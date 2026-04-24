class_name BasePanelWidget
extends PanelContainer

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _root: VBoxContainer = null
var _title_label: Label = null
var _content_root: VBoxContainer = null


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(self, "panel")

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_root)

	_title_label = Label.new()
	_title_label.visible = false
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_section_label(_title_label)
	_root.add_child(_title_label)

	_content_root = VBoxContainer.new()
	_content_root.add_theme_constant_override("separation", 8)
	_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(_content_root)


func set_variant(variant: String) -> void:
	PageUIThemeScript.apply_panel_variant(self, variant)


func set_title(title_text: String, accent: bool = false) -> void:
	_title_label.text = title_text
	_title_label.visible = title_text.strip_edges() != ""
	PageUIThemeScript.style_section_label(_title_label, accent)


func set_spacing(separation: int) -> void:
	_root.add_theme_constant_override("separation", separation)
	_content_root.add_theme_constant_override("separation", separation)


func get_content_root() -> VBoxContainer:
	return _content_root


func clear_content() -> void:
	for child in _content_root.get_children():
		_content_root.remove_child(child)
		child.queue_free()
