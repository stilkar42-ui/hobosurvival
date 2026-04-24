class_name DetailPanelWidget
extends "res://scripts/ui/widgets/base_panel_widget.gd"

var _detail_title_label: Label = null
var _summary_label: Label = null
var _details_label: Label = null
var _extra_root: VBoxContainer = null


func _init() -> void:
	super._init()
	_detail_title_label = Label.new()
	_detail_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_header_label(_detail_title_label, true)
	get_content_root().add_child(_detail_title_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_summary_label)
	get_content_root().add_child(_summary_label)

	_details_label = Label.new()
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_body_label(_details_label, true)
	get_content_root().add_child(_details_label)

	_extra_root = VBoxContainer.new()
	_extra_root.add_theme_constant_override("separation", 8)
	_extra_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_extra_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_content_root().add_child(_extra_root)


func set_detail(detail: Dictionary) -> void:
	_detail_title_label.text = String(detail.get("title", "Detail"))
	_summary_label.text = String(detail.get("summary", ""))
	var blocks = detail.get("blocks", [])
	if blocks is Array:
		var lines: Array[String] = []
		for block in blocks:
			lines.append(String(block))
		_details_label.text = "\n".join(lines)
	else:
		_details_label.text = String(blocks)


func set_detail_content(control: Control) -> void:
	clear_detail_content()
	if control != null:
		_extra_root.add_child(control)


func clear_detail_content() -> void:
	for child in _extra_root.get_children():
		_extra_root.remove_child(child)
		child.queue_free()
