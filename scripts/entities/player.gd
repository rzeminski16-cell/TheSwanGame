extends CharacterBody2D
## Player — 8-directional movement. Speed from PlayerManager.
## Combat logic does NOT live here (CombatManager handles that in Phase 2).

var player_id: int = 1

@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent


func set_player_id(id: int) -> void:
	player_id = id


func _physics_process(_delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	# Normalize so diagonal isn't faster
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var speed: float = PlayerManager.get_effective_stat(player_id, "move_speed")
	velocity = input_dir * speed
	move_and_slide()
