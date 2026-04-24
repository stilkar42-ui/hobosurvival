class_name ItemSlotWidget
extends PanelContainer

signal slot_selected(item_id)

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _item_id: StringName = &""
var _title_label: Label = null
var _summary_label: Label = null
var _tags_label: Label = null
var _button: Button = null


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(self, "alt")

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_section_label(_title_label)
	root.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_summary_label)
	root.add_child(_summary_label)

	_tags_label = Label.new()
	_tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_small_label(_tags_label)
	root.add_child(_tags_label)

	_button = Button.new()
	_button.text = "Inspect"
	_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	PageUIThemeScript.style_button(_button)
	_button.pressed.connect(Callable(self, "_on_slot_pressed"))
	root.add_child(_button)


func set_item_data(data: Dictionary) -> void:
	_item_id = StringName(data.get("item_id", &""))
	_title_label.text = String(data.get("title", "Item"))
	_summary_label.text = String(data.get("summary", ""))
	var tags = data.get("tags", [])
	if tags is Array:
		var pieces: Array[String] = []
		for entry in tags:
			pieces.append(String(entry))
		_tags_label.text = ", ".join(pieces)
	else:
		_tags_label.text = String(tags)
	_button.text = String(data.get("action_label", "Inspect"))
	_button.disabled = not bool(data.get("enabled", true))
	_button.tooltip_text = String(data.get("tooltip_text", ""))


func _on_slot_pressed() -> void:
	slot_selected.emit(_item_id)
