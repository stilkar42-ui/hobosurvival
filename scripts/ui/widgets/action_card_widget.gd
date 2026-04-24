class_name ActionCardWidget
extends PanelContainer

signal selected(action_id)

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _action_id: StringName = &""
var _title_label: Label = null
var _description_label: Label = null
var _requirements_label: Label = null
var _status_label: Label = null
var _action_button: Button = null


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(self, "dark")

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_section_label(_title_label, true)
	root.add_child(_title_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_description_label)
	root.add_child(_description_label)

	_requirements_label = Label.new()
	_requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_small_label(_requirements_label)
	root.add_child(_requirements_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_status_label, true)
	root.add_child(_status_label)

	_action_button = Button.new()
	_action_button.text = "Select"
	_action_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	PageUIThemeScript.style_button(_action_button, true)
	_action_button.pressed.connect(Callable(self, "_on_action_pressed"))
	root.add_child(_action_button)


func set_data(data: Dictionary) -> void:
	set_action_id(StringName(data.get("action_id", &"")))
	set_title(String(data.get("title", "Action")))
	set_description(String(data.get("description", "")))
	set_requirements(data.get("requirements", []))
	set_status(String(data.get("status", "")))
	set_action_label(String(data.get("action_label", "Select")))
	set_enabled(bool(data.get("enabled", true)))
	_action_button.tooltip_text = String(data.get("tooltip_text", ""))


func set_action_id(action_id: StringName) -> void:
	_action_id = action_id


func set_title(title_text: String) -> void:
	_title_label.text = title_text


func set_description(description_text: String) -> void:
	_description_label.text = description_text


func set_requirements(requirements) -> void:
	if requirements is PackedStringArray:
		_requirements_label.text = "\n".join(requirements)
	elif requirements is Array:
		var lines: Array[String] = []
		for entry in requirements:
			lines.append(String(entry))
		_requirements_label.text = "\n".join(lines)
	else:
		_requirements_label.text = String(requirements)


func set_status(status_text: String) -> void:
	_status_label.text = status_text


func set_action_label(label_text: String) -> void:
	_action_button.text = label_text


func set_enabled(enabled: bool) -> void:
	_action_button.disabled = not enabled


func _on_action_pressed() -> void:
	selected.emit(_action_id)
