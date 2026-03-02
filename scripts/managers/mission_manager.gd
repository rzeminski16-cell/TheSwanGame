extends Node
## MissionManager — Mission state tracking, objective completion, rewards.
## Mission data loaded from DataManager (missions.json).
## Objectives: talk_to_npc, enter_dungeon, collect_item, return_home, deliver_item, reach_location.

enum MissionState { NOT_STARTED, ACTIVE, COMPLETED, FAILED }

signal mission_started(mission_id: String)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)
signal objective_completed(mission_id: String, objective_index: int)

var _mission_states: Dictionary = {}  # mission_id → MissionState
var _objective_status: Dictionary = {}  # mission_id → Array[bool]


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

	_mission_states[mission_id] = MissionState.ACTIVE
	GameState.current_mission_id = mission_id

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

	# Auto-start next mission if defined
	var next_id = data.get("next_mission_id")
	if next_id != null and next_id != "":
		start_mission(next_id)
	else:
		GameState.current_mission_id = ""


func fail_mission(mission_id: String) -> void:
	if get_mission_state(mission_id) != MissionState.ACTIVE:
		return

	_mission_states[mission_id] = MissionState.FAILED
	GameState.current_mission_id = ""
	mission_failed.emit(mission_id)
	print("MissionManager: Mission '%s' failed" % mission_id)


# --- Objective Triggers ---

func notify_talk_to_npc(npc_id: String) -> void:
	_check_objective("talk_to_npc", {"npc_id": npc_id})


func notify_reach_location(location_id: String) -> void:
	_check_objective("reach_location", {"location_id": location_id})


func notify_enter_dungeon(dungeon_id: String) -> void:
	_check_objective("enter_dungeon", {"dungeon_id": dungeon_id})


func notify_deliver_item(delivery_job_id: String) -> void:
	_check_objective("deliver_item", {"delivery_job_id": delivery_job_id})


func notify_collect_item(item_id: String) -> void:
	_check_objective("collect_item", {"item_id": item_id})


func notify_return_home() -> void:
	_check_objective("return_home", {})


func _check_objective(obj_type: String, params: Dictionary) -> void:
	var active_id := get_active_mission_id()
	if active_id == "":
		return

	var data: Dictionary = DataManager.get_mission(active_id)
	var objectives: Array = data.get("objectives", [])
	var status: Array = _objective_status.get(active_id, [])

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

		if matches:
			complete_objective(active_id, i)
			break


# --- Queries ---

func get_mission_state(mission_id: String) -> int:
	return _mission_states.get(mission_id, MissionState.NOT_STARTED)


func get_active_mission_id() -> String:
	return GameState.current_mission_id


func is_mission_completed(mission_id: String) -> bool:
	return get_mission_state(mission_id) == MissionState.COMPLETED


func get_active_mission_data() -> Dictionary:
	var active_id := get_active_mission_id()
	if active_id == "":
		return {}
	return DataManager.get_mission(active_id)


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
	## Returns a human-readable description of the current objective.
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
		_:
			return "Unknown objective"


# --- Save/Load helpers (Phase 6) ---

func get_save_data() -> Dictionary:
	return {
		"mission_states": _mission_states.duplicate(true),
		"objective_status": _objective_status.duplicate(true),
		"current_mission_id": GameState.current_mission_id,
	}


func load_save_data(data: Dictionary) -> void:
	_mission_states = data.get("mission_states", {}).duplicate(true)
	_objective_status = data.get("objective_status", {}).duplicate(true)
	GameState.current_mission_id = data.get("current_mission_id", "")
