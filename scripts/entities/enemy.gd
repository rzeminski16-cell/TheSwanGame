extends CharacterBody2D
## Enemy — Data-driven enemy entity.
## Initialized by CombatManager with data from enemies.json.
## AI behavior delegated to AIComponent child.

var enemy_id: String = ""
var enemy_data: Dictionary = {}
var _scaled_stats: Dictionary = {}

@onready var health_component: HealthComponent = $HealthComponent
@onready var ai_component = $AIComponent
@onready var sprite: ColorRect = $PlaceholderSprite


func initialize(data: Dictionary, scaling: Dictionary = {}) -> void:
	enemy_data = data
	enemy_id = data.get("id", "")
	_apply_scaling(data.get("base_stats", {}), scaling)


func _apply_scaling(base_stats: Dictionary, scaling: Dictionary) -> void:
	_scaled_stats = base_stats.duplicate()

	# Apply dungeon scaling multipliers
	var health_mult: float = scaling.get("enemy_health_multiplier", 1.0)
	var damage_mult: float = scaling.get("enemy_damage_multiplier", 1.0)

	_scaled_stats["health"] = float(_scaled_stats.get("health", 50)) * health_mult
	_scaled_stats["damage"] = float(_scaled_stats.get("damage", 8)) * damage_mult


func _ready() -> void:
	# Set health from scaled stats
	if health_component:
		health_component.set_max_health(float(_scaled_stats.get("health", 50)))

	# Set placeholder color based on enemy type
	if sprite:
		var enemy_type: String = enemy_data.get("type", "melee")
		match enemy_type:
			"melee":
				sprite.color = Color(0.9, 0.3, 0.2, 1.0)  # Red
			"ranged":
				sprite.color = Color(0.9, 0.6, 0.1, 1.0)  # Orange
			"boss":
				sprite.color = Color(0.8, 0.1, 0.8, 1.0)  # Purple
				sprite.offset_left = -16.0
				sprite.offset_top = -16.0
				sprite.offset_right = 16.0
				sprite.offset_bottom = 16.0

	# Initialize AI
	if ai_component and ai_component.has_method("setup"):
		ai_component.setup(self)


func get_stat(stat: String) -> float:
	return float(_scaled_stats.get(stat, 0))


func get_enemy_type() -> String:
	return enemy_data.get("type", "melee")


func play_death() -> void:
	# Simple death: disable, then free after a brief delay
	set_physics_process(false)
	if ai_component:
		ai_component.set_process(false)
		ai_component.set_physics_process(false)
	# Fade out
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
