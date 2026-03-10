extends Node
## MissionManager — Mission state tracking, objective completion, rewards.
## Supports multiple active quests simultaneously with one tracked quest for HUD.
## Mission data loaded from DataManager (missions.json).

enum MissionState { NOT_STARTED, ACTIVE, COMPLETED, FAILED }

signal mission_started(mission_id: String)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)
signal objective_completed(mission_id: String, objective_index: int)
signal tracked_mission_changed(mission_id: String)
signal mission_unlocked(mission_id: String)

var _mission_states: Dictionary = {}  # mission_id → MissionState
var _objective_status: Dictionary = {}  # mission_id → Array[bool]
var _kill_counts: Dictionary = {}  # enemy_id → int (global kill tracker)


func _ready() -> void:
	print("MissionManager: Ready (%d missions loaded)" % DataManager.get_all_missions().size())


# --- Mission Lifecycle ---

func start_mission(mission_id: String) -> bool:
	var data: Dictionary = DataManager.get_mission(mission_id)
	if data.is_empty():
		push_warning("MissionManager: Unknown mission_id '%s'" % mission_id)
		return false

	if get_mission_state(mission_id) == MissionState.COMPLETED:
		print("MissionManager: Mission '%s' already completed" % mission_id)
		return false

	if get_mission_state(mission_id) == MissionState.ACTIVE:
		print("MissionManager: Mission '%s' already active" % mission_id)
		return false

	# Check character restriction
	var restriction = data.get("character_restriction")
	if restriction != null and restriction != "" and restriction != GameState.active_character_id:
		print("MissionManager: Mission '%s' restricted to character '%s'" % [mission_id, restriction])
		return false

	_mission_states[mission_id] = MissionState.ACTIVE

	# Add to active list
	if mission_id not in GameState.active_mission_ids:
		GameState.active_mission_ids.append(mission_id)

	# Legacy compat
	GameState.current_mission_id = mission_id

	# Auto-track if nothing is tracked
	if GameState.tracked_mission_id == "":
		track_mission(mission_id)

	# Initialize objective tracking
	var objectives: Array = data.get("objectives", [])
	var status: Array = []
	for i in range(objectives.size()):
		status.append(false)
	_objective_status[mission_id] = status

	mission_started.emit(mission_id)
	print("MissionManager: Started mission '%s' — %s (%d objectives)" % [
		mission_id, data.get("display_name", ""), objectives.size()])
	return true


func complete_objective(mission_id: String, objective_index: int) -> void:
	if get_mission_state(mission_id) != MissionState.ACTIVE:
		return

	var status: Array = _objective_status.get(mission_id, [])
	if objective_index < 0 or objective_index >= status.size():
		push_warning("MissionManager: Invalid objective index %d for '%s'" % [objective_index, mission_id])
		return

	if status[objective_index]:
		return  # Already completed

	status[objective_index] = true
	_objective_status[mission_id] = status
	objective_completed.emit(mission_id, objective_index)

	var data: Dictionary = DataManager.get_mission(mission_id)
	var objectives: Array = data.get("objectives", [])
	var obj_desc := _describe_objective(objectives[objective_index]) if objective_index < objectives.size() else ""
	print("MissionManager: Objective %d/%d completed — %s" % [
		objective_index + 1, status.size(), obj_desc])

	# Check if all objectives complete
	if _all_objectives_complete(mission_id):
		_complete_mission(mission_id)


func _all_objectives_complete(mission_id: String) -> bool:
	var status: Array = _objective_status.get(mission_id, [])
	for done in status:
		if not done:
			return false
	return status.size() > 0


func _complete_mission(mission_id: String) -> void:
	_mission_states[mission_id] = MissionState.COMPLETED

	# Remove from active list
	GameState.active_mission_ids.erase(mission_id)

	var data: Dictionary = DataManager.get_mission(mission_id)

	# Grant rewards
	var rewards: Dictionary = data.get("rewards", {})
	var money: int = int(rewards.get("money", 0))
	var xp: int = int(rewards.get("xp", 0))
	if money > 0:
		EconomyManager.add_money(1, money)
	if xp > 0:
		PlayerManager.add_xp(1, xp)
	var items: Array = rewards.get("items", [])
	for item_id in items:
		InventoryManager.add_item(1, item_id)

	mission_completed.emit(mission_id)
	print("MissionManager: Mission '%s' completed! Rewards: %d money, %d XP" % [
		data.get("display_name", mission_id), money, xp])

	# If this was the tracked mission, auto-track next available
	if GameState.tracked_mission_id == mission_id:
		_auto_track_next(mission_id)

	# Update legacy compat
	if GameState.current_mission_id == mission_id:
		GameState.current_mission_id = GameState.tracked_mission_id

	# Auto-start next mission if defined
	var next_id = data.get("next_mission_id")
	if next_id != null and next_id != "":
		start_mission(next_id)

	# Check if any quests are now unlockable
	_check_unlocks()


