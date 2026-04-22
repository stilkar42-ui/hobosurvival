class_name OverlayBuilder
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")


func build_camp_contextual_overlay_models(player_state, config, ui_state: Dictionary, deps: Dictionary) -> Dictionary:
	if player_state == null or config == null:
		return {}
	return {
		&"cooking": _build_cooking_overlay_model(player_state, config, ui_state, deps),
		&"fire": _build_cooking_overlay_model(player_state, config, ui_state, deps),
		&"craft": _build_hobocraft_overlay_model(player_state, config, ui_state, deps),
		&"ready": _build_getting_ready_overlay_model(player_state, config, deps),
		&"rest": _build_rest_overlay_model(player_state, config, ui_state, deps)
	}


func build_overlay_recipe_workspace_data(recipe: Dictionary, player_state, config, action_id: StringName, context_source: String, action_label_format: String, is_cooking: bool, deps: Dictionary, utility_sections: Array = []) -> Dictionary:
	if recipe.is_empty():
		return {
			"card": {
				"badge_text": "NOTE",
				"title": "Recipe Card",
				"subtitle": "nothing selected",
				"summary": "Pick a recipe to review materials and outcome.",
				"sections": [],
				"action": {}
			},
			"utility_sections": utility_sections
		}

	var recipe_id := StringName(recipe.get("recipe_id", &""))
	var availability = _get_action_availability(deps, action_id, _build_action_context(deps, context_source, {"recipe_id": recipe_id}))
	var card_sections: Array = [
		{
			"title": "Held",
			"body": build_overlay_recipe_material_summary(recipe, player_state, config, is_cooking, deps)
		},
		{
			"title": "Needs",
			"body": format_recipe_inputs(recipe, deps)
		},
		{
			"title": "Status",
			"body": "Ready now" if bool(availability.get("enabled", false)) else String(availability.get("reason", "Missing materials"))
		},
		{
			"title": "Tradeoff",
			"body": build_recipe_tradeoff_text(recipe, config, is_cooking, deps)
		},
		{
			"title": "Result",
			"body": build_recipe_result_text(recipe, player_state, config, is_cooking, deps)
		}
	]
	return {
		"card": {
			"badge_text": get_recipe_badge_label(recipe, is_cooking),
			"title": String(recipe.get("display_name", "Recipe")),
			"subtitle": "written down for camp use",
			"summary": String(recipe.get("summary", "")),
			"sections": card_sections,
			"action": _build_camp_overlay_action_entry(
				action_label_format % String(recipe.get("display_name", "Recipe")),
				action_id,
				{"recipe_id": recipe_id},
				_build_overlay_tooltip(String(recipe.get("summary", "")), availability),
				context_source
			)
		},
		"utility_sections": utility_sections
	}


