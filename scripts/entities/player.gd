extends CharacterBody2D
## Player — 8-directional movement. Speed from PlayerManager.
## In multiplayer, only the local player processes input.
## Remote players are interpolated by NetworkSyncComponent.

var player_id: int = 1
var _is_local: bool = true

@onready var health_component: HealthComponent = $HealthComponent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var network_sync: NetworkSyncComponent = $NetworkSyncComponent


func set_player_id(id: int) -> void:
	player_id = id


func setup_multiplayer(peer_id: int) -> void:
	## Called after spawn to configure network authority.
	_is_local = not GameState.is_multiplayer or (peer_id == multiplayer.get_unique_id())
	network_sync.setup(peer_id)

	# Connect health changes to network sync
	if _is_local and GameState.is_multiplayer:
		health_component.health_changed.connect(_on_health_changed_for_sync)

	# Tint remote players to distinguish them
	if not _is_local:
		var sprite = get_node_or_null("PlaceholderSprite")
		if sprite:
			sprite.color = Color(0.6, 0.3, 0.8, 1.0)


func _on_health_changed_for_sync(current: float, maximum: float) -> void:
	network_sync.sync_health(current, maximum)


func _physics_process(_delta: float) -> void:
	if not _is_local:
		return  # Remote players interpolated by NetworkSyncComponent

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	# Normalize so diagonal isn't faster
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var speed: float = PlayerManager.get_effective_stat(player_id, "move_speed")
	velocity = input_dir * speed
	move_and_slide()