func fail_mission(mission_id: String) -> void:
	if get_mission_state(mission_id) != MissionState.ACTIVE:
		return

	_mission_states[mission_id] = MissionState.FAILED
	GameState.active_mission_ids.erase(mission_id)

	if GameState.tracked_mission_id == mission_id:
		_auto_track_next("")

	if GameState.current_mission_id == mission_id:
		GameState.current_mission_id = GameState.tracked_mission_id

	mission_failed.emit(mission_id)
	print("MissionManager: Mission '%s' failed" % mission_id)


func debug_complete_mission(mission_id: String) -> void:
	## Debug: force-complete all objectives and the mission itself.
	if get_mission_state(mission_id) != MissionState.ACTIVE:
		if get_mission_state(mission_id) == MissionState.NOT_STARTED:
			start_mission(mission_id)
		else:
			return

	var status: Array = _objective_status.get(mission_id, [])
	for i in range(status.size()):
		if not status[i]:
			status[i] = true
			objective_completed.emit(mission_id, i)
	_objective_status[mission_id] = status
	_complete_mission(mission_id)
	print("MissionManager: DEBUG — Force-completed mission '%s'" % mission_id)


# --- Tracking ---

func track_mission(mission_id: String) -> void:
	if mission_id != "" and get_mission_state(mission_id) != MissionState.ACTIVE:
		return
	GameState.tracked_mission_id = mission_id
	GameState.current_mission_id = mission_id  # Legacy compat
	tracked_mission_changed.emit(mission_id)
	print("MissionManager: Now tracking '%s'" % mission_id)


func get_tracked_mission_id() -> String:
	return GameState.tracked_mission_id


func get_tracked_mission_data() -> Dictionary:
	var tid := get_tracked_mission_id()
	if tid == "":
		return {}
	return DataManager.get_mission(tid)


func _auto_track_next(completed_id: String) -> void:
	# Track the first remaining active mission
	for mid in GameState.active_mission_ids:
		if mid != completed_id:
			track_mission(mid)
			return
	track_mission("")


# --- Unlock System ---

func _check_unlocks() -> void:
	## Check all missions to see if any new ones are now unlockable.
	for mission_data in DataManager.get_all_missions():
		var mid: String = mission_data.get("id", "")
		if get_mission_state(mid) != MissionState.NOT_STARTED:
			continue
		if _can_unlock(mission_data):
			mission_unlocked.emit(mid)


func _can_unlock(mission_data: Dictionary) -> bool:
	var requirements: Array = mission_data.get("unlock_requirements", [])
	if requirements.is_empty():
		return true
	for req_id in requirements:
		if not is_mission_completed(req_id):
			return false
	# Check character restriction
	var restriction = mission_data.get("character_restriction")
	if restriction != null and restriction != "" and restriction != GameState.active_character_id:
		return false
	return true


func is_mission_unlockable(mission_id: String) -> bool:
	var data: Dictionary = DataManager.get_mission(mission_id)
	if data.is_empty():
		return false
	return _can_unlock(data)


func get_unlockable_missions() -> Array:
	## Returns missions that are NOT_STARTED but whose requirements are met.
	var result: Array = []
	for mission_data in DataManager.get_all_missions():
		var mid: String = mission_data.get("id", "")
		if get_mission_state(mid) != MissionState.NOT_STARTED:
			continue
		if _can_unlock(mission_data):
			result.append(mission_data)
	return result


# --- Objective Triggers ---

func notify_talk_to_npc(npc_id: String) -> void:
	_check_objective_all_active("talk_to_npc", {"npc_id": npc_id})


func notify_reach_location(location_id: String) -> void:
	_check_objective_all_active("reach_location", {"location_id": location_id})


func notify_enter_dungeon(dungeon_id: String) -> void:
	_check_objective_all_active("enter_dungeon", {"dungeon_id": dungeon_id})


func notify_deliver_item(delivery_job_id: String) -> void:
	_check_objective_all_active("deliver_item", {"delivery_job_id": delivery_job_id})


func notify_collect_item(item_id: String) -> void:
	_check_objective_all_active("collect_item", {"item_id": item_id})


