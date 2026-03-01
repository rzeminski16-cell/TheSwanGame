extends Node
## MultiplayerManager — Host authoritative networking.
## Full implementation in Phase 7.

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)


func host_game(_port: int = 9999) -> bool:
	# Phase 7: Create ENet host
	push_warning("MultiplayerManager.host_game() not yet implemented")
	return false


func join_game(_address: String, _port: int = 9999) -> bool:
	# Phase 7: Connect to ENet host
	push_warning("MultiplayerManager.join_game() not yet implemented")
	return false


func is_host() -> bool:
	return GameState.is_host


func get_peer_ids() -> Array:
	return [1]  # Single player only for now
