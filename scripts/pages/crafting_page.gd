class_name CraftingPage
extends RefCounted

const OverlayBuilderScript := preload("res://scripts/front_end/adapters/overlay_builder.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const ROUTE_HOBOCRAFT := &"hobocraft"
const ROUTE_COOKING := &"cooking"

var _overlay_builder = OverlayBuilderScript.new()
var _game_state_manager = null
var _data_manager = null
var _time_manager = null
var _stats_manager = null
var _ui_manager = null
var _show_status := Callable()

var _panel: PanelContainer = null
var _hobocraft_panel: PanelContainer = null
var _cooking_panel: PanelContainer = null
var _hobocraft_recipe_list: VBoxContainer = null
var _hobocraft_detail_root: VBoxContainer = null
var _cooking_recipe_list: VBoxContainer = null
var _cooking_detail_root: VBoxContainer = null
var _cooking_filter_button: Button = null
var _cooking_prep_summary: Label = null
var _build_fire_button: Button = null
var _tend_fire_button: Button = null
var _gather_kindling_button: Button = null
var _brew_camp_coffee_button: Button = null

var _current_route: StringName = ROUTE_HOBOCRAFT
var _selected_hobocraft_recipe_id: StringName = &""
var _selected_cooking_recipe_id: StringName = &""
var _show_only_makeable_cooking := false


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_game_state_manager = deps.get("game_state_manager", null)
	_data_manager = deps.get("data_manager", null)
	_time_manager = deps.get("time_manager", null)
	_stats_manager = deps.get("stats_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_show_status = deps.get("show_status", Callable())
	_overlay_builder = deps.get("overlay_builder", _overlay_builder)
	_build_panels(deps.get("page_host", null))
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_route(route_name: StringName) -> void:
	if route_name == ROUTE_HOBOCRAFT or route_name == ROUTE_COOKING:
		_current_route = route_name
	_apply_visibility(true)
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_visible(visible: bool) -> void:
	_apply_visibility(visible)


func refresh_from_state(player_state) -> void:
	if player_state == null:
		return
	_refresh_hobocraft_recipes(player_state)
	_refresh_cooking_panel(player_state)


func handle_input(event: InputEvent) -> bool:
	if _panel == null or not _panel.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		if _ui_manager != null:
			_ui_manager.switch_to(&"travel_ui")
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


func _build_panels(page_host) -> void:
	if page_host == null:
		return
	_panel = PanelContainer.new()
	_panel.name = "CraftingPagePanel"
	_panel.visible = false
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.add_child(_panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(root)

	_hobocraft_panel = _build_hobocraft_page()
	_cooking_panel = _build_cooking_page()
	root.add_child(_hobocraft_panel)
	root.add_child(_cooking_panel)


func _build_hobocraft_page() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "HobocraftPage"
	panel.visible = false
	var root = VBoxContainer.new()
	root.name = "PageRoot"
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	_add_title(root, "Hobocraft", "Small camp makes: practical, material-bound, and fed by store goods or salvage.")
	root.add_child(_make_back_button())
	var layout = HBoxContainer.new()
	layout.name = "HobocraftLayout"
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)
	var list_panel = PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(280.0, 0.0)
	layout.add_child(list_panel)
	_hobocraft_recipe_list = VBoxContainer.new()
	_hobocraft_recipe_list.name = "HobocraftRecipeList"
	_hobocraft_recipe_list.add_theme_constant_override("separation", 8)
	list_panel.add_child(_hobocraft_recipe_list)
	var detail_panel = PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(detail_panel)
	_hobocraft_detail_root = VBoxContainer.new()
	_hobocraft_detail_root.name = "HobocraftDetail"
	_hobocraft_detail_root.add_theme_constant_override("separation", 8)
	detail_panel.add_child(_hobocraft_detail_root)
	return panel


func _build_cooking_page() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "CookingPage"
	panel.visible = false
	var root = VBoxContainer.new()
	root.name = "PageRoot"
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	_add_title(root, "Cooking", "Camp food and coffee trade time and setup for a steadier stake.")
	root.add_child(_make_back_button())
	_cooking_prep_summary = Label.new()
	_cooking_prep_summary.name = "CookingPrepSummary"
	_cooking_prep_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_cooking_prep_summary)
	_build_fire_button = Button.new()
	_build_fire_button.pressed.connect(Callable(self, "_on_action_pressed").bind(SurvivalLoopRulesScript.ACTION_BUILD_FIRE))
	root.add_child(_build_fire_button)
	_tend_fire_button = Button.new()
	_tend_fire_button.pressed.connect(Callable(self, "_on_action_pressed").bind(SurvivalLoopRulesScript.ACTION_TEND_FIRE))
	root.add_child(_tend_fire_button)
	_gather_kindling_button = Button.new()
	_gather_kindling_button.pressed.connect(Callable(self, "_on_action_pressed").bind(SurvivalLoopRulesScript.ACTION_GATHER_KINDLING))
	root.add_child(_gather_kindling_button)
	_brew_camp_coffee_button = Button.new()
	_brew_camp_coffee_button.pressed.connect(Callable(self, "_on_action_pressed").bind(SurvivalLoopRulesScript.ACTION_BREW_CAMP_COFFEE))
	root.add_child(_brew_camp_coffee_button)
	_cooking_filter_button = Button.new()
	_cooking_filter_button.toggle_mode = true
	_cooking_filter_button.pressed.connect(Callable(self, "_on_cooking_filter_pressed"))
	root.add_child(_cooking_filter_button)
	var layout = HBoxContainer.new()
	layout.name = "CookingLayout"
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)
	var list_panel = PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(280.0, 0.0)
	layout.add_child(list_panel)
	_cooking_recipe_list = VBoxContainer.new()
	_cooking_recipe_list.name = "CookingRecipeList"
	_cooking_recipe_list.add_theme_constant_override("separation", 8)
	list_panel.add_child(_cooking_recipe_list)
	var detail_panel = PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(detail_panel)
	_cooking_detail_root = VBoxContainer.new()
	_cooking_detail_root.name = "CookingDetail"
	_cooking_detail_root.add_theme_constant_override("separation", 8)
	detail_panel.add_child(_cooking_detail_root)
	return panel


