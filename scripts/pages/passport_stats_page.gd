class_name PassportStatsPage
extends RefCounted

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _overlay: Control = null
var _close_button: Button = null
var _open_passport_button: Button = null
var _passport_panel = null
var _game_state_manager = null
var _stats_manager = null
var _inventory_manager = null
var _location_manager = null
var _ui_manager = null
var _character_rules = null
var _resolve_return_route := Callable()
var _return_route: StringName = &"town"


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_overlay = deps.get("overlay", null)
	_close_button = deps.get("close_button", null)
	_open_passport_button = deps.get("open_passport_button", null)
	_passport_panel = deps.get("passport_panel", null)
	_game_state_manager = deps.get("game_state_manager", null)
	_stats_manager = deps.get("stats_manager", null)
	_inventory_manager = deps.get("inventory_manager", null)
	_location_manager = deps.get("location_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_character_rules = deps.get("character_rules", null)
	_resolve_return_route = deps.get("resolve_return_route", Callable())

	if _overlay != null:
		_overlay.visible = false
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_close")):
		_close_button.pressed.connect(Callable(self, "_close"))
	if _open_passport_button != null:
		_open_passport_button.text = "Open Passport"
		if not _open_passport_button.pressed.is_connected(Callable(self, "_open")):
			_open_passport_button.pressed.connect(Callable(self, "_open"))
	_apply_layout_theme()
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_context(context: Dictionary) -> void:
	_return_route = StringName(context.get("return_route", _return_route))


func set_route(_route_name: StringName) -> void:
	pass


func set_visible(visible: bool) -> void:
	if _overlay != null:
		_overlay.visible = visible


func refresh_from_state(player_state) -> void:
	if _passport_panel == null:
		return
	if player_state == null:
		_passport_panel.set_passport_data(null)
		_passport_panel.set_external_sections([])
		return
	_passport_panel.set_passport_data(player_state.passport_profile)
	var external_sections: Array = _build_surface_sections(player_state)
	if _character_rules != null and _character_rules.has_method("get_derived_snapshot") and _character_rules.has_method("build_passport_sections"):
		var derived_snapshot = _character_rules.get_derived_snapshot(player_state, {
			"stats_manager": _stats_manager,
			"inventory_manager": _inventory_manager,
			"location_manager": _location_manager
		})
		external_sections.append_array(_character_rules.build_passport_sections(derived_snapshot))
	_passport_panel.set_external_sections(external_sections)


func handle_input(event: InputEvent) -> bool:
	if _overlay == null or not _overlay.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		_close()
		return true
	return false


func _apply_layout_theme() -> void:
	if _overlay != null:
		PageUIThemeScript.style_overlay_backdrop(_overlay.get_node_or_null("Backdrop"))
		var window = _overlay.get_node_or_null("PassportMargin/PassportWindow") as PanelContainer
		PageUIThemeScript.apply_panel_variant(window, "panel")
		var title = _overlay.get_node_or_null("PassportMargin/PassportWindow/PassportRoot/PassportHeader/PassportTitle") as Label
		PageUIThemeScript.style_header_label(title, true)
	if _close_button != null:
		PageUIThemeScript.style_button(_close_button)
	if _open_passport_button != null:
		PageUIThemeScript.style_button(_open_passport_button, true)


func _open() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(&"passport_stats", {"return_route": _ui_manager.get_active_route()})


func _close() -> void:
	if _ui_manager == null:
		return
	var route = _return_route
	if route == &"" and not _resolve_return_route.is_null():
		route = StringName(_resolve_return_route.call())
	_ui_manager.open_page(route)


func _build_surface_sections(player_state) -> Array:
	var sections: Array = []
	if player_state == null:
		return sections
	var inventory = _inventory_manager.get_inventory(player_state) if _inventory_manager != null else null
	var total_weight = inventory.get_total_weight_kg() if inventory != null else 0.0
	var max_weight = inventory.max_total_weight_kg if inventory != null else 0.0
	sections.append({
		"id": &"road_surface",
		"title": "Road Surface",
		"summary": "Some conditions live in the carried stake and camp setup, not only in the body itself.",
		"fields": [
			{
				"id": &"water_surface",
				"label": "Water",
				"value": "Potable %d | Raw %d" % [int(player_state.camp_potable_water_units), int(player_state.camp_non_potable_water_units)],
				"notes": "Water here means what camp can presently work with for washing, cooking, and coffee."
			},
			{
				"id": &"carry_weight",
				"label": "Weight",
				"value": "%.2f / %.2f kg" % [total_weight, max_weight],
				"notes": "Carry weight is not just storage. It is road drag, fatigue burden, and travel readiness."
			}
		]
	})
	return sections
