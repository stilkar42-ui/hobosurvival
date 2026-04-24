class_name ActionButtonWidget
extends PanelContainer

signal pressed(action_id)

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _action_id: StringName = &""
var _button: Button = null


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button = Button.new()
	_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_button(_button, true)
	_button.pressed.connect(Callable(self, "_on_button_pressed"))
	add_child(_button)


func set_action_id(action_id: StringName) -> void:
	_action_id = action_id


func set_label(label_text: String) -> void:
	_button.text = label_text


func set_enabled(enabled: bool) -> void:
	_button.disabled = not enabled


func set_action_tooltip(tooltip_text: String) -> void:
	_button.tooltip_text = tooltip_text


func set_accent(accent: bool) -> void:
	PageUIThemeScript.style_button(_button, accent)


func get_button() -> Button:
	return _button


func _on_button_pressed() -> void:
	pressed.emit(_action_id)
