extends Node
## Main scene script — root of the game.
## Children: SceneManager, UIManager, AudioManager

@onready var scene_manager: Node = $SceneManager
@onready var ui_manager: CanvasLayer = $UIManager
@onready var audio_manager: Node = $AudioManager


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Main: Game starting.")
	print("Main: DataManager config loaded = %s" % str(DataManager.get_config().size() > 0))
	print("Main: Enemies loaded = %d" % DataManager.get_all_enemies().size())
	print("Main: Items loaded = %d" % DataManager.get_all_items().size())
	print("Main: Skills loaded = %d" % DataManager.get_all_skills().size())
	print("Main: Dungeons loaded = %d" % DataManager.get_all_dungeons().size())
	print("Main: Missions loaded = %d" % DataManager.get_all_missions().size())

	# Show main menu on launch
	ui_manager.show_main_menu()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.is_action_pressed("toggle_inventory"):
		ui_manager.toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_skill_tree"):
		ui_manager.toggle_skill_tree()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_quest_log"):
		ui_manager.toggle_quest_log()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		ui_manager._toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F3:
		print("Main: F3 detected, opening debug menu")
		ui_manager.toggle_debug_menu()
		get_viewport().set_input_as_handled()
