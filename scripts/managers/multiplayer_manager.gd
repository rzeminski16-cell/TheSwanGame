extends Node
## MultiplayerManager — Host-authoritative LAN multiplayer via ENet.
## Manages peer connections, player assignment, scene sync, and RPC validation.
## Architecture: host owns all game state; clients send input, receive state.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded()
signal connection_failed()
signal server_disconnected()
signal all_players_ready()

const DEFAULT_PORT := 9999
const MAX_PLAYERS := 4

var _peer: ENetMultiplayerPeer = null
var _next_player_id: int = 1
var _players_ready: Dictionary = {}  # peer_id → bool (scene ready tracking)


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# --- Host / Join ---

func host_game(port: int = DEFAULT_PORT) -> bool:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("MultiplayerManager: Failed to create server on port %d (error %d)" % [port, err])
		_peer = null
		return false

	multiplayer.multiplayer_peer = _peer

	# Host is always peer_id 1
	GameState.is_host = true
	GameState.is_multiplayer = true
	GameState.host_peer_id = 1

	# Assign host as player 1
	_next_player_id = 1
	_assign_player(1, "Host")
	_next_player_id = 2

	print("MultiplayerManager: Hosting on port %d" % port)
	return true


func join_game(address: String, port: int = DEFAULT_PORT) -> bool:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)
	if err != OK:
		push_error("MultiplayerManager: Failed to connect to %s:%d (error %d)" % [address, port, err])
		_peer = null
		return false

	multiplayer.multiplayer_peer = _peer
	GameState.is_host = false
	GameState.is_multiplayer = true

	print("MultiplayerManager: Connecting to %s:%d..." % [address, port])
	return true


func disconnect_game() -> void:
	if _peer != null:
		multiplayer.multiplayer_peer = null
		_peer = null

	_next_player_id = 1
	_players_ready.clear()
	GameState.reset_multiplayer()
	print("MultiplayerManager: Disconnected")


func is_host() -> bool:
	return GameState.is_host


func is_multiplayer_active() -> bool:
	return GameState.is_multiplayer


func get_peer_ids() -> Array:
	if not GameState.is_multiplayer:
		return [1]
	return GameState.active_peer_ids.duplicate()


func get_local_player_id() -> int:
	if not GameState.is_multiplayer:
		return 1
	var my_peer := multiplayer.get_unique_id()
	return GameState.get_player_id_for_peer(my_peer)


func get_all_player_ids() -> Array:
	var ids: Array = []
	for pid in GameState.peer_player_map.values():
		ids.append(pid)
	ids.sort()
	return ids


# --- Peer Connection Handlers ---

func _on_peer_connected(peer_id: int) -> void:
	print("MultiplayerManager: Peer %d connected" % peer_id)

	if not is_host():
		return

	# Host assigns player ID to new peer
	if _next_player_id > MAX_PLAYERS:
		push_warning("MultiplayerManager: Max players reached, rejecting peer %d" % peer_id)
		# Can't easily kick in Godot ENet, but we don't assign them
		return

	var assigned_id := _next_player_id
	_next_player_id += 1
	var player_name := "Player %d" % assigned_id
	_assign_player(peer_id, player_name)

	# Tell ALL clients (including new one) the full player map
	_sync_player_assignments.rpc()

	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("MultiplayerManager: Peer %d disconnected" % peer_id)

	if is_host():
		var player_id := GameState.get_player_id_for_peer(peer_id)
		_unassign_player(peer_id)

		# Notify remaining clients
		_sync_player_assignments.rpc()

		player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	print("MultiplayerManager: Connected to server!")
	GameState.is_multiplayer = true
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	push_warning("MultiplayerManager: Connection failed")
	_peer = null
	GameState.reset_multiplayer()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	push_warning("MultiplayerManager: Server disconnected")
	disconnect_game()
	server_disconnected.emit()


# --- Player Assignment ---

func _assign_player(peer_id: int, player_name: String) -> void:
	var player_id := _next_player_id if peer_id != 1 else 1
	if peer_id == 1:
		player_id = 1

	# Find next available player_id for non-host
	if peer_id != 1:
		player_id = _next_player_id - 1  # Already incremented in _on_peer_connected

	GameState.peer_player_map[peer_id] = player_id
	GameState.player_peer_map[player_id] = peer_id
	GameState.player_names[player_id] = player_name
	if peer_id not in GameState.active_peer_ids:
		GameState.active_peer_ids.append(peer_id)

	GameState.player_count = GameState.peer_player_map.size()
	print("MultiplayerManager: Assigned peer %d → player %d ('%s')" % [peer_id, player_id, player_name])


func _unassign_player(peer_id: int) -> void:
	var player_id := GameState.get_player_id_for_peer(peer_id)
	GameState.peer_player_map.erase(peer_id)
	if player_id > 0:
		GameState.player_peer_map.erase(player_id)
		GameState.player_names.erase(player_id)
	GameState.active_peer_ids.erase(peer_id)
	GameState.player_count = GameState.peer_player_map.size()
	_players_ready.erase(peer_id)
	print("MultiplayerManager: Unassigned peer %d (was player %d)" % [peer_id, player_id])


# --- RPC: Sync Player Assignments ---

@rpc("authority", "call_local", "reliable")
func _sync_player_assignments() -> void:
	# Host sends the full assignment to everyone
	if is_host():
		var data := {
			"peer_player_map": GameState.peer_player_map.duplicate(),
			"player_names": GameState.player_names.duplicate(),
			"active_peer_ids": GameState.active_peer_ids.duplicate(),
			"player_count": GameState.player_count,
		}
		_receive_player_assignments.rpc(data)


@rpc("authority", "call_local", "reliable")
func _receive_player_assignments(data: Dictionary) -> void:
	GameState.peer_player_map = data.get("peer_player_map", {})
	GameState.player_names = data.get("player_names", {})
	GameState.active_peer_ids = data.get("active_peer_ids", [])
	GameState.player_count = data.get("player_count", 1)

	# Rebuild reverse map
	GameState.player_peer_map.clear()
	for peer_id in GameState.peer_player_map:
		var pid = GameState.peer_player_map[peer_id]
		GameState.player_peer_map[pid] = peer_id

	print("MultiplayerManager: Received assignments — %d players" % GameState.player_count)


# --- RPC: Scene Sync ---

@rpc("authority", "call_local", "reliable")
func request_change_scene(scene_path: String) -> void:
	## Host calls this to tell all clients to change scene.
	if not is_host():
		return
	_players_ready.clear()
	_remote_change_scene.rpc(scene_path)


@rpc("authority", "call_local", "reliable")
func _remote_change_scene(scene_path: String) -> void:
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene(scene_path)
	# Report ready after scene loads
	if GameState.is_multiplayer:
		_report_scene_ready.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func _report_scene_ready() -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = 1  # Local call from host
	_players_ready[sender] = true
	print("MultiplayerManager: Peer %d scene ready (%d/%d)" % [
		sender, _players_ready.size(), GameState.player_count])
	if _players_ready.size() >= GameState.player_count:
		all_players_ready.emit()


# --- RPC Validation ---

func validate_sender_is_host(sender_id: int) -> bool:
	return sender_id == 1 or sender_id == 0


func validate_sender_owns_player(sender_id: int, player_id: int) -> bool:
	var expected_peer := GameState.get_peer_id_for_player(player_id)
	return sender_id == expected_peer or sender_id == 0