func _apply_visibility(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible
	if _hobocraft_panel != null:
		_hobocraft_panel.visible = visible and _current_route == ROUTE_HOBOCRAFT
	if _cooking_panel != null:
		_cooking_panel.visible = visible and _current_route == ROUTE_COOKING


func _refresh_hobocraft_recipes(player_state) -> void:
	_clear_children(_hobocraft_recipe_list)
	_clear_children(_hobocraft_detail_root)
	var recipes = SurvivalLoopRulesScript.get_hobocraft_recipes()
	if recipes.is_empty():
		_hobocraft_recipe_list.add_child(_wrapped_label("No known camp makes are available."))
		_hobocraft_detail_root.add_child(_wrapped_label("Hobocraft needs a known make before the detail pane can show materials."))
		return
	if _selected_hobocraft_recipe_id == &"" or _find_recipe(recipes, _selected_hobocraft_recipe_id).is_empty():
		_selected_hobocraft_recipe_id = StringName(recipes[0].get("recipe_id", &""))
	var current_category := ""
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var category = _format_recipe_category(recipe)
		if category != current_category:
			current_category = category
			_hobocraft_recipe_list.add_child(_build_category_label(current_category))
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
			{"source": "crafting.hobocraft", "recipe_id": recipe_id}
		)
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 62.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_recipe_button_text(recipe, availability)
		button.tooltip_text = String(recipe.get("summary", ""))
		button.pressed.connect(Callable(self, "_on_hobocraft_recipe_selected").bind(recipe_id))
		_hobocraft_recipe_list.add_child(button)
	_refresh_hobocraft_detail(_find_recipe(recipes, _selected_hobocraft_recipe_id), player_state)


