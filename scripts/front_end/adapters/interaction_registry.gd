class_name InteractionRegistry
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const INVENTORY_UI_PAGE := &"inventory_ui"


static func build_camp_interactions(player_state_service, player_state, config, page_ids: Dictionary, format_duration: Callable) -> Array:
	if player_state == null or config == null:
		return []
	var fire_action = SurvivalLoopRulesScript.ACTION_BUILD_FIRE if int(player_state.camp_fire_level) <= 0 else SurvivalLoopRulesScript.ACTION_TEND_FIRE
	var fire_minutes = config.build_fire_minutes if fire_action == SurvivalLoopRulesScript.ACTION_BUILD_FIRE else config.tend_fire_minutes
	return [
		_make_interaction(
			&"fire",
			"Tend Fire" if fire_action == SurvivalLoopRulesScript.ACTION_TEND_FIRE else "Build Fire",
			fire_action,
			&"",
			"heat / night safety",
			"%s; affects warmth, morale, and sleep risk" % format_duration.call(fire_minutes),
			player_state_service
		),
		_make_interaction(
			&"rest",
			"Bedroll / Rest",
			SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH,
			&"",
			"night recovery",
			"sleep from evening or exhaustion; restores tomorrow's capacity, risks cold if camp is poor",
			player_state_service
		),
		_make_interaction(
			&"craft",
			"Craft Area",
			&"",
			StringName(page_ids.get(&"hobocraft", &"")),
			"repair and makes",
			"uses time and materials; changes future camp and cooking options",
			player_state_service
		),
		_make_interaction(
			&"cooking",
			"Water / Cooking",
			&"",
			StringName(page_ids.get(&"cooking", &"")),
			"food and boiling",
			"trades fire, water, tools, and time for warmth, morale, and safer water",
			player_state_service
		),
		_make_interaction(
			&"ready",
			"Wash / Groom",
			&"",
			StringName(page_ids.get(&"getting_ready", &"")),
			"be fit to be seen",
			"uses water and time; affects appearance and job response",
			player_state_service
		),
		_make_interaction(
			&"exit",
			"Path to Town",
			SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN,
			&"",
			"leave camp",
			"%s travel; returns to work, stores, and remittance choices" % format_duration.call(config.camp_to_town_travel_minutes),
			player_state_service
		)
	]


static func build_town_interactions(player_state_service, config, page_ids: Dictionary, format_duration: Callable) -> Array:
	if config == null:
		return []
	return [
		_make_interaction(&"town_jobs", "Jobs Board", &"", StringName(page_ids.get(&"jobs_board", &"")), "work leads", "check posted work before the day moves on", player_state_service),
		_make_interaction(&"town_foreman", "Foreman's Office", &"", StringName(page_ids.get(&"jobs_board", &"")), "ask after work", "talking to the right desk can turn time into wages", player_state_service),
		_make_interaction(&"town_send_money", "Church Office", &"", StringName(page_ids.get(&"send_money", &"")), "send money home", "turn cash into proof that the road still serves home", player_state_service),
		_make_interaction(&"town_grocery", "Grocery Store", &"", StringName(page_ids.get(&"grocery", &"")), "buy food", "spend stake on provisions, coffee, and camp meals", player_state_service),
		_make_interaction(&"town_hardware", "Hardware Store", &"", StringName(page_ids.get(&"hardware", &"")), "buy tools", "small hardware makes fire, water, and repair work possible", player_state_service),
		_make_interaction(
			&"town_exit",
			"Road to Camp",
			SurvivalLoopRulesScript.ACTION_GO_TO_CAMP,
			&"",
			"leave town",
			"%s travel; returns to your camp, stash, and preparation" % format_duration.call(config.town_to_camp_travel_minutes),
			player_state_service
		)
	]


