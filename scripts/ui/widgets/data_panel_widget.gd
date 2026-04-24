class_name DataPanelWidget
extends "res://scripts/ui/widgets/base_panel_widget.gd"

var _body_label: Label = null


func _init() -> void:
	super._init()
	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_body_label(_body_label)
	get_content_root().add_child(_body_label)


func set_data(data) -> void:
	if data is PackedStringArray:
		_body_label.text = "\n".join(data)
	elif data is Array:
		var lines: Array[String] = []
		for entry in data:
			lines.append(String(entry))
		_body_label.text = "\n".join(lines)
	else:
		_body_label.text = String(data)


func get_label() -> Label:
	return _body_label