func build_recipe_inventory_note_lines(recipe: Dictionary, player_state, config, is_cooking: bool, deps: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Materials on hand:")
	var material_entries = _get_recipe_material_entries(recipe, player_state, config, is_cooking, deps)
	if material_entries.is_empty():
		lines.append("No counted materials for this note.")
	else:
		for entry in material_entries:
			lines.append(format_recipe_material_line(entry))

	var relevant_entries = _get_relevant_item_entries(recipe, player_state, is_cooking, deps)
	if not relevant_entries.is_empty():
		lines.append("")
		lines.append("Relevant kit already carried:")
		for entry in relevant_entries:
			lines.append("%s x%d" % [String(entry.get("label", "Item")), int(entry.get("count", 0))])

	if is_cooking and player_state != null and player_state.has_method("get_camp_fire_status_label"):
		lines.append("")
		lines.append("Camp fire: %s" % String(player_state.get_camp_fire_status_label()))

	return lines


func build_recipe_workspace_model(recipe: Dictionary, player_state, config, availability: Dictionary, is_cooking: bool, deps: Dictionary) -> Dictionary:
	return {
		"note": {
			"title": "Camp Note",
			"status": "Ready now" if bool(availability.get("enabled", false)) else String(availability.get("reason", "Missing materials")),
			"lines": build_recipe_inventory_note_lines(recipe, player_state, config, is_cooking, deps)
		},
		"card": {
			"badge_text": get_recipe_badge_label(recipe, is_cooking),
			"title": String(recipe.get("display_name", "Recipe")),
			"subtitle": "written down for camp use",
			"summary": String(recipe.get("summary", "")),
			"sections": [
				{
					"title": "Needs",
					"body": format_recipe_inputs(recipe, deps),
					"font_color": Color("221c16")
				},
				{
					"title": "Status",
					"body": "Ready now" if bool(availability.get("enabled", false)) else String(availability.get("reason", "Missing materials")),
					"font_color": Color("221c16")
				},
				{
					"title": "Tradeoff",
					"body": build_recipe_tradeoff_text(recipe, config, is_cooking, deps),
					"font_color": Color("221c16")
				},
				{
					"title": "Result",
					"body": build_recipe_result_text(recipe, player_state, config, is_cooking, deps),
					"font_color": Color("221c16")
				}
			],
			"action_label": ("Cook " if is_cooking else "Craft ") + String(recipe.get("display_name", "Recipe")),
			"action_disabled": not bool(availability.get("enabled", false)),
			"action_tooltip": _build_overlay_tooltip(String(recipe.get("summary", "")), availability),
			"output_item_id": StringName(recipe.get("output_item_id", &""))
		}
	}


func build_overlay_recipe_material_summary(recipe: Dictionary, player_state, config, is_cooking: bool, deps: Dictionary) -> String:
	var lines := PackedStringArray()
	for entry in _get_recipe_material_entries(recipe, player_state, config, is_cooking, deps):
		lines.append("%s: %d held (needs %d)" % [
			String(entry.get("label", "Material")),
			int(entry.get("have", 0)),
			int(entry.get("need", 1))
		])
	return "\n".join(lines) if not lines.is_empty() else "No counted ingredients for this card."


func build_recipe_tradeoff_text(_recipe: Dictionary, config, is_cooking: bool, deps: Dictionary) -> String:
	if is_cooking:
		return "Costs camp time, depends on heat, and wears improvised cooking tools down."
	if config == null:
		return "Consumes listed materials and turns them into one hard-used camp tool."
	return "Costs %s, consumes listed materials, and turns them into one more useful camp make." % _format_duration(deps, int(config.hobocraft_action_minutes))


func build_recipe_result_text(recipe: Dictionary, player_state, config, is_cooking: bool, deps: Dictionary) -> String:
	if is_cooking:
		var result_text = String(recipe.get("effects_text", "")).strip_edges()
		if result_text == "":
			result_text = "Changes camp condition."
		if player_state != null:
			var warmth_breakdown = SurvivalLoopRulesScript.get_sleep_warmth_breakdown(player_state, config)
			result_text += "\nSleep warmth now: %s" % _format_warmth_breakdown(deps, warmth_breakdown)
		return result_text
	var output_item_id := StringName(recipe.get("output_item_id", &""))
	var output_item = _get_item_definition(deps, output_item_id)
	return "%s x%d" % [
		output_item.display_name if output_item != null else String(output_item_id).replace("_", " "),
		int(recipe.get("output_quantity", 1))
	]


func get_recipe_badge_label(recipe: Dictionary, is_cooking: bool) -> String:
	if is_cooking:
		var category = String(recipe.get("category", "")).to_upper()
		if category.contains("WATER"):
			return "TIN"
		if category.contains("DRINK"):
			return "CUP"
		if category.contains("HOT"):
			return "PAN"
		return "COOK"
	var craft_category = String(recipe.get("category", "")).to_upper()
	if craft_category.contains("FIRE"):
		return "HEAT"
	if craft_category.contains("REPAIR"):
		return "MEND"
	return "MAKE"


func format_recipe_material_line(entry: Dictionary) -> String:
	return "%s: %d / %d" % [
		String(entry.get("label", "Material")),
		int(entry.get("have", 0)),
		int(entry.get("need", 1))
	]


func format_recipe_inputs(recipe: Dictionary, deps: Dictionary) -> String:
	if String(recipe.get("inputs_text", "")).strip_edges() != "":
		return String(recipe.get("inputs_text", ""))
	var parts: Array[String] = []
	for input in recipe.get("inputs", []):
		if not (input is Dictionary):
			continue
		var item_id := StringName(input.get("item_id", &""))
		var item = _get_item_definition(deps, item_id)
		var item_name = item.display_name if item != null else String(item_id).replace("_", " ")
		parts.append("%s x%d" % [item_name, int(input.get("quantity", 1))])
	if parts.is_empty():
		return "No material inputs."
	return " + ".join(parts)


func _build_cooking_overlay_model(player_state, config, ui_state: Dictionary, deps: Dictionary) -> Dictionary:
	var fire_action = SurvivalLoopRulesScript.ACTION_BUILD_FIRE if int(player_state.camp_fire_level) <= 0 else SurvivalLoopRulesScript.ACTION_TEND_FIRE
	var fire_minutes = config.build_fire_minutes if fire_action == SurvivalLoopRulesScript.ACTION_BUILD_FIRE else config.tend_fire_minutes
	var fire_actions := [
		_build_camp_overlay_action_entry(
			"Tend Fire\n%s" % _format_duration(deps, fire_minutes) if fire_action == SurvivalLoopRulesScript.ACTION_TEND_FIRE else "Make Fire\n%s" % _format_duration(deps, fire_minutes),
			fire_action,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, fire_action, {}))
		),
		_build_camp_overlay_action_entry(
			"Gather Kindling\n%s" % _format_duration(deps, config.gather_kindling_minutes),
			SurvivalLoopRulesScript.ACTION_GATHER_KINDLING,
			{},
			_build_overlay_tooltip("Prepare dry kindling for fire and cooking work.", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_GATHER_KINDLING, {}))
		)
	]
	var recipes = SurvivalLoopRulesScript.get_cooking_recipes()
	var selected_recipe_id := StringName(ui_state.get("selected_cooking_recipe_id", &""))
	var expanded_categories: Dictionary = ui_state.get("expanded_cooking_overlay_categories", {})
	var browser_entries: Array = []
	var current_category := ""
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var category = _format_recipe_category(recipe)
		if category != current_category:
			current_category = category
			var expanded = bool(expanded_categories.get(current_category, expanded_categories.is_empty()))
			browser_entries.append(_build_overlay_recipe_category_entry(&"cooking", current_category, expanded))
			if not expanded:
				continue
		var recipe_id := StringName(recipe.get("recipe_id", &""))
		var availability = _get_action_availability(
			deps,
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			_build_action_context(deps, "camp.overlay.cooking", {"recipe_id": recipe_id})
		)
		browser_entries.append(_build_overlay_recipe_select_entry(
			&"cooking",
			recipe_id,
			"%s\n%s" % [
				String(recipe.get("display_name", "Recipe")),
				"ready" if bool(availability.get("enabled", false)) else String(availability.get("reason", "missing materials"))
			],
			_build_overlay_tooltip(String(recipe.get("summary", "")), availability),
			recipe_id == selected_recipe_id
		))
	return {
		"title": "Fire / Cooking",
		"subtitle": "coals, kettle, tins, and camp heat",
		"theme": {
			"badge_text": "FIRE",
			"title_bar_color": "47301f",
			"badge_color": "6a4729",
			"body_color": "1f1712",
			"section_color": "2a1f19",
			"button_color": "39291e",
			"button_hover_color": "4a3323",
			"button_pressed_color": "573b28",
			"border_color": "9a7243",
			"accent_color": "efbf73"
		},
		"summary": "Fire %s. Kindling prepared: %s. Potable water %d, non-potable %d." % [
			player_state.get_camp_fire_status_label(),
			"yes" if bool(player_state.camp_kindling_prepared) else "no",
			int(player_state.camp_potable_water_units),
			int(player_state.camp_non_potable_water_units)
		],
		"layout": "recipe_browser",
		"browser": {
			"list_title": "Known Cooking",
			"entries": browser_entries,
			"detail": {
				"title": "Camp Cooking",
				"summary": "A good camp fire is heat, safer water, and tomorrow's working body.",
				"workspace": build_overlay_recipe_workspace_data(
					_find_recipe(recipes, selected_recipe_id),
					player_state,
					config,
					SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
					"camp.overlay.cooking",
					"Cook %s",
					true,
					deps,
					[
						{
							"title": "Fire Work",
							"summary": "Heat and prepared kindling decide whether camp cooking and sleep support hold together.",
							"actions": fire_actions
						}
					]
				)
			}
		}
	}


