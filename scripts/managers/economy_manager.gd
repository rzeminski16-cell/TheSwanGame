extends Node
## EconomyManager — Money tracking, rent, income.
## Full implementation in Phase 3.

signal money_changed(player_id: int, new_amount: int)
signal rent_due(amount: int)
signal rent_paid(player_id: int, amount: int)

var _player_money: Dictionary = {}  # player_id → int


func add_money(_player_id: int, _amount: int) -> void:
	# Phase 3: Add money, emit signal
	push_warning("EconomyManager.add_money() not yet implemented")


func deduct_money(_player_id: int, _amount: int) -> bool:
	# Phase 3: Deduct if sufficient, return success
	push_warning("EconomyManager.deduct_money() not yet implemented")
	return false


func get_money(player_id: int) -> int:
	return _player_money.get(player_id, 0)


func pay_rent(_player_id: int) -> bool:
	# Phase 3/5: Deduct weekly rent from player
	push_warning("EconomyManager.pay_rent() not yet implemented")
	return false


func get_weekly_rent() -> int:
	var config: Dictionary = DataManager.get_config()
	return config.get("base_weekly_rent", 250)