static func apply_route_bindings(world_objects: Array, interaction_by_route: Dictionary) -> void:
	for world_object in world_objects:
		if world_object == null:
			continue
		var binding = default_binding_for_route(world_object.route_id)
		if binding.is_empty():
			continue
		world_object.action_id = StringName(binding.get("action_id", world_object.action_id))
		world_object.page_id = StringName(binding.get("page_id", world_object.page_id))
		world_object.prompt_action = String(binding.get("prompt_action", world_object.prompt_action))
		if interaction_by_route.has(world_object.route_id):
			var interaction: Dictionary = interaction_by_route.get(world_object.route_id, {})
			world_object.action_id = StringName(interaction.get("action_id", world_object.action_id))
			world_object.page_id = StringName(interaction.get("page_id", world_object.page_id))
			world_object.detail_text = String(interaction.get("consequence_text", world_object.detail_text))
			world_object.prompt_action = resolve_prompt_action(world_object.route_id, String(interaction.get("label", world_object.prompt_action)))


static func default_binding_for_route(route_id: StringName) -> Dictionary:
	match route_id:
		&"rest":
			return {"action_id": &"sleep_rough", "page_id": &"", "prompt_action": "Rest"}
		&"craft":
			return {"action_id": &"", "page_id": &"hobocraft", "prompt_action": "Craft"}
		&"cooking":
			return {"action_id": &"", "page_id": &"cooking", "prompt_action": "Cook"}
		&"exit":
			return {"action_id": &"return_to_town", "page_id": &"", "prompt_action": "Leave for Town"}
		&"stash":
			return {"action_id": &"", "page_id": INVENTORY_UI_PAGE, "prompt_action": "Open the Stash"}
		&"ready":
			return {"action_id": &"", "page_id": &"getting_ready", "prompt_action": "Get Ready"}
		&"town_jobs":
			return {"action_id": &"", "page_id": &"jobs_board", "prompt_action": "Read the Jobs Board"}
		&"town_send_money":
			return {"action_id": &"", "page_id": &"send_money", "prompt_action": "Send Money Home"}
		&"town_grocery":
			return {"action_id": &"", "page_id": &"grocery", "prompt_action": "Buy Provisions"}
		&"town_hardware":
			return {"action_id": &"", "page_id": &"hardware", "prompt_action": "Buy Tools"}
		&"town_foreman":
			return {"action_id": &"", "page_id": &"jobs_board", "prompt_action": "Ask After Work"}
		&"town_exit":
			return {"action_id": &"go_to_camp", "page_id": &"", "prompt_action": "Walk to Camp"}
		_:
			return {}


static func resolve_prompt_action(route_id: StringName, label: String) -> String:
	match route_id:
		&"fire":
			return "Build the Fire" if label.find("Tend") == -1 else "Tend the Fire"
		&"rest":
			return "Rest"
		&"craft":
			return "Craft"
		&"cooking":
			return "Cook"
		&"exit":
			return "Leave for Town"
		&"stash":
			return "Open the Stash"
		&"ready":
			return "Get Ready"
		&"town_jobs":
			return "Read the Jobs Board"
		&"town_send_money":
			return "Send Money Home"
		&"town_grocery":
			return "Buy Provisions"
		&"town_hardware":
			return "Buy Tools"
		&"town_foreman":
			return "Ask After Work"
		&"town_exit":
			return "Walk to Camp"
		_:
			return label


static func _make_interaction(route_id: StringName, label: String, action_id: StringName, page_id: StringName, cue: String, consequence_text: String, player_state_service) -> Dictionary:
	var status_text = ""
	if action_id != &"" and player_state_service != null:
		var availability = player_state_service.get_loop_action_availability(action_id)
		if not bool(availability.get("enabled", false)):
			status_text = " Now: %s" % String(availability.get("reason", "blocked"))
	return {
		"route_id": route_id,
		"label": label,
		"action_id": action_id,
		"page_id": page_id,
		"cue": cue,
		"consequence_text": "%s%s" % [consequence_text, status_text]
	}