func notify_return_home() -> void:
	_check_objective_all_active("return_home", {})


func notify_enemy_killed(enemy_id: String) -> void:
	_kill_counts[enemy_id] = _kill_counts.get(enemy_id, 0) + 1
	_check_objective_all_active("kill_enemies", {"enemy_id": enemy_id})


func notify_survive_complete(arena_id: String) -> void:
	_check_objective_all_active("survive_waves", {"arena_id": arena_id})


func notify_investigate(clue_id: String) -> void:
	_check_objective_all_active("investigate", {"clue_id": clue_id})


func notify_puzzle_solved(puzzle_id: String) -> void:
	_check_objective_all_active("solve_puzzle", {"puzzle_id": puzzle_id})


func notify_riddle_solved(riddle_id: String) -> void:
	_check_objective_all_active("solve_riddle", {"riddle_id": riddle_id})


func notify_defend_complete(location_id: String) -> void:
	_check_objective_all_active("defend_location", {"location_id": location_id})


func notify_timed_complete(sub_type: String, delivery_job_id: String) -> void:
	_check_objective_all_active("timed_objective", {"sub_type": sub_type, "delivery_job_id": delivery_job_id})


func notify_stealth_complete(area_id: String) -> void:
	_check_objective_all_active("stealth", {"area_id": area_id})


func notify_dialogue_choice(choice_id: String) -> void:
	_check_objective_all_active("dialogue_choice", {"choice_id": choice_id})


func notify_make_choice(choice_id: String) -> void:
	_check_objective_all_active("make_choice", {"choice_id": choice_id})


func _check_objective_all_active(obj_type: String, params: Dictionary) -> void:
	## Check all active missions (not just the tracked one) for matching objectives.
	var active_ids := GameState.active_mission_ids.duplicate()
	for mid in active_ids:
		_check_objective(mid, obj_type, params)


func _check_objective(mission_id: String, obj_type: String, params: Dictionary) -> void:
	if get_mission_state(mission_id) != MissionState.ACTIVE:
		return

	var data: Dictionary = DataManager.get_mission(mission_id)
	var objectives: Array = data.get("objectives", [])
	var status: Array = _objective_status.get(mission_id, [])

	for i in range(objectives.size()):
		if i >= status.size() or status[i]:
			continue

		var obj: Dictionary = objectives[i]
		if obj.get("type", "") != obj_type:
			continue

		var matches := true
		match obj_type:
			"talk_to_npc":
				matches = obj.get("npc_id", "") == params.get("npc_id", "")
			"reach_location":
				matches = obj.get("location_id", "") == params.get("location_id", "")
			"enter_dungeon":
				matches = obj.get("dungeon_id", "") == params.get("dungeon_id", "")
			"deliver_item":
				matches = obj.get("delivery_job_id", "") == params.get("delivery_job_id", "")
			"collect_item":
				matches = obj.get("item_id", "") == params.get("item_id", "")
			"return_home":
				matches = true
			"kill_enemies":
				var eid: String = obj.get("enemy_id", "")
				var needed: int = int(obj.get("count", 1))
				matches = params.get("enemy_id", "") == eid and get_kill_count(eid) >= needed
			"survive_waves":
				matches = obj.get("arena_id", "") == params.get("arena_id", "")
			"investigate":
				matches = obj.get("clue_id", "") == params.get("clue_id", "")
			"solve_puzzle":
				matches = obj.get("puzzle_id", "") == params.get("puzzle_id", "")
			"solve_riddle":
				matches = obj.get("riddle_id", "") == params.get("riddle_id", "")
			"defend_location":
				matches = obj.get("location_id", "") == params.get("location_id", "")
			"timed_objective":
				matches = obj.get("sub_type", "") == params.get("sub_type", "")
			"stealth":
				matches = obj.get("area_id", "") == params.get("area_id", "")
			"dialogue_choice":
				matches = obj.get("choice_id", "") == params.get("choice_id", "")
			"make_choice":
				matches = obj.get("choice_id", "") == params.get("choice_id", "")

		if matches:
			complete_objective(mission_id, i)
			break


# --- Kill Count ---

func get_kill_count(enemy_id: String) -> int:
	return _kill_counts.get(enemy_id, 0)


func reset_kill_counts() -> void:
	_kill_counts.clear()


# --- Queries ---

func get_mission_state(mission_id: String) -> int:
	return _mission_states.get(mission_id, MissionState.NOT_STARTED)


