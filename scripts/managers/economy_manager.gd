extends Node
## EconomyManager — Money tracking, rent, income, economy skill bonuses.
## Reads base values from global_config.json.
## Skill bonuses (rent_reduction, money_drop, delivery_reward) from SkillManager.

signal money_changed(player_id: int, new_amount: int)
signal rent_due(amount: int)
signal rent_paid(player_id: int, amount: int)
signal rent_failed(player_id: int, amount: int)

var _player_money: Dictionary = {}  # player_id → int


# --- Money Operations ---

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


# --- Rent ---

func pay_rent(player_id: int) -> bool:
	var rent: int = get_effective_rent(player_id)
	rent_due.emit(rent)
	if deduct_money(player_id, rent):
		rent_paid.emit(player_id, rent)
		print("EconomyManager: Player %d paid rent of %d" % [player_id, rent])
		return true
	else:
		rent_failed.emit(player_id, rent)
		print("EconomyManager: Player %d cannot afford rent of %d (has %d)" % [player_id, rent, get_money(player_id)])
		return false


func get_weekly_rent_base() -> int:
	return DataManager.get_config_value("base_weekly_rent", 250)


func get_effective_rent(player_id: int) -> int:
	var base_rent: int = get_weekly_rent_base()
	# Apply rent_reduction from skills (e.g. Haggler: -10% rent)
	var skill_mods: Dictionary = SkillManager.get_skill_modifiers(player_id)
	var rent_reduction: float = float(skill_mods.get("rent_reduction_percent", 0))
	var effective: float = float(base_rent) * (1.0 - rent_reduction)
	return maxi(0, roundi(effective))


func get_weekly_rent() -> int:
	# Convenience: returns effective rent for player 1
	return get_effective_rent(1)


# --- Economy Skill Bonuses ---

func get_money_drop_bonus(player_id: int) -> float:
	## Returns the bonus multiplier for money drops (e.g. 0.10 = +10%).
	var skill_mods: Dictionary = SkillManager.get_skill_modifiers(player_id)
	return float(skill_mods.get("money_drop_percent", 0))


func get_delivery_reward_bonus(player_id: int) -> float:
	## Returns the bonus multiplier for delivery rewards (e.g. 0.10 = +10%).
	var skill_mods: Dictionary = SkillManager.get_skill_modifiers(player_id)
	return float(skill_mods.get("delivery_reward_percent", 0))


func get_delivery_reward(player_id: int) -> int:
	## Returns the effective delivery reward for the player.
	var base: int = DataManager.get_config_value("base_delivery_reward", 50)
	var bonus: float = get_delivery_reward_bonus(player_id)
	return roundi(float(base) * (1.0 + bonus))


# --- Save/Load helpers (Phase 6) ---

func get_save_data(player_id: int) -> int:
	return get_money(player_id)


func load_save_data(player_id: int, money: int) -> void:
	_player_money[player_id] = money
	money_changed.emit(player_id, money)
