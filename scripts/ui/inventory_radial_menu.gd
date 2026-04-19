class_name InventoryRadialMenu
extends Control

signal action_selected(action_id: int)
signal canceled

const OUTER_RADIUS := 118.0
const ACTION_BUTTON_SIZE := Vector2(150.0, 44.0)
const CENTER_BUTTON_SIZE := Vector2(104.0, 40.0)
const VIEWPORT_PADDING := 22.0

var _action_buttons: Array[Button] = []
var _cancel_button: Button = null
var _center_position := Vector2.ZERO


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	z_index = 30


func popup_actions(action_entries: Array, screen_position: Vector2) -> void:
	_clear_buttons()

	var non_cancel_actions: Array = []
	var cancel_action: Dictionary = {}
	for action_entry in action_entries:
		if not (action_entry is Dictionary):
			continue
		if bool(action_entry.get("is_cancel", false)):
			cancel_action = action_entry
			continue
		non_cancel_actions.append(action_entry)

	_center_position = _clamp_center(screen_position)
	_build_action_buttons(non_cancel_actions)
	_build_cancel_button(cancel_action)
	visible = true


func hide_menu() -> void:
	visible = false
	_clear_buttons()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		canceled.emit()
		hide_menu()


func _build_action_buttons(action_entries: Array) -> void:
	if action_entries.is_empty():
		return

	var angle_step := TAU / float(action_entries.size())
	var start_angle := -PI / 2.0
	for index in range(action_entries.size()):
		var action_entry: Dictionary = action_entries[index]
		var action_button := Button.new()
		action_button.text = String(action_entry.get("label", "Action"))
		action_button.tooltip_text = String(action_entry.get("tooltip", ""))
		action_button.custom_minimum_size = ACTION_BUTTON_SIZE
		action_button.size = ACTION_BUTTON_SIZE
		_apply_action_button_style(action_button)

		var angle = start_angle + (angle_step * float(index))
		var button_position = _center_position + (Vector2.RIGHT.rotated(angle) * OUTER_RADIUS) - (ACTION_BUTTON_SIZE * 0.5)
		action_button.position = _clamp_button_position(button_position, ACTION_BUTTON_SIZE)
		action_button.pressed.connect(Callable(self, "_on_action_button_pressed").bind(int(action_entry.get("id", -1))))
		add_child(action_button)
		_action_buttons.append(action_button)


func _build_cancel_button(cancel_action: Dictionary) -> void:
	_cancel_button = Button.new()
	_cancel_button.text = String(cancel_action.get("label", "Cancel"))
	_cancel_button.tooltip_text = String(cancel_action.get("tooltip", "Close this menu."))
	_cancel_button.custom_minimum_size = CENTER_BUTTON_SIZE
	_cancel_button.size = CENTER_BUTTON_SIZE
	_apply_cancel_button_style(_cancel_button)
	_cancel_button.position = _clamp_button_position(_center_position - (CENTER_BUTTON_SIZE * 0.5), CENTER_BUTTON_SIZE)
	_cancel_button.pressed.connect(Callable(self, "_on_cancel_pressed"))
	add_child(_cancel_button)


func _on_action_button_pressed(action_id: int) -> void:
	hide_menu()
	action_selected.emit(action_id)


func _on_cancel_pressed() -> void:
	hide_menu()
	canceled.emit()


func _clear_buttons() -> void:
	for action_button in _action_buttons:
		if is_instance_valid(action_button):
			action_button.queue_free()
	_action_buttons.clear()
	if is_instance_valid(_cancel_button):
		_cancel_button.queue_free()
	_cancel_button = null


func _clamp_center(screen_position: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var safe_left = VIEWPORT_PADDING + OUTER_RADIUS + (ACTION_BUTTON_SIZE.x * 0.5)
	var safe_right = viewport_size.x - safe_left
	var safe_top = VIEWPORT_PADDING + OUTER_RADIUS + (ACTION_BUTTON_SIZE.y * 0.5)
	var safe_bottom = viewport_size.y - safe_top
	return Vector2(
		clampf(screen_position.x, safe_left, safe_right),
		clampf(screen_position.y, safe_top, safe_bottom)
	)


func _clamp_button_position(position: Vector2, button_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		clampf(position.x, VIEWPORT_PADDING, viewport_size.x - button_size.x - VIEWPORT_PADDING),
		clampf(position.y, VIEWPORT_PADDING, viewport_size.y - button_size.y - VIEWPORT_PADDING)
	)


func _apply_action_button_style(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("f1e3cf"))
	button.add_theme_color_override("font_hover_color", Color("fff2dd"))
	button.add_theme_color_override("font_pressed_color", Color("fff2dd"))
	button.add_theme_stylebox_override("normal", _make_style(Color("342a22"), Color("9d7b54")))
	button.add_theme_stylebox_override("hover", _make_style(Color("403328"), Color("b68d5f")))
	button.add_theme_stylebox_override("pressed", _make_style(Color("2b231d"), Color("9d7b54")))


func _apply_cancel_button_style(button: Button) -> void:
	button.add_theme_color_override("font_color", Color("efe2cd"))
	button.add_theme_color_override("font_hover_color", Color("fff0db"))
	button.add_theme_color_override("font_pressed_color", Color("fff0db"))
	button.add_theme_stylebox_override("normal", _make_style(Color("272522"), Color("71675d")))
	button.add_theme_stylebox_override("hover", _make_style(Color("302d29"), Color("8d7c6a")))
	button.add_theme_stylebox_override("pressed", _make_style(Color("22201d"), Color("71675d")))


func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 8
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style
