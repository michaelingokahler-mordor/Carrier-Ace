extends RefCounted
class_name GameInput

static func setup() -> void:
	_add("flight_left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add("flight_right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_add("flight_up", [KEY_W, KEY_UP], JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_add("flight_down", [KEY_S, KEY_DOWN], JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_add("fire", [KEY_SPACE, KEY_Z], JOY_BUTTON_A)
	_add("roll", [KEY_SHIFT, KEY_X], JOY_BUTTON_B)
	_add("pause_game", [KEY_ESCAPE, KEY_P], JOY_BUTTON_START)
	_add("fullscreen", [KEY_F11], -1)

static func _add(action: String, keys: Array, button: int, axis: int = -1, value: float = 0) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.22)
	for key in keys:
		var keyboard := InputEventKey.new()
		keyboard.physical_keycode = key
		InputMap.action_add_event(action, keyboard)
	if button >= 0:
		var pad := InputEventJoypadButton.new()
		pad.button_index = button
		InputMap.action_add_event(action, pad)
	if axis >= 0:
		var stick := InputEventJoypadMotion.new()
		stick.axis = axis
		stick.axis_value = value
		InputMap.action_add_event(action, stick)
