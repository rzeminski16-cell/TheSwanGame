# Phase 7 — LAN Multiplayer

## Overview
Host-authoritative LAN co-op for 1-4 players using Godot's ENet multiplayer.
All game state is owned by the host; clients send input and receive replicated state.

## Architecture

### Host-Authoritative Model
- Host creates ENet server on port 9999 (configurable)
- Clients connect via IP address
- Host owns all non-player entities (enemies, loot)
- Each player owns their own character input
- All damage calculations, XP distribution, and loot drops run on host

### Peer-to-Player Mapping
- Each connecting peer gets assigned a player_id (1-4)
- Host is always peer_id 1 / player_id 1
- Mapping stored in GameState: `peer_player_map`, `player_peer_map`
- Player count locked at world creation (set via MainMenu SpinBox)

## Files Modified

### Core Multiplayer
| File | Changes |
|------|---------|
| `scripts/managers/game_state.gd` | Added `is_multiplayer`, `active_peer_ids`, `peer_player_map`, `player_peer_map`, `player_names`, `host_peer_id`, `get_player_id_for_peer()`, `get_peer_id_for_player()`, `reset_multiplayer()` |
| `scripts/managers/multiplayer_manager.gd` | Full ENet implementation: `host_game()`, `join_game()`, `disconnect_game()`, peer connection handlers, player assignment, scene sync RPCs, RPC validation |
| `scripts/components/network_sync_component.gd` | Position sync (20Hz unreliable), health sync (reliable on change), velocity sync, remote player interpolation |
| `scripts/entities/player.gd` | `_is_local` flag, `setup_multiplayer()`, only local player processes input, remote players interpolated |

### Manager Updates
| File | Changes |
|------|---------|
| `scripts/managers/combat_manager.gd` | XP awarded to all active players (not just player 1) |
| `scripts/managers/save_manager.gd` | Version 2 format with `multiplayer`, `player_count`, `player_names` fields; `new_game()` resets all players; `apply_death_penalty(player_id)` accepts player_id parameter |
| `scripts/scene_manager.gd` | Added `change_scene_synced()` for host-triggered synchronized scene changes |

### UI Updates
| File | Changes |
|------|---------|
| `scripts/ui/main_menu.gd` | Added Host Game button, Join Game (IP + button), player count SpinBox, status label |
| `scripts/ui_manager.gd` | Wired `host_game_pressed` / `join_game_pressed` signals, `_on_host_game()`, `_on_join_game()`, `_start_multiplayer_game()`, disconnect on return to main menu |
| `scripts/ui/debug_menu.gd` | Added Multiplayer category: Host Game, Join Localhost, Disconnect, Print Peer Info |

### Scene Updates
| File | Changes |
|------|---------|
| `scripts/overworld_scene.gd` | Spawns all active players with offset positions, camera on local player only |
| `scripts/dungeon_scene.gd` | Spawns all active players, connects death signal for all players |

## Multiplayer Rules (from Game Design Document)
- Shared house (all players live together)
- Individual money (each player has separate funds)
- Chest loot is first-come-first-serve
- Corpse loot is NOT stealable (per-player)
- Shared dungeon instance (all players enter together)
- One save file per world
- Player count locked on world creation

## Save Format v2
```json
{
  "version": 2,
  "multiplayer": true,
  "player_count": 2,
  "scene_path": "res://scenes/OverworldScene.tscn",
  "player_names": { "1": "Host", "2": "Player 2" },
  "players": {
    "1": { "level": 3, "xp": 450, ... },
    "2": { "level": 2, "xp": 200, ... }
  },
  "economy": { "1": 320, "2": 150 },
  "inventory": { "1": ["damage_ring"], "2": ["light_boots"] },
  "dungeons": { "crab_cave": 1 },
  "missions": { "current_mission_id": "" },
  "time": { "current_day": 3, "elapsed": 42.5 }
}
```

## RPC Overview
| Function | Authority | Reliability | Purpose |
|----------|-----------|-------------|---------|
| `_sync_player_assignments` | Host | Reliable | Broadcast peer-to-player mapping |
| `_receive_player_assignments` | Host | Reliable | Clients receive mapping |
| `request_change_scene` | Host | Reliable | Host triggers scene change |
| `_remote_change_scene` | Host | Reliable | Clients load new scene |
| `_report_scene_ready` | Any peer | Reliable | Client reports scene loaded |
| `_send_position` | Any peer | Unreliable | Position sync (20Hz) |
| `_receive_health` | Any peer | Reliable | Health state sync |
| `_receive_velocity` | Any peer | Unreliable | Movement direction sync |

## Testing
- **Python tests**: `tests/test_phase7_json.py` — 91 checks
- **GDScript runtime tests**: `tests/test_phase7_runtime.gd` — GameState fields, peer mapping, save format, death penalty per-player

### Human Testing Checklist
- [ ] Single player: New Game still works as before
- [ ] Single player: Continue from save still works
- [ ] Host Game: creates server, loads overworld with player
- [ ] Join Game: connects to host, second player appears
- [ ] Both players can move independently
- [ ] Enemies award XP to all players
- [ ] Save/Load preserves all player data
- [ ] Disconnect returns to main menu cleanly
- [ ] Debug Menu: Host/Join/Disconnect/Info buttons work