func _refresh_hobocraft_detail(recipe: Dictionary, player_state) -> void:
	_clear_children(_hobocraft_detail_root)
	if recipe.is_empty():
		_hobocraft_detail_root.add_child(_wrapped_label("Select a recipe to see its requirements."))
		return
	var recipe_id = StringName(recipe.get("recipe_id", &""))
	var availability = _game_state_manager.get_loop_action_availability_with_context(
		SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
		{"source": "crafting.hobocraft.detail", "recipe_id": recipe_id}
	)
	_hobocraft_detail_root.add_child(build_recipe_workspace(
		recipe,
		player_state,
		availability,
		false,
		Callable(self, "_on_craft_recipe_pressed").bind(recipe_id)
	))


func _refresh_cooking_panel(player_state) -> void:
	var config = _get_loop_config()
	_cooking_prep_summary.text = "Fire first: %s. Kindling prepared: %s. Cooking follows once heat, water, and tools are in hand." % [
		player_state.get_camp_fire_status_label(),
		"yes" if bool(player_state.camp_kindling_prepared) else "no"
	]
	_clear_children(_cooking_recipe_list)
	_clear_children(_cooking_detail_root)
	_cooking_filter_button.button_pressed = _show_only_makeable_cooking
	_cooking_filter_button.text = "Showing Makeable Now" if _show_only_makeable_cooking else "Showing All Known"
	_build_fire_button.text = "Build Fire"
	_tend_fire_button.text = "Tend Fire"
	_gather_kindling_button.text = "Gather Kindling"
	_brew_camp_coffee_button.text = "Brew Camp Coffee"
	var recipes = SurvivalLoopRulesScript.get_cooking_recipes()
	if recipes.is_empty():
		_cooking_recipe_list.add_child(_wrapped_label("No known cooking actions are available."))
		_cooking_detail_root.add_child(_wrapped_label("Cooking needs known actions before the detail pane can show materials."))
		return
	var visible_recipes: Array = []
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			{"source": "crafting.cooking", "recipe_id": recipe_id}
		)
		if _show_only_makeable_cooking and not bool(availability.get("enabled", false)):
			continue
		visible_recipes.append(recipe)
	if visible_recipes.is_empty():
		_cooking_recipe_list.add_child(_wrapped_label("No cooking actions are makeable yet. Build a fire, boil water, or gather the right tinwork."))
		_cooking_detail_root.add_child(_wrapped_label("Cooking needs camp, time, and materials. The filter may be hiding known recipes that are not makeable right now."))
		return
	if _selected_cooking_recipe_id == &"" or _find_recipe(visible_recipes, _selected_cooking_recipe_id).is_empty():
		_selected_cooking_recipe_id = StringName(visible_recipes[0].get("recipe_id", &""))
	var current_category := ""
	for recipe in visible_recipes:
		var category = _format_recipe_category(recipe)
		if category != current_category:
			current_category = category
			_cooking_recipe_list.add_child(_build_category_label(current_category))
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			{"source": "crafting.cooking.detail", "recipe_id": recipe_id}
		)
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 66.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_recipe_button_text(recipe, availability)
		button.tooltip_text = String(recipe.get("summary", ""))
		button.pressed.connect(Callable(self, "_on_cooking_recipe_selected").bind(recipe_id))
		_cooking_recipe_list.add_child(button)
	_refresh_cooking_detail(_find_recipe(visible_recipes, _selected_cooking_recipe_id), player_state)


func _refresh_cooking_detail(recipe: Dictionary, player_state) -> void:
	_clear_children(_cooking_detail_root)
	if recipe.is_empty():
		_cooking_detail_root.add_child(_wrapped_label("Select a cooking action to see its needs and result."))
		return
	var recipe_id = StringName(recipe.get("recipe_id", &""))
	var title = Label.new()
	title.text = String(recipe.get("display_name", "Cooking"))
	title.add_theme_font_size_override("font_size", 22)
	_cooking_detail_root.add_child(title)
	var availability = _game_state_manager.get_loop_action_availability_with_context(
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		{"source": "crafting.cooking.recipe", "recipe_id": recipe_id}
	)
	_cooking_detail_root.add_child(build_recipe_workspace(
		recipe,
		player_state,
		availability,
		true,
		Callable(self, "_on_cooking_recipe_pressed").bind(recipe_id)
	))


