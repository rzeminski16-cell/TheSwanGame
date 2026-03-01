extends Node
## EconomyManager — Money tracking, rent, income.
## Full implementation in Phase 3.

signal money_changed(player_id: int, new_amount: int)
signal rent_due(amount: int)
signal rent_paid(player_id: int, amount: int)

var _player_money: Dictionary = {}  # player_id → int


func add_money(player_id: int, amount: int) -> void:
	if amount <= 0:
		return
	if not _player_money.has(player_id):
		_player_money[player_id] = 0
	_player_money[player_id] += amount
	money_changed.emit(player_id, _player_money[player_id])
	print("EconomyManager: Player %d gained %d money (total: %d)" % [player_id, amount, _player_money[player_id]])


func deduct_money(player_id: int, amount: int) -> bool:
	if not _player_money.has(player_id):
		_player_money[player_id] = 0
	if _player_money[player_id] < amount:
		return false
	_player_money[player_id] -= amount
	money_changed.emit(player_id, _player_money[player_id])
	return true


func get_money(player_id: int) -> int:
	return _player_money.get(player_id, 0)


func pay_rent(_player_id: int) -> bool:
	# Phase 3/5: Deduct weekly rent from player
	push_warning("EconomyManager.pay_rent() not yet implemented")
	return false


func get_weekly_rent() -> int:
	var config: Dictionary = DataManager.get_config()
	return config.get("base_weekly_rent", 250)