func _build_hobocraft_overlay_model(player_state, config, ui_state: Dictionary, deps: Dictionary) -> Dictionary:
	var recipes = SurvivalLoopRulesScript.get_hobocraft_recipes()
	var selected_recipe_id := StringName(ui_state.get("selected_hobocraft_recipe_id", &""))
	var expanded_categories: Dictionary = ui_state.get("expanded_hobocraft_overlay_categories", {})
	var browser_entries: Array = []
	var current_category := ""
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var category = _format_recipe_category(recipe)
		if category != current_category:
			current_category = category
			var expanded = bool(expanded_categories.get(current_category, expanded_categories.is_empty()))
			browser_entries.append(_build_overlay_recipe_category_entry(&"craft", current_category, expanded))
			if not expanded:
				continue
		var recipe_id := StringName(recipe.get("recipe_id", &""))
		var availability = _get_action_availability(
			deps,
			SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
			_build_action_context(deps, "camp.overlay.craft", {"recipe_id": recipe_id})
		)
		browser_entries.append(_build_overlay_recipe_select_entry(
			&"craft",
			recipe_id,
			"%s\n%s" % [
				String(recipe.get("display_name", "Recipe")),
				"ready" if bool(availability.get("enabled", false)) else String(availability.get("reason", "missing materials"))
			],
			_build_overlay_tooltip(String(recipe.get("summary", "")), availability),
			recipe_id == selected_recipe_id
		))
	return {
		"title": "Tool Area",
		"subtitle": "bench, scraps, cordage, and field repair",
		"theme": {
			"badge_text": "CRAFT",
			"title_bar_color": "2f3622",
			"badge_color": "4f6032",
			"body_color": "171b14",
			"section_color": "20261a",
			"button_color": "2d3422",
			"button_hover_color": "39422b",
			"button_pressed_color": "465235",
			"border_color": "7f9a57",
			"accent_color": "c8dd94"
		},
		"summary": "Repair and makeshift gear stay local to camp because they support work, cooking, and the next day's body.",
		"layout": "recipe_browser",
		"browser": {
			"list_title": "Known Makes",
			"entries": browser_entries,
			"detail": {
				"title": "Hobocraft",
				"summary": "Small camp makes preserve function rather than adding abstraction.",
				"workspace": build_overlay_recipe_workspace_data(
					_find_recipe(recipes, selected_recipe_id),
					player_state,
					config,
					SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
					"camp.overlay.craft",
					"Craft %s",
					false,
					deps
				)
			}
		}
	}


