extends Node
## Main scene script — root of the game.
## Children: SceneManager, UIManager, AudioManager

@onready var scene_manager: Node = $SceneManager
@onready var ui_manager: CanvasLayer = $UIManager
@onready var audio_manager: Node = $AudioManager


func _ready() -> void:
	print("Main: Game starting.")
	print("Main: DataManager config loaded = %s" % str(DataManager.get_config().size() > 0))
	print("Main: Enemies loaded = %d" % DataManager.get_all_enemies().size())
	print("Main: Items loaded = %d" % DataManager.get_all_items().size())
	print("Main: Skills loaded = %d" % DataManager.get_all_skills().size())
	print("Main: Dungeons loaded = %d" % DataManager.get_all_dungeons().size())
	print("Main: Missions loaded = %d" % DataManager.get_all_missions().size())

	# Load the test playground by default
	scene_manager.change_scene("res://scenes/TestPlayground.tscn")
