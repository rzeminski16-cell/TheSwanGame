extends Node
class_name StaminaComponent
## StaminaComponent — Tracks stamina with passive regeneration.
## Regen pauses briefly after stamina is used.

signal stamina_changed(current: float, maximum: float)
signal stamina_depleted()

var max_stamina: float = 100.0
var current_stamina: float = 100.0

## Stamina regenerated per second
@export var regen_rate: float = 15.0
## Seconds to wait after using stamina before regen starts
@export var regen_delay: float = 1.0

var _regen_timer: float = 0.0


func _ready() -> void:
	current_stamina = max_stamina


func _process(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return

	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)
		stamina_changed.emit(current_stamina, max_stamina)


func set_max_stamina(value: float) -> void:
	var was_full := is_equal_approx(current_stamina, max_stamina)
	max_stamina = maxf(1.0, value)
	if was_full:
		current_stamina = max_stamina
	else:
		current_stamina = minf(current_stamina, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)


func use_stamina(amount: float) -> bool:
	if current_stamina < amount:
		stamina_depleted.emit()
		return false
	current_stamina = maxf(0.0, current_stamina - amount)
	_regen_timer = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)
	if current_stamina <= 0.0:
		stamina_depleted.emit()
	return true


func get_stamina_percent() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return current_stamina / max_stamina