func _build_getting_ready_overlay_model(player_state, config, deps: Dictionary) -> Dictionary:
	var water_action_duration = config.ready_boil_water_minutes if player_state.camp_non_potable_water_units > 0 else config.ready_fetch_water_minutes
	var ready_actions := [
		_build_camp_overlay_action_entry(
			"Fetch Water / Boil Water\nrequired first | %s" % _format_duration(deps, water_action_duration),
			SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER, {}))
		),
		_build_camp_overlay_action_entry(
			"Wash Body\n+Hygiene, +Presentability, -Stamina | %s" % _format_duration(deps, config.ready_wash_body_minutes),
			SurvivalLoopRulesScript.ACTION_READY_WASH_BODY,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_WASH_BODY, {}))
		),
		_build_camp_overlay_action_entry(
			"Wash Face / Hands\n+Hygiene, +Presentability | %s" % _format_duration(deps, config.ready_wash_face_hands_minutes),
			SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS, {}))
		),
		_build_camp_overlay_action_entry(
			"Shave\n+Presentability | %s" % _format_duration(deps, config.ready_shave_minutes),
			SurvivalLoopRulesScript.ACTION_READY_SHAVE,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_SHAVE, {}))
		),
		_build_camp_overlay_action_entry(
			"Comb / Groom\n+Presentability | %s" % _format_duration(deps, config.ready_comb_groom_minutes),
			SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM, {}))
		),
		_build_camp_overlay_action_entry(
			"Air Out Clothes\n+Hygiene, +Presentability | %s" % _format_duration(deps, config.ready_air_out_clothes_minutes),
			SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES, {}))
		),
		_build_camp_overlay_action_entry(
			"Brush Clothes\n+Presentability | %s" % _format_duration(deps, config.ready_brush_clothes_minutes),
			SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES,
			{},
			_build_overlay_tooltip("", _get_action_availability(deps, SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES, {}))
		)
	]
	return {
		"title": "Wash / Get Ready",
		"subtitle": "water, grooming, and being fit to be seen",
		"theme": {
			"badge_text": "READY",
			"title_bar_color": "24353b",
			"badge_color": "365660",
			"body_color": "141a1d",
			"section_color": "1d2529",
			"button_color": "273238",
			"button_hover_color": "31414a",
			"button_pressed_color": "3b505a",
			"border_color": "6fa1a8",
			"accent_color": "b7ddd8"
		},
		"summary": "Water potable %d / non-potable %d. Hygiene %d / 100. Presentability %d / 100. Stamina %d / 100." % [
			int(player_state.camp_potable_water_units),
			int(player_state.camp_non_potable_water_units),
			int(player_state.passport_profile.hygiene),
			int(player_state.passport_profile.presentability),
			_get_stamina_value(deps, player_state)
		],
		"sections": [
			{
				"title": "Routine",
				"detail": "Cleaning up stays close to camp because it exists to support work, town response, and dignity under pressure.",
				"actions": ready_actions
			}
		]
	}


