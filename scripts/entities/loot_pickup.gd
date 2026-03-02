extends Area2D
## LootPickup — Collectible item or money pickup on the ground.
## Auto-collected when player walks over it. Despawns after timeout.

enum PickupType { ITEM, MONEY }

var _pickup_type: PickupType = PickupType.ITEM
var _item_id: String = ""
var _money_amount: int = 0
var _despawn_time: float = 10.0
var _age: float = 0.0


func setup_item(item_id: String) -> void:
	_pickup_type = PickupType.ITEM
	_item_id = item_id

	# Set color based on item rarity
	var item_data: Dictionary = DataManager.get_item(item_id)
	var sprite = get_node_or_null("PlaceholderSprite")
	if sprite and not item_data.is_empty():
		var rarity: String = item_data.get("rarity", "common")
		match rarity:
			"common":
				sprite.color = Color(0.8, 0.8, 0.8, 1.0)  # Light gray
			"rare":
				sprite.color = Color(0.3, 0.5, 1.0, 1.0)   # Blue
			"epic":
				sprite.color = Color(0.7, 0.3, 0.9, 1.0)   # Purple


func setup_money(amount: int) -> void:
	_pickup_type = PickupType.MONEY
	_money_amount = amount

	var sprite = get_node_or_null("PlaceholderSprite")
	if sprite:
		sprite.color = Color(1.0, 0.85, 0.0, 1.0)  # Gold


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_despawn_time = DataManager.get_config_value("loot_despawn_time", 10.0)

	# Pickup collision: detect player bodies
	collision_layer = 8   # Pickup layer
	collision_mask = 2    # Player layer


func _process(delta: float) -> void:
	_age += delta

	# Blink warning before despawn
	if _age >= _despawn_time - 2.0:
		var sprite = get_node_or_null("PlaceholderSprite")
		if sprite:
			sprite.visible = fmod(_age, 0.3) < 0.15

	if _age >= _despawn_time:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Only players can pick up
	if not body.has_method("set_player_id"):
		return

	var player_id: int = body.get("player_id")
	if player_id == null:
		player_id = 1

	match _pickup_type:
		PickupType.ITEM:
			if InventoryManager.add_item(player_id, _item_id):
				queue_free()
		PickupType.MONEY:
			EconomyManager.add_money(player_id, _money_amount)
			queue_free()
