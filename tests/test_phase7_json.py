#!/usr/bin/env python3
"""Phase 7 — LAN Multiplayer: static validation tests.

Checks that all required scripts, signals, functions, RPCs, and scene
references exist in the codebase without running Godot.
"""

import os, sys, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
passed = 0
failed = 0


def check(label, condition):
    global passed, failed
    if condition:
        print(f"  PASS  {label}")
        passed += 1
    else:
        print(f"  FAIL  {label}")
        failed += 1


def read(rel_path):
    full = os.path.join(ROOT, rel_path)
    if not os.path.exists(full):
        return ""
    with open(full, "r") as f:
        return f.read()


# ---------- GameState Multiplayer Fields ----------
print("\n--- GameState Multiplayer Fields ---")
gs = read("scripts/managers/game_state.gd")
check("GameState has is_multiplayer", "var is_multiplayer" in gs)
check("GameState has active_peer_ids", "var active_peer_ids" in gs)
check("GameState has peer_player_map", "var peer_player_map" in gs)
check("GameState has player_peer_map", "var player_peer_map" in gs)
check("GameState has player_names", "var player_names" in gs)
check("GameState has host_peer_id", "var host_peer_id" in gs)
check("GameState has get_player_id_for_peer()", "func get_player_id_for_peer" in gs)
check("GameState has get_peer_id_for_player()", "func get_peer_id_for_player" in gs)
check("GameState has reset_multiplayer()", "func reset_multiplayer" in gs)


# ---------- MultiplayerManager ----------
print("\n--- MultiplayerManager ---")
mm = read("scripts/managers/multiplayer_manager.gd")
check("MM has player_connected signal", "signal player_connected" in mm)
check("MM has player_disconnected signal", "signal player_disconnected" in mm)
check("MM has connection_succeeded signal", "signal connection_succeeded" in mm)
check("MM has connection_failed signal", "signal connection_failed" in mm)
check("MM has server_disconnected signal", "signal server_disconnected" in mm)
check("MM has all_players_ready signal", "signal all_players_ready" in mm)
check("MM has host_game()", "func host_game" in mm)
check("MM has join_game()", "func join_game" in mm)
check("MM has disconnect_game()", "func disconnect_game" in mm)
check("MM has is_host()", "func is_host" in mm)
check("MM has is_multiplayer_active()", "func is_multiplayer_active" in mm)
check("MM has get_peer_ids()", "func get_peer_ids" in mm)
check("MM has get_local_player_id()", "func get_local_player_id" in mm)
check("MM has get_all_player_ids()", "func get_all_player_ids" in mm)
check("MM uses ENetMultiplayerPeer", "ENetMultiplayerPeer" in mm)
check("MM has create_server", "create_server" in mm)
check("MM has create_client", "create_client" in mm)
check("MM has _assign_player()", "func _assign_player" in mm)
check("MM has _unassign_player()", "func _unassign_player" in mm)
check("MM has request_change_scene()", "func request_change_scene" in mm)
check("MM has validate_sender_is_host()", "func validate_sender_is_host" in mm)
check("MM has validate_sender_owns_player()", "func validate_sender_owns_player" in mm)

# Check @rpc annotations
check("MM has @rpc annotations", "@rpc(" in mm)
rpc_count = mm.count("@rpc(")
check("MM has at least 4 @rpc annotations", rpc_count >= 4)


# ---------- NetworkSyncComponent ----------
print("\n--- NetworkSyncComponent ---")
nsc = read("scripts/components/network_sync_component.gd")
check("NSC file exists", nsc != "")
check("NSC has class_name", "class_name NetworkSyncComponent" in nsc)
check("NSC has setup()", "func setup" in nsc)
check("NSC has sync_health()", "func sync_health" in nsc)
check("NSC has sync_velocity()", "func sync_velocity" in nsc)
check("NSC has _send_position @rpc", "_send_position" in nsc and "@rpc(" in nsc)
check("NSC has _receive_health @rpc", "_receive_health" in nsc)
check("NSC has _receive_velocity @rpc", "_receive_velocity" in nsc)
check("NSC uses SYNC_INTERVAL", "SYNC_INTERVAL" in nsc)
check("NSC uses interpolation", "_interpolation_speed" in nsc or "lerp" in nsc)


# ---------- Player Multiplayer ----------
print("\n--- Player Multiplayer ---")
player = read("scripts/entities/player.gd")
check("Player has _is_local", "var _is_local" in player)
check("Player has setup_multiplayer()", "func setup_multiplayer" in player)
check("Player has network_sync reference", "network_sync" in player)
check("Player checks _is_local in _physics_process", "if not _is_local" in player)
check("Player has health sync callback", "_on_health_changed_for_sync" in player)


