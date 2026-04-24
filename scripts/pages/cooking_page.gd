class_name CookingPage
extends RefCounted

const OverlayBuilderScript := preload("res://scripts/front_end/adapters/overlay_builder.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")
const ActionButtonWidgetScript := preload("res://scripts/ui/widgets/action_button_widget.gd")
const ActionCardWidgetScript := preload("res://scripts/ui/widgets/action_card_widget.gd")
const BasePanelWidgetScript := preload("res://scripts/ui/widgets/base_panel_widget.gd")
const DataPanelWidgetScript := preload("res://scripts/ui/widgets/data_panel_widget.gd")
const DetailPanelWidgetScript := preload("res://scripts/ui/widgets/detail_panel_widget.gd")
const VerticalListWidgetScript := preload("res://scripts/ui/widgets/vertical_list_widget.gd")

const ROUTE_COOKING := &"cooking"

var _overlay_builder = OverlayBuilderScript.new()
var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _stats_manager = null
var _ui_manager = null
var _show_status := Callable()

var _panel: PanelContainer = null
var _context_widget = null
var _prep_actions_widget = null
var _recipe_list_widget = null
var _detail_widget = null
var _back_button = null
var _filter_toggle: CheckButton = null

var _return_route: StringName = &"camp"
var _selected_recipe_id: StringName = &""
var _show_only_makeable := false


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_game_state_manager = deps.get("game_state_manager", null)
	_data_manager = deps.get("data_manager", null)
	_time_manager = deps.get("time_manager", null)
	_stats_manager = deps.get("stats_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_show_status = deps.get("show_status", Callable())
	_overlay_builder = deps.get("overlay_builder", _overlay_builder)
	_build_panel(deps.get("page_host", null))
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_context(context: Dictionary) -> void:
	_return_route = StringName(context.get("return_route", _return_route))


func set_route(route_name: StringName) -> void:
	if route_name == ROUTE_COOKING:
		set_visible(true)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible


func refresh_from_state(player_state) -> void:
	if player_state == null or _context_widget == null:
		return
	var config = _get_loop_config()
	_context_widget.set_data([
		"Heat source: %s" % player_state.get_camp_fire_status_label(),
		"Water ready %d | raw %d | kindling %s" % [
			int(player_state.camp_potable_water_units),
			int(player_state.camp_non_potable_water_units),
			"yes" if bool(player_state.camp_kindling_prepared) else "no"
		],
		"Cooking here is camp work done by hand: fire, tins, and whatever the pack can spare."
	])
	_refresh_prep_actions(player_state, config)
	_refresh_recipe_cards(player_state)


func handle_input(event: InputEvent) -> bool:
	if _panel == null or not _panel.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		return true
	return false


func build_recipe_inventory_note_lines(recipe: Dictionary, player_state, is_cooking: bool) -> PackedStringArray:
	return _overlay_builder.build_recipe_inventory_note_lines(recipe, player_state, _get_loop_config(), is_cooking, _get_overlay_builder_deps())


func build_overlay_recipe_workspace_data(recipe: Dictionary, player_state, action_id: StringName, context_source: String, action_label_format: String, is_cooking: bool, utility_sections: Array = []) -> Dictionary:
	return _overlay_builder.build_overlay_recipe_workspace_data(
		recipe,
		player_state,
		_get_loop_config(),
		action_id,
		context_source,
		action_label_format,
		is_cooking,
		_get_overlay_builder_deps(),
		utility_sections
	)


func build_recipe_workspace(recipe: Dictionary, player_state, availability: Dictionary, is_cooking: bool, action_pressed: Callable) -> Control:
	var workspace = HBoxContainer.new()
	workspace.name = "RecipeWorkspace"
	workspace.add_theme_constant_override("separation", 14)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var workspace_model = _overlay_builder.build_recipe_workspace_model(
		recipe,
		player_state,
		_get_loop_config(),
		availability,
		is_cooking,
		_get_overlay_builder_deps()
	)
	workspace.add_child(_build_recipe_note_panel(workspace_model.get("note", {})))
	workspace.add_child(_build_recipe_card_panel(workspace_model.get("card", {}), action_pressed))
	return workspace


func _build_panel(page_host) -> void:
	if page_host == null:
		return
	_panel = PanelContainer.new()
	_panel.name = "CookingPagePanel"
	_panel.visible = false
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(_panel, "panel")
	page_host.add_child(_panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(root)

	var title = Label.new()
	title.text = "Cooking"
	PageUIThemeScript.style_header_label(title, true)
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Fire, water, and a tin in hand. Meals here are set to heat, watched, and worked through by hand."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(subtitle)
	root.add_child(subtitle)

	_back_button = ActionButtonWidgetScript.new()
	_back_button.set_action_id(&"back")
	_back_button.set_label("Back to World")
	_back_button.set_accent(false)
	_back_button.pressed.connect(Callable(self, "_on_nav_pressed"))
	root.add_child(_back_button)

	_context_widget = DataPanelWidgetScript.new()
	_context_widget.set_title("Heat / Water", true)
	_context_widget.set_variant("alt")
	root.add_child(_context_widget)

	_prep_actions_widget = BasePanelWidgetScript.new()
	_prep_actions_widget.set_title("Camp Work")
	_prep_actions_widget.set_variant("dark")
	root.add_child(_prep_actions_widget)

	_filter_toggle = CheckButton.new()
	_filter_toggle.text = "Show only what can be set to heat now"
	_filter_toggle.toggled.connect(Callable(self, "_on_filter_toggled"))
	_prep_actions_widget.get_content_root().add_child(_filter_toggle)

	var layout = HBoxContainer.new()
	layout.name = "CookingLayout"
	layout.add_theme_constant_override("separation", 14)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(layout)

	_recipe_list_widget = VerticalListWidgetScript.new()
	_recipe_list_widget.set_title("Fireside Work")
	_recipe_list_widget.custom_minimum_size = Vector2(320.0, 0.0)
	_recipe_list_widget.set_variant("dark")
	layout.add_child(_recipe_list_widget)

	_detail_widget = DetailPanelWidgetScript.new()
	_detail_widget.set_title("Meal Detail", true)
	_detail_widget.set_variant("highlight")
	layout.add_child(_detail_widget)


func _refresh_prep_actions(player_state, config) -> void:
	var content_root = _prep_actions_widget.get_content_root()
	for child in content_root.get_children():
		if child == _filter_toggle:
			continue
		content_root.remove_child(child)
		child.queue_free()

	_filter_toggle.button_pressed = _show_only_makeable
	for action_data in [
		{
			"action_id": SurvivalLoopRulesScript.ACTION_BUILD_FIRE,
			"label": "Build Fire",
			"tooltip": "Lay a fire so water and food can be worked over heat."
		},
		{
			"action_id": SurvivalLoopRulesScript.ACTION_TEND_FIRE,
			"label": "Tend Fire",
			"tooltip": "Keep the heat steady enough for cooking and warmth."
		},
		{
			"action_id": SurvivalLoopRulesScript.ACTION_GATHER_KINDLING,
			"label": "Gather Kindling",
			"tooltip": "Prepare the small dry stuff before the fire goes flat."
		},
		{
			"action_id": SurvivalLoopRulesScript.ACTION_BREW_CAMP_COFFEE,
			"label": "Brew Camp Coffee",
			"tooltip": "Turn grounds, water, and tin into something hot enough to steady the body."
		}
	]:
		var availability = _game_state_manager.get_loop_action_availability(action_data.action_id)
		var button = ActionButtonWidgetScript.new()
		button.set_action_id(action_data.action_id)
		button.set_label("%s\n%s" % [
			action_data.label,
			"ready" if bool(availability.get("enabled", false)) else String(availability.get("reason", "unavailable"))
		])
		button.set_action_tooltip(String(action_data.tooltip))
		button.pressed.connect(Callable(self, "_on_prep_action_pressed"))
		content_root.add_child(button)


func _refresh_recipe_cards(player_state) -> void:
	_recipe_list_widget.clear_items()
	var recipes = _data_manager.get_recipes_by_category("cooking") if _data_manager != null else []
	var visible_recipes: Array = []
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			{"source": "cooking.page", "recipe_id": recipe_id}
		)
		if _show_only_makeable and not bool(availability.get("enabled", false)):
			continue
		visible_recipes.append(recipe)
		var card = ActionCardWidgetScript.new()
		card.set_data({
			"action_id": recipe_id,
			"title": String(recipe.get("display_name", "Recipe")),
			"description": String(recipe.get("summary", "")),
			"requirements": [
				"Needs: %s" % _format_cooking_needs(recipe),
				"Result: %s" % _format_cooking_result(recipe)
			],
			"status": "Ready to set over the fire." if bool(availability.get("enabled", false)) else "Held up: %s" % String(availability.get("reason", "missing setup")),
			"enabled": true,
			"action_label": "Review Meal",
			"tooltip_text": String(recipe.get("summary", ""))
		})
		card.selected.connect(Callable(self, "_on_recipe_selected"))
		_recipe_list_widget.add_item(card)

	if visible_recipes.is_empty():
		var empty_widget = DataPanelWidgetScript.new()
		empty_widget.set_title("Nothing Ready")
		empty_widget.set_data("Nothing is ready to set over the fire. Heat, water, or the right tinwork may still be missing.")
		_recipe_list_widget.add_item(empty_widget)
		_show_recipe_detail({}, player_state)
		return

	if _selected_recipe_id == &"" or _find_recipe(visible_recipes, _selected_recipe_id).is_empty():
		_selected_recipe_id = StringName(visible_recipes[0].get("recipe_id", &""))

	_show_recipe_detail(_find_recipe(visible_recipes, _selected_recipe_id), player_state)


func _show_recipe_detail(recipe: Dictionary, player_state) -> void:
	_detail_widget.clear_detail_content()
	if recipe.is_empty():
		_detail_widget.set_detail({
			"title": "No Recipe Selected",
			"summary": "Pick a camp meal to review what it needs and what it yields.",
			"blocks": []
		})
		return
	var recipe_id = StringName(recipe.get("recipe_id", &""))
	var availability = _game_state_manager.get_loop_action_availability_with_context(
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		{"source": "cooking.recipe.detail", "recipe_id": recipe_id}
	)
	_detail_widget.set_detail({
		"title": String(recipe.get("display_name", "Cooking")),
		"summary": String(recipe.get("summary", "")),
		"blocks": [
			"Needs: %s" % _format_cooking_needs(recipe),
			"Result: %s" % _format_cooking_result(recipe)
		]
	})
	_detail_widget.set_detail_content(build_recipe_workspace(
		recipe,
		player_state,
		availability,
		true,
		Callable(self, "_on_cooking_recipe_pressed").bind(recipe_id)
	))


func _build_recipe_note_panel(note_model: Dictionary) -> Control:
	var widget = DataPanelWidgetScript.new()
	widget.name = "RecipeInventoryNote"
	widget.custom_minimum_size = Vector2(270.0, 0.0)
	widget.set_title(String(note_model.get("title", "Camp Note")), true)
	widget.set_variant("dark")
	var lines: PackedStringArray = note_model.get("lines", PackedStringArray())
	var blocks: Array[String] = [String(note_model.get("status", "Missing setup"))]
	for line in lines:
		blocks.append(String(line))
	widget.set_data(blocks)
	return widget


func _build_recipe_card_panel(card_model: Dictionary, action_pressed: Callable) -> Control:
	var panel = PanelContainer.new()
	panel.name = "RecipeIndexCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(panel, "highlight")
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(56.0, 56.0)
	header.add_child(badge)
	var badge_label = Label.new()
	badge_label.text = String(card_model.get("badge_text", "CARD"))
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 16)
	badge.add_child(badge_label)
	var title_column = VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_column)
	var title = Label.new()
	title.text = String(card_model.get("title", "Recipe"))
	PageUIThemeScript.style_header_label(title, true)
	title_column.add_child(title)
	var subtitle = Label.new()
	subtitle.text = String(card_model.get("subtitle", "written down for camp use"))
	title_column.add_child(subtitle)
	var summary = Label.new()
	summary.text = String(card_model.get("summary", ""))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(summary)
	for section_model in card_model.get("sections", []):
		if section_model is Dictionary:
			root.add_child(_build_recipe_card_section(
				String(section_model.get("title", "")),
				String(section_model.get("body", "")),
				section_model.get("font_color", Color("221c16"))
			))
	var action_button = Button.new()
	action_button.custom_minimum_size = Vector2(0.0, 54.0)
	action_button.text = String(card_model.get("action_label", "Act"))
	action_button.disabled = bool(card_model.get("action_disabled", false))
	action_button.tooltip_text = String(card_model.get("action_tooltip", ""))
	action_button.pressed.connect(action_pressed)
	PageUIThemeScript.style_button(action_button, true)
	root.add_child(action_button)
	return panel


