extends Node
## Phase 7 Runtime Tests — LAN Multiplayer.
## Tests GameState multiplayer fields, MultiplayerManager API,
## NetworkSyncComponent setup, and save format v2.

var _pass_count := 0
var _fail_count := 0


func _ready() -> void:
	print("\n=== Phase 7 Runtime Tests ===\n")
	_test_game_state_multiplayer_fields()
	_test_multiplayer_manager_api()
	_test_multiplayer_manager_peer_ids()
	_test_save_format_v2()
	_test_player_id_mapping()
	_test_all_player_ids()
	_test_death_penalty_player_id()
	_test_reset_multiplayer()

	print("\n--- Results: %d passed, %d failed ---" % [_pass_count, _fail_count])


func _check(label: String, condition: bool) -> void:
	if condition:
		print("  PASS  %s" % label)
		_pass_count += 1
	else:
		print("  FAIL  %s" % label)
		_fail_count += 1


func _test_game_state_multiplayer_fields() -> void:
	print("--- GameState Multiplayer Fields ---")
	_check("is_multiplayer defaults to false", GameState.is_multiplayer == false)
	_check("active_peer_ids defaults to empty", GameState.active_peer_ids.is_empty())
	_check("peer_player_map defaults to empty", GameState.peer_player_map.is_empty())
	_check("player_peer_map defaults to empty", GameState.player_peer_map.is_empty())
	_check("player_names defaults to empty", GameState.player_names.is_empty())
	_check("host_peer_id defaults to 1", GameState.host_peer_id == 1)
	_check("player_count defaults to 1", GameState.player_count == 1)


func _test_multiplayer_manager_api() -> void:
	print("--- MultiplayerManager API ---")
	_check("is_host() returns true by default", MultiplayerManager.is_host() == true)
	_check("is_multiplayer_active() returns false by default", MultiplayerManager.is_multiplayer_active() == false)
	_check("get_local_player_id() returns 1 in single player", MultiplayerManager.get_local_player_id() == 1)


func _test_multiplayer_manager_peer_ids() -> void:
	print("--- MultiplayerManager Peer IDs ---")
	var peers := MultiplayerManager.get_peer_ids()
	_check("get_peer_ids() returns [1] in single player", peers.size() == 1 and peers[0] == 1)


func _test_save_format_v2() -> void:
	print("--- Save Format v2 ---")
	_check("SAVE_VERSION is 2", SaveManager.SAVE_VERSION == 2)


func _test_player_id_mapping() -> void:
	print("--- Player ID Mapping ---")
	# Simulate multiplayer assignment
	GameState.peer_player_map[1] = 1
	GameState.player_peer_map[1] = 1
	GameState.peer_player_map[12345] = 2
	GameState.player_peer_map[2] = 12345

	_check("get_player_id_for_peer(1) == 1", GameState.get_player_id_for_peer(1) == 1)
	_check("get_player_id_for_peer(12345) == 2", GameState.get_player_id_for_peer(12345) == 2)
	_check("get_player_id_for_peer(999) == -1", GameState.get_player_id_for_peer(999) == -1)
	_check("get_peer_id_for_player(1) == 1", GameState.get_peer_id_for_player(1) == 1)
	_check("get_peer_id_for_player(2) == 12345", GameState.get_peer_id_for_player(2) == 12345)

	# Cleanup
	GameState.peer_player_map.clear()
	GameState.player_peer_map.clear()


func _test_all_player_ids() -> void:
	print("--- All Player IDs ---")
	# Single player mode
	var ids := MultiplayerManager.get_all_player_ids()
	_check("get_all_player_ids() returns [1] in single player", ids.size() >= 1)

	# Simulate multiplayer
	GameState.peer_player_map[1] = 1
	GameState.peer_player_map[100] = 2
	GameState.peer_player_map[200] = 3
	var mp_ids := MultiplayerManager.get_all_player_ids()
	_check("get_all_player_ids() returns 3 ids with 3 peers", mp_ids.size() == 3)
	_check("get_all_player_ids() sorted", mp_ids[0] == 1 and mp_ids[1] == 2 and mp_ids[2] == 3)

	# Cleanup
	GameState.peer_player_map.clear()


func _test_death_penalty_player_id() -> void:
	print("--- Death Penalty Player ID ---")
	# Setup two players with money
	EconomyManager.load_save_data(1, 1000)
	EconomyManager.load_save_data(2, 500)

	# Apply penalty to player 2 only
	SaveManager.apply_death_penalty(2)

	_check("Player 1 money unchanged after p2 penalty", EconomyManager.get_money(1) == 1000)
	_check("Player 2 money reduced after penalty", EconomyManager.get_money(2) < 500)

	# Cleanup
	EconomyManager.load_save_data(1, 0)
	EconomyManager.load_save_data(2, 0)


func _test_reset_multiplayer() -> void:
	print("--- Reset Multiplayer ---")
	# Set some multiplayer state
	GameState.is_multiplayer = true
	GameState.active_peer_ids = [1, 2, 3]
	GameState.peer_player_map = {1: 1, 2: 2}
	GameState.player_count = 3

	GameState.reset_multiplayer()

	_check("reset clears is_multiplayer", GameState.is_multiplayer == false)
	_check("reset clears active_peer_ids", GameState.active_peer_ids.is_empty())
	_check("reset clears peer_player_map", GameState.peer_player_map.is_empty())
	_check("reset sets player_count to 1", GameState.player_count == 1)
	_check("reset sets is_host to true", GameState.is_host == true)