func get_active_mission_id() -> String:
	## Legacy compat — returns tracked mission or first active.
	if GameState.tracked_mission_id != "":
		return GameState.tracked_mission_id
	if GameState.active_mission_ids.size() > 0:
		return GameState.active_mission_ids[0]
	return ""


func is_mission_completed(mission_id: String) -> bool:
	return get_mission_state(mission_id) == MissionState.COMPLETED


func get_active_mission_data() -> Dictionary:
	var active_id := get_active_mission_id()
	if active_id == "":
		return {}
	return DataManager.get_mission(active_id)


func get_all_active_missions() -> Array:
	## Returns data dictionaries for all active missions.
	var result: Array = []
	for mid in GameState.active_mission_ids:
		var data := DataManager.get_mission(mid)
		if not data.is_empty():
			result.append(data)
	return result


func get_all_completed_missions() -> Array:
	## Returns data dictionaries for all completed missions.
	var result: Array = []
	for mid in _mission_states:
		if _mission_states[mid] == MissionState.COMPLETED:
			var data := DataManager.get_mission(mid)
			if not data.is_empty():
				result.append(data)
	return result


func get_objective_status(mission_id: String) -> Array:
	return _objective_status.get(mission_id, [])


func get_current_objective_index(mission_id: String) -> int:
	## Returns the first incomplete objective index, or -1 if all done.
	var status: Array = _objective_status.get(mission_id, [])
	for i in range(status.size()):
		if not status[i]:
			return i
	return -1


func get_current_objective_description() -> String:
	## Returns a human-readable description of the current objective for the tracked mission.
	var active_id := get_active_mission_id()
	if active_id == "":
		return "No active mission"

	var data: Dictionary = DataManager.get_mission(active_id)
	var objectives: Array = data.get("objectives", [])
	var idx := get_current_objective_index(active_id)
	if idx < 0 or idx >= objectives.size():
		return "All objectives complete"

	return _describe_objective(objectives[idx])


func _describe_objective(obj: Dictionary) -> String:
	# Use custom description if provided
	var custom_desc: String = obj.get("description", "")
	if custom_desc != "":
		return custom_desc

	match obj.get("type", ""):
		"talk_to_npc":
			return "Talk to %s" % obj.get("npc_id", "???")
		"reach_location":
			return "Go to %s" % obj.get("location_id", "???")
		"enter_dungeon":
			return "Enter %s" % obj.get("dungeon_id", "???")
		"deliver_item":
			return "Complete delivery %s" % obj.get("delivery_job_id", "???")
		"collect_item":
			return "Collect %s" % obj.get("item_id", "???")
		"return_home":
			return "Return home"
		"kill_enemies":
			var eid: String = obj.get("enemy_id", "???")
			var count: int = int(obj.get("count", 1))
			var killed := get_kill_count(eid)
			return "Kill %s (%d/%d)" % [eid, mini(killed, count), count]
		"survive_waves":
			return "Survive for %ds" % int(obj.get("duration", 60))
		"investigate":
			return "Investigate"
		"solve_puzzle":
			return "Solve the puzzle"
		"solve_riddle":
			return "Solve the riddle"
		"defend_location":
			return "Defend for %ds" % int(obj.get("duration", 45))
		"timed_objective":
			return "Complete within %ds" % int(obj.get("time_limit", 60))
		"stealth":
			return "Sneak through undetected"
		"dialogue_choice":
			return "Make a dialogue choice"
		"make_choice":
			return "Make a decision"
		_:
			return "Unknown objective"


# --- Save/Load helpers ---

func get_save_data() -> Dictionary:
	return {
		"mission_states": _mission_states.duplicate(true),
		"objective_status": _objective_status.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
		"tracked_mission_id": GameState.tracked_mission_id,
		"active_mission_ids": GameState.active_mission_ids.duplicate(),
		"kill_counts": _kill_counts.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	_mission_states = data.get("mission_states", {}).duplicate(true)
	_objective_status = data.get("objective_status", {}).duplicate(true)
	_kill_counts = data.get("kill_counts", {}).duplicate(true)
	GameState.current_mission_id = data.get("current_mission_id", "")
	GameState.tracked_mission_id = data.get("tracked_mission_id", data.get("current_mission_id", ""))
	GameState.active_mission_ids = data.get("active_mission_ids", []).duplicate()

	# Rebuild active_mission_ids from states if loading old save without it
	if GameState.active_mission_ids.is_empty():
		for mid in _mission_states:
			if _mission_states[mid] == MissionState.ACTIVE:
				GameState.active_mission_ids.append(mid)