func _build_recipe_card_section(title_text: String, body_text: String, font_color: Color) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	var title = Label.new()
	title.text = title_text
	PageUIThemeScript.style_section_label(title)
	section.add_child(title)
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = font_color
	section.add_child(body)
	return section


func _on_nav_pressed(_action_id: StringName) -> void:
	_go_back()


func _on_prep_action_pressed(action_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(action_id), {"source": "cooking.prep"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_filter_toggled(button_pressed: bool) -> void:
	_show_only_makeable = button_pressed
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_recipe_selected(recipe_id: StringName) -> void:
	_selected_recipe_id = recipe_id
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_cooking_recipe_pressed(recipe_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_COOK_RECIPE), {
		"source": "cooking.recipe",
		"recipe_id": recipe_id
	})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _format_recipe_inputs(recipe: Dictionary) -> String:
	return _overlay_builder.format_recipe_inputs(recipe, _get_overlay_builder_deps())


func _format_cooking_needs(recipe: Dictionary) -> String:
	var needs_text = String(recipe.get("inputs_text", "")).strip_edges()
	if needs_text != "":
		return needs_text
	return _format_recipe_inputs(recipe)


func _format_cooking_result(recipe: Dictionary) -> String:
	var result_text = String(recipe.get("effects_text", "")).strip_edges()
	if result_text != "":
		return result_text
	return "prepared food or drink"


func _format_warmth_breakdown(breakdown: Dictionary) -> String:
	if breakdown.is_empty():
		return "not available"
	var parts: Array[String] = []
	for entry in breakdown.get("contributors", []):
		if entry is Dictionary:
			parts.append("%s %+d" % [String(entry.get("label", "warmth")), int(entry.get("value", 0))])
	parts.append("net %+d" % int(breakdown.get("net_warmth_change", 0)))
	return ", ".join(parts)


func _get_overlay_builder_deps() -> Dictionary:
	return {
		"build_action_context": Callable(self, "_build_action_context"),
		"format_duration": Callable(self, "_format_duration"),
		"format_warmth_breakdown": Callable(self, "_format_warmth_breakdown"),
		"get_action_availability": Callable(self, "_get_overlay_action_availability"),
		"get_item_catalog": Callable(self, "_get_overlay_item_catalog"),
		"get_item_definition": Callable(self, "_get_item_definition"),
		"get_stamina_value": Callable(self, "_get_stamina_value")
	}


func _build_action_context(source: String, values: Dictionary = {}) -> Dictionary:
	var context = values.duplicate(true)
	context["source"] = source
	context["selected_stack_index"] = int(context.get("stack_index", -1))
	return context


func _get_overlay_action_availability(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	if _game_state_manager == null:
		return {"enabled": false, "reason": "Action is unavailable."}
	if context.is_empty():
		return _game_state_manager.get_loop_action_availability(action_id)
	return _game_state_manager.get_loop_action_availability_with_context(action_id, context)


func _get_overlay_item_catalog():
	return _data_manager.get_item_catalog() if _data_manager != null else null


func _get_item_definition(item_id: StringName):
	return _data_manager.get_item_definition(item_id) if _data_manager != null else null


func _get_stamina_value(player_state) -> int:
	return _stats_manager.get_stamina(player_state) if _stats_manager != null else 0


func _find_recipe(recipes: Array, recipe_id: StringName) -> Dictionary:
	for recipe in recipes:
		if recipe is Dictionary and StringName(recipe.get("recipe_id", &"")) == recipe_id:
			return recipe
	return {}


func _get_loop_config():
	return _data_manager.get_loop_config() if _data_manager != null else null


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes


func _go_back() -> void:
	if _ui_manager != null:
		_ui_manager.open_page(_return_route)