func _build_rest_overlay_model(player_state, config, ui_state: Dictionary, deps: Dictionary) -> Dictionary:
	var selected_rest_hours := int(ui_state.get("selected_rest_hours", 8))
	var selected_sleep_item_id := StringName(ui_state.get("selected_sleep_item_id", &""))
	var sleep_context := {"hours": selected_rest_hours}
	if selected_sleep_item_id != &"":
		sleep_context["sleep_item_id"] = selected_sleep_item_id
	var availability = _get_action_availability(
		deps,
		SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH,
		_build_action_context(deps, "camp.overlay.rest", sleep_context)
	)
	var hour_actions: Array = [
		{
			"label": "-",
			"command_type": "adjust_rest_hours",
			"delta": -1,
			"disabled": selected_rest_hours <= 1,
			"tooltip_text": "Rest one fewer hour."
		},
		{
			"label": "%d hour%s" % [selected_rest_hours, "" if selected_rest_hours == 1 else "s"],
			"command_type": "set_rest_hours",
			"hours": selected_rest_hours,
			"disabled": true,
			"tooltip_text": "Selected rest duration."
		},
		{
			"label": "+",
			"command_type": "adjust_rest_hours",
			"delta": 1,
			"disabled": selected_rest_hours >= 12,
			"tooltip_text": "Rest one more hour."
		}
	]
	var sleep_item_actions: Array = [
		{
			"label": "Ground Only%s" % (" selected" if selected_sleep_item_id == &"" else ""),
			"command_type": "set_sleep_item",
			"sleep_item_id": &"",
			"tooltip_text": "Rest without bedding from the pack."
		}
	]
	if player_state != null and player_state.inventory_state != null and player_state.inventory_state.has_item(&"blanket_roll", 1):
		sleep_item_actions.append({
			"label": "Use Bedroll%s" % (" selected" if selected_sleep_item_id == &"blanket_roll" else ""),
			"command_type": "set_sleep_item",
			"sleep_item_id": &"blanket_roll",
			"tooltip_text": "Use the blanket roll you are carrying."
		})
	return {
		"title": "Bedroll",
		"subtitle": "blankets, rough sleep, and tomorrow's strength",
		"theme": {
			"badge_text": "REST",
			"title_bar_color": "2e2f39",
			"badge_color": "44495e",
			"body_color": "17181d",
			"section_color": "1e2028",
			"button_color": "2a2d38",
			"button_hover_color": "35394a",
			"button_pressed_color": "40455a",
			"border_color": "8d98ba",
			"accent_color": "d3dbf2"
		},
		"summary": "Rough sleep is only relief if the camp is ready enough to carry you into the next workday.",
		"sections": [
			{
				"title": "Hours",
				"detail": "Rest can happen day or night, but night sleep does more good. Current warmth outlook: %s." % _format_warmth_breakdown(deps, SurvivalLoopRulesScript.get_sleep_warmth_breakdown(player_state, config)),
				"layout": "compact_controls",
				"actions": hour_actions
			},
			{
				"title": "Sleeping Items",
				"detail": "Choose whether you are laying out carried bedding or taking the ground as it is.",
				"actions": sleep_item_actions
			},
			{
				"title": "Rest",
				"detail": "Selected rest: %d hour%s%s." % [
					selected_rest_hours,
					"" if selected_rest_hours == 1 else "s",
					" with bedroll" if selected_sleep_item_id == &"blanket_roll" else " on the ground"
				],
				"actions": [
					_build_camp_overlay_action_entry(
						"Sleep %d Hour%s" % [selected_rest_hours, "" if selected_rest_hours == 1 else "s"],
						SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH,
						sleep_context,
						_build_overlay_tooltip(String(availability.get("reason", "")), availability),
						"camp.overlay.rest"
					)
				]
			}
		]
	}


