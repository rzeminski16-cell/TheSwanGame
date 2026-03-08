extends ColorRect
## ScreenTransition — Full-screen fade overlay for scene transitions.
## Sits on UIManager's CanvasLayer. Fades to black and back.

signal fade_out_complete()
signal fade_in_complete()

const FADE_DURATION := 0.4

var _tween: Tween = null


func _ready() -> void:
	# Full-screen black overlay
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000
	anchors_preset = Control.PRESET_FULL_RECT
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = true


func fade_out(duration: float = FADE_DURATION) -> void:
	## Fade TO black (screen goes dark).
	_kill_tween()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(self, "color:a", 1.0, duration)
	_tween.tween_callback(func(): fade_out_complete.emit())


func fade_in(duration: float = FADE_DURATION) -> void:
	## Fade FROM black (screen becomes visible).
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "color:a", 0.0, duration)
	_tween.tween_callback(func():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade_in_complete.emit()
	)


func instant_black() -> void:
	_kill_tween()
	color.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP


func instant_clear() -> void:
	_kill_tween()
	color.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
		_tween = null
