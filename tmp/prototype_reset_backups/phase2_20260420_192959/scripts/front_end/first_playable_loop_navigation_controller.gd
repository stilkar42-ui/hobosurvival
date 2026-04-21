class_name FirstPlayableLoopNavigationController
extends RefCounted

var _page_panels: Dictionary = {}
var _page_nav_row: Control = null
var _camp_nav_panel: Control = null
var _active_page: StringName = &""


func configure(page_panels: Dictionary, page_nav_row: Control, camp_nav_panel: Control) -> void:
	_page_panels = page_panels.duplicate()
	_page_nav_row = page_nav_row
	_camp_nav_panel = camp_nav_panel


func set_active_page(page_id: StringName) -> void:
	_active_page = page_id
	for entry_id in _page_panels.keys():
		var panel = _page_panels.get(entry_id, null)
		if panel != null:
			panel.visible = StringName(entry_id) == _active_page


func get_active_page() -> StringName:
	return _active_page


func sync_active_page_for_location(
	location_id: StringName,
	town_location_id: StringName,
	camp_location_id: StringName,
	town_page_id: StringName,
	camp_page_id: StringName,
	town_only_pages: Array,
	camp_only_pages: Array
) -> void:
	if location_id == camp_location_id:
		if _active_page in town_only_pages:
			set_active_page(camp_page_id)
		return
	if location_id == town_location_id and _active_page in camp_only_pages:
		set_active_page(town_page_id)


func is_world_camp_page(location_id: StringName, camp_location_id: StringName, camp_page_id: StringName) -> bool:
	return location_id == camp_location_id and _active_page == camp_page_id


func refresh_navigation_visibility(
	location_id: StringName,
	camp_location_id: StringName,
	camp_page_id: StringName,
	camp_sub_pages: Array
) -> void:
	if _page_nav_row != null:
		_page_nav_row.visible = not is_world_camp_page(location_id, camp_location_id, camp_page_id)
	if _camp_nav_panel != null:
		_camp_nav_panel.visible = location_id == camp_location_id and _active_page in camp_sub_pages
