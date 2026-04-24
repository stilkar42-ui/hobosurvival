class_name VerticalListWidget
extends "res://scripts/ui/widgets/base_panel_widget.gd"

var _scroll: ScrollContainer = null
var _list_root: VBoxContainer = null


func _init() -> void:
	super._init()
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	get_content_root().add_child(_scroll)

	_list_root = VBoxContainer.new()
	_list_root.add_theme_constant_override("separation", 8)
	_list_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list_root)


func clear_items() -> void:
	for child in _list_root.get_children():
		_list_root.remove_child(child)
		child.queue_free()


func add_item(control: Control) -> void:
	if control == null:
		return
	_list_root.add_child(control)


func get_list_root() -> VBoxContainer:
	return _list_root


func get_item_count() -> int:
	return _list_root.get_child_count()
