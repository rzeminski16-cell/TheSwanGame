extends Node
## MissionManager — Mission state tracking.
## Full implementation in Phase 5.

enum MissionState { NOT_STARTED, ACTIVE, COMPLETED, FAILED }

signal mission_started(mission_id: String)
signal mission_completed(mission_id: String)
signal objective_completed(mission_id: String, objective_index: int)

var _mission_states: Dictionary = {}  # mission_id → MissionState


func start_mission(_mission_id: String) -> bool:
	# Phase 5: Activate mission, load objectives
	push_warning("MissionManager.start_mission() not yet implemented")
	return false


func complete_objective(_mission_id: String, _objective_index: int) -> void:
	# Phase 5: Mark objective done, check if mission complete
	push_warning("MissionManager.complete_objective() not yet implemented")


func get_mission_state(mission_id: String) -> int:
	return _mission_states.get(mission_id, MissionState.NOT_STARTED)


func get_active_mission_id() -> String:
	return GameState.current_mission_id


func is_mission_completed(mission_id: String) -> bool:
	return get_mission_state(mission_id) == MissionState.COMPLETED
