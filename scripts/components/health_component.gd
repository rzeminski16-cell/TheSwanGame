extends Node
class_name HealthComponent
## HealthComponent — Tracks current and max health.
## No passive regen. Healed by items/events only.

signal health_changed(current: float, maximum: float)
signal died()

var max_health: float = 100.0
var current_health: float = 100.0
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


func set_max_health(value: float) -> void:
	var was_full := is_equal_approx(current_health, max_health)
	max_health = maxf(1.0, value)
	if was_full:
		current_health = max_health
	else:
		current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func heal_full() -> void:
	if is_dead:
		return
	current_health = max_health
	health_changed.emit(current_health, max_health)


func revive(health_percent: float = 1.0) -> void:
	is_dead = false
	current_health = max_health * clampf(health_percent, 0.1, 1.0)
	health_changed.emit(current_health, max_health)


func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
