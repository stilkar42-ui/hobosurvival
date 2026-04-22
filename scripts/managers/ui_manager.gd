class_name UIManager
extends RefCounted

var _pages: Dictionary = {}
var _active_page: StringName = &""


func register_page(name: StringName, node) -> void:
	if name == &"" or node == null:
		return
	_pages[name] = node


func switch_to(name: StringName) -> bool:
	if not _pages.has(name):
		return false
	_active_page = name
	for page_name in _pages.keys():
		var page_node = _pages.get(page_name, null)
		if page_node != null and page_node is CanvasItem:
			page_node.visible = StringName(page_name) == _active_page
	return true


func get_active_page() -> StringName:
	return _active_page
