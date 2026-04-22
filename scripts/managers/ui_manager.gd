class_name UIManager
extends RefCounted

signal route_changed(route_name: StringName, page_name: StringName)

var _pages: Dictionary = {}
var _routes: Dictionary = {}
var _active_page: StringName = &""
var _active_route: StringName = &""
var _active_context: Dictionary = {}


func register_page(name: StringName, page) -> void:
	if name == &"" or page == null:
		return
	_pages[name] = page


func register_route(route_name: StringName, page_name: StringName) -> void:
	if route_name == &"" or page_name == &"" or not _pages.has(page_name):
		return
	_routes[route_name] = page_name


func open_page(name: StringName, context: Dictionary = {}) -> bool:
	var resolved_page_name = _resolve_page_name(name)
	if resolved_page_name == &"" or not _pages.has(resolved_page_name):
		return false
	_active_route = name
	_active_page = resolved_page_name
	_active_context = context.duplicate(true)
	var active_page = _pages.get(_active_page, null)
	if active_page != null and active_page.has_method("set_context"):
		active_page.set_context(_active_context)
	if active_page != null and active_page.has_method("set_route"):
		active_page.set_route(name)
	for page_name in _pages.keys():
		var page = _pages.get(page_name, null)
		var is_active = StringName(page_name) == _active_page
		if page == null:
			continue
		if page.has_method("set_visible"):
			page.set_visible(is_active)
		elif page is CanvasItem:
			page.visible = is_active
	route_changed.emit(_active_route, _active_page)
	return true


func switch_to(name: StringName) -> bool:
	return open_page(name, {})


func get_active_page() -> StringName:
	return _active_page


func get_active_route() -> StringName:
	return _active_route


func get_active_context() -> Dictionary:
	return _active_context.duplicate(true)


func get_page(page_name: StringName):
	return _pages.get(page_name, null)


func _resolve_page_name(name: StringName) -> StringName:
	if _pages.has(name):
		return name
	return StringName(_routes.get(name, &""))