func _build_recipe_note_panel(note_model: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.name = "RecipeInventoryNote"
	panel.custom_minimum_size = Vector2(270.0, 0.0)
	panel.add_theme_stylebox_override("panel", _make_recipe_section_style(Color("0f0f10"), Color("f0ebe0"), 2, 12, 14.0))
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var title = Label.new()
	title.text = String(note_model.get("title", "Camp Note"))
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)
	var status = Label.new()
	status.text = String(note_model.get("status", "Missing materials"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(status)
	for line in note_model.get("lines", PackedStringArray()):
		var label = Label.new()
		label.text = String(line)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(label)
	return panel


func _build_recipe_card_panel(card_model: Dictionary, action_pressed: Callable) -> Control:
	var panel = PanelContainer.new()
	panel.name = "RecipeIndexCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_recipe_section_style(Color("efe2c8"), Color("8e7452"), 2, 10, 16.0))
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
	title.add_theme_font_size_override("font_size", 24)
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
	root.add_child(action_button)
	return panel


func _build_recipe_card_section(title_text: String, body_text: String, font_color: Color) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 16)
	section.add_child(title)
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = font_color
	section.add_child(body)
	return section


func _on_action_pressed(action_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(action_id), {"source": "crafting.action"})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_hobocraft_recipe_selected(recipe_id: StringName) -> void:
	_selected_hobocraft_recipe_id = recipe_id
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_cooking_filter_pressed() -> void:
	_show_only_makeable_cooking = _cooking_filter_button.button_pressed
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_cooking_recipe_selected(recipe_id: StringName) -> void:
	_selected_cooking_recipe_id = recipe_id
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_craft_recipe_pressed(recipe_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE), {
		"source": "crafting.recipe",
		"recipe_id": recipe_id
	})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _on_cooking_recipe_pressed(recipe_id: StringName) -> void:
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_COOK_RECIPE), {
		"source": "cooking.recipe",
		"recipe_id": recipe_id
	})
	if not _show_status.is_null():
		_show_status.call(String(result.get("message", "No result.")))


func _make_back_button() -> Button:
	var button = Button.new()
	button.text = "Back to Routes"
	button.custom_minimum_size = Vector2(180.0, 40.0)
	button.pressed.connect(func() -> void:
		if _ui_manager != null:
			_ui_manager.switch_to(&"travel_ui")
	)
	return button


func _add_title(parent: VBoxContainer, title_text: String, body_text: String) -> void:
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	parent.add_child(title)
	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(body)


func _build_category_label(category: String) -> Label:
	var label = Label.new()
	label.text = category
	label.add_theme_font_size_override("font_size", 18)
	return label


func _wrapped_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _format_recipe_button_text(recipe: Dictionary, availability: Dictionary) -> String:
	var status = "ready" if bool(availability.get("enabled", false)) else String(availability.get("reason", "missing materials"))
	return "%s\n%s\n%s" % [
		String(recipe.get("display_name", "Recipe")),
		_format_recipe_inputs(recipe),
		status
	]


func _format_recipe_category(recipe: Dictionary) -> String:
	var category = String(recipe.get("category", "")).strip_edges()
	if category == "":
		return "Camp Utility"
	return category


func _format_recipe_inputs(recipe: Dictionary) -> String:
	return _overlay_builder.format_recipe_inputs(recipe, _get_overlay_builder_deps())


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


func _make_recipe_section_style(bg: Color, border: Color, border_width: int, corner_radius: int, margin: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _get_loop_config():
	return _data_manager.get_loop_config() if _data_manager != null else null


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes) if _time_manager != null else "%d min" % minutes
