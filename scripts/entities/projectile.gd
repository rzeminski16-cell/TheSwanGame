extends Area2D
## Projectile — Moves in a direction and applies damage on hit.
## Used by both player weapon and ranged enemies.

var _direction: Vector2 = Vector2.RIGHT
var _damage: float = 10.0
var _owner_node: Node = null
var _owner_type: String = "player"  # "player" or "enemy"
var _speed: float = 400.0
var _lifetime: float = 3.0
var _age: float = 0.0


func setup(direction: Vector2, damage: float, owner_node: Node, owner_type: String = "player") -> void:
	_direction = direction.normalized()
	_damage = damage
	_owner_node = owner_node
	_owner_type = owner_type
	rotation = direction.angle()


func _ready() -> void:
	# Connect body_entered for collision detection
	body_entered.connect(_on_body_entered)

	# Collision layers: 1=walls, 2=player, 4=enemy, 8=pickup
	if _owner_type == "player":
		collision_layer = 0
		collision_mask = 4   # Detect enemies
	else:
		collision_layer = 0
		collision_mask = 2   # Detect players

	# Set placeholder sprite color
	var sprite = get_node_or_null("PlaceholderSprite")
	if sprite:
		if _owner_type == "player":
			sprite.color = Color(1.0, 1.0, 0.2, 1.0)  # Yellow
		else:
			sprite.color = Color(1.0, 0.3, 0.3, 1.0)  # Red


func _process(delta: float) -> void:
	position += _direction * _speed * delta
	_age += delta
	if _age >= _lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Don't hit owner
	if body == _owner_node:
		return

	# Apply damage through CombatManager
	if _owner_node and is_instance_valid(_owner_node):
		CombatManager.apply_damage(_owner_node, body, _damage)

	queue_free()