# ---------- Player.tscn has NetworkSyncComponent ----------
print("\n--- Player.tscn Scene ---")
ptscn = read("scenes/entities/Player.tscn")
check("Player.tscn has NetworkSyncComponent", "NetworkSyncComponent" in ptscn)
check("Player.tscn has network_sync_component.gd", "network_sync_component.gd" in ptscn)


# ---------- CombatManager Multi-player XP ----------
print("\n--- CombatManager Multi-player XP ---")
cm = read("scripts/managers/combat_manager.gd")
check("CombatManager uses get_all_player_ids()", "get_all_player_ids" in cm)
check("CombatManager awards XP to all players", "for pid in player_ids" in cm)
check("CombatManager no longer hardcodes player 1 XP", "add_xp(1, xp_reward)" not in cm)


# ---------- SaveManager Version 2 ----------
print("\n--- SaveManager Version 2 ---")
sm = read("scripts/managers/save_manager.gd")
check("SaveManager version is 2", "SAVE_VERSION := 2" in sm)
check("SaveManager saves multiplayer flag", '"multiplayer"' in sm)
check("SaveManager saves player_count", '"player_count"' in sm)
check("SaveManager saves player_names", '"player_names"' in sm)
check("SaveManager restores player_count", "saved_player_count" in sm or 'player_count' in sm)
check("SaveManager new_game resets all players", "range(1, GameState.player_count + 1)" in sm)
check("SaveManager apply_death_penalty accepts player_id", "func apply_death_penalty(player_id" in sm)


# ---------- SceneManager Sync ----------
print("\n--- SceneManager Sync ---")
scm = read("scripts/scene_manager.gd")
check("SceneManager has change_scene_synced()", "func change_scene_synced" in scm)
check("SceneManager calls request_change_scene", "request_change_scene" in scm)


# ---------- MainMenu Multiplayer Buttons ----------
print("\n--- MainMenu Multiplayer ---")
menu = read("scripts/ui/main_menu.gd")
check("MainMenu has host_game_pressed signal", "signal host_game_pressed" in menu)
check("MainMenu has join_game_pressed signal", "signal join_game_pressed" in menu)
check("MainMenu has Host Game button", '"Host Game"' in menu)
check("MainMenu has Join button", '"Join"' in menu)
check("MainMenu has IP input", "LineEdit" in menu)
check("MainMenu has player count spin", "SpinBox" in menu)
check("MainMenu has set_status()", "func set_status" in menu)
check("MainMenu has _player_count_spin", "_player_count_spin" in menu)
check("MainMenu has LAN Multiplayer label", '"LAN Multiplayer"' in menu)


# ---------- UIManager Multiplayer Wiring ----------
print("\n--- UIManager Multiplayer Wiring ---")
um = read("scripts/ui_manager.gd")
check("UIManager connects host_game_pressed", "host_game_pressed" in um)
check("UIManager connects join_game_pressed", "join_game_pressed" in um)
check("UIManager has _on_host_game()", "func _on_host_game" in um)
check("UIManager has _on_join_game()", "func _on_join_game" in um)
check("UIManager has _start_multiplayer_game()", "func _start_multiplayer_game" in um)
check("UIManager disconnects multiplayer on main menu", "disconnect_game" in um)


# ---------- OverworldScene Multi-player Spawning ----------
print("\n--- OverworldScene Multi-player Spawning ---")
ow = read("scripts/overworld_scene.gd")
check("Overworld uses get_all_player_ids()", "get_all_player_ids" in ow)
check("Overworld calls setup_multiplayer()", "setup_multiplayer" in ow)
check("Overworld spawns multiple players", "for i in range" in ow)


# ---------- DungeonScene Multi-player Spawning ----------
print("\n--- DungeonScene Multi-player Spawning ---")
ds = read("scripts/dungeon_scene.gd")
check("Dungeon uses get_all_player_ids()", "get_all_player_ids" in ds)
check("Dungeon calls setup_multiplayer()", "setup_multiplayer" in ds)
check("Dungeon spawns multiple players", "for i in range" in ds)
check("Dungeon connects death for all players", "for pid in player_ids" in ds)


# ---------- Debug Menu Multiplayer ----------
print("\n--- Debug Menu Multiplayer ---")
dm = read("scripts/ui/debug_menu.gd")
check("DebugMenu has Multiplayer category", '"Multiplayer"' in dm)
check("DebugMenu has Host Game button", '"Host Game' in dm)
check("DebugMenu has Join Localhost button", '"Join Localhost"' in dm)
check("DebugMenu has Disconnect button", '"Disconnect"' in dm)
check("DebugMenu has Print Peer Info button", '"Print Peer Info"' in dm)
check("DebugMenu has _on_mp_host()", "func _on_mp_host" in dm)
check("DebugMenu has _on_mp_info()", "func _on_mp_info" in dm)


# ---------- Results ----------
print(f"\n{'='*60}")
print(f"  RESULTS: {passed} passed, {failed} failed")
print(f"{'='*60}")
sys.exit(1 if failed > 0 else 0)