func _get_recipe_material_entries(recipe: Dictionary, player_state, config, is_cooking: bool, deps: Dictionary) -> Array:
	if is_cooking:
		return SurvivalLoopRulesScript.get_cooking_recipe_material_snapshot(
			player_state,
			config,
			recipe,
			_get_item_catalog(deps)
		)
	return SurvivalLoopRulesScript.get_hobocraft_recipe_material_snapshot(
		player_state,
		recipe,
		_get_item_catalog(deps)
	)


func _get_relevant_item_entries(recipe: Dictionary, player_state, is_cooking: bool, deps: Dictionary) -> Array:
	return SurvivalLoopRulesScript.get_recipe_relevant_item_snapshot(
		player_state,
		recipe,
		is_cooking,
		_get_item_catalog(deps)
	)


func _build_camp_overlay_action_entry(label: String, action_id: StringName, context: Dictionary = {}, tooltip_text: String = "", context_source: String = "camp.overlay") -> Dictionary:
	return {
		"label": label,
		"action_id": action_id,
		"context": context.duplicate(true),
		"tooltip_text": tooltip_text,
		"context_source": context_source
	}


func _build_overlay_recipe_select_entry(route_id: StringName, selection_id: StringName, label: String, tooltip_text: String, selected: bool) -> Dictionary:
	return {
		"entry_kind": "recipe",
		"command_type": "select_overlay_recipe",
		"route_id": route_id,
		"selection_id": selection_id,
		"label": label,
		"tooltip_text": tooltip_text,
		"selected": selected
	}


func _build_overlay_recipe_category_entry(route_id: StringName, category_id: String, expanded: bool) -> Dictionary:
	return {
		"entry_kind": "category",
		"command_type": "toggle_overlay_category",
		"route_id": route_id,
		"category_id": category_id,
		"label": "%s %s" % ["[-]" if expanded else "[+]", category_id],
		"expanded": expanded
	}


func _build_overlay_tooltip(base_text: String, availability: Dictionary) -> String:
	var reason = String(availability.get("reason", "")).strip_edges()
	if bool(availability.get("enabled", false)) or reason == "":
		return base_text
	if base_text.strip_edges() == "":
		return "Current check: %s" % reason
	return "%s\nCurrent check: %s" % [base_text, reason]


func _build_action_context(deps: Dictionary, source: String, values: Dictionary = {}) -> Dictionary:
	var callable: Callable = deps.get("build_action_context", Callable())
	if callable.is_valid():
		return callable.call(source, values)
	return values.duplicate(true)


func _get_action_availability(deps: Dictionary, action_id: StringName, context: Dictionary = {}) -> Dictionary:
	var callable: Callable = deps.get("get_action_availability", Callable())
	if callable.is_valid():
		return callable.call(action_id, context)
	return {"enabled": false, "reason": "Action is unavailable."}


func _format_duration(deps: Dictionary, minutes: int) -> String:
	var callable: Callable = deps.get("format_duration", Callable())
	if callable.is_valid():
		return String(callable.call(minutes))
	if minutes >= 60 and minutes % 60 == 0:
		return "%dh" % int(minutes / 60)
	if minutes >= 60:
		return "%dh %02dm" % [int(minutes / 60), minutes % 60]
	return "%dm" % minutes


func _format_warmth_breakdown(deps: Dictionary, breakdown: Dictionary) -> String:
	var callable: Callable = deps.get("format_warmth_breakdown", Callable())
	if callable.is_valid():
		return String(callable.call(breakdown))
	return "not available"


func _get_item_definition(deps: Dictionary, item_id: StringName):
	var callable: Callable = deps.get("get_item_definition", Callable())
	if callable.is_valid():
		return callable.call(item_id)
	return null


func _get_item_catalog(deps: Dictionary):
	var callable: Callable = deps.get("get_item_catalog", Callable())
	if callable.is_valid():
		return callable.call()
	return null


func _get_stamina_value(deps: Dictionary, player_state) -> int:
	var callable: Callable = deps.get("get_stamina_value", Callable())
	if callable.is_valid():
		return int(callable.call(player_state))
	return 0


func _find_recipe(recipes: Array, recipe_id: StringName) -> Dictionary:
	for recipe in recipes:
		if recipe is Dictionary and StringName(recipe.get("recipe_id", &"")) == recipe_id:
			return recipe
	return {}


func _format_recipe_category(recipe: Dictionary) -> String:
	var category = String(recipe.get("category", "")).strip_edges()
	if category == "":
		return "Camp Utility"
	return category
