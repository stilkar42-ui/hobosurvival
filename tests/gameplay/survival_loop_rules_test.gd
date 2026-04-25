extends SceneTree

const PlayerStateFactoryScript := preload("res://scripts/player/player_state_factory.gd")
const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")
const SurvivalLoopConfigScript := preload("res://scripts/gameplay/survival_loop_config.gd")
const SurvivalJobTemplateScript := preload("res://scripts/gameplay/survival_job_template.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

var _failed := false


func _init() -> void:
	var catalog = load("res://data/items/inventory_catalog.tres")
	catalog.rebuild_index()

	var config = _build_test_config()
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)

	_expect(state.daily_job_board.size() == 2, "daily job board generates the configured number of jobs")
	_expect(state.job_board_generated_day == 1, "job board marks the current generation day")

	var first_job = _find_nonpersistent_job(state.daily_job_board)
	if first_job.is_empty():
		first_job = state.daily_job_board[0]
	var first_job_result = SurvivalLoopRulesScript.apply_job(state, config, catalog, StringName(first_job.get("instance_id", &"")))
	_expect(first_job_result.get("success", false), "generated job can be performed")
	_expect(state.money_cents > config.starter_money_cents, "generated job increases money")
	_expect(state.passport_data.hygiene < 36, "dirty generated job reduces hygiene when configured")

	var persistent_present := false
	for job in state.daily_job_board:
		if bool(job.get("persistent", false)):
			persistent_present = true
			break
	_expect(persistent_present, "persistent jobs remain on the board after another job is completed")

	while state.time_of_day_minutes < config.camp_prep_unlock_minutes:
		SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_WAIT)

	var fire_ready = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE)
	_expect(not fire_ready.get("enabled", false), "build fire is blocked while still in town")
	var travel_to_camp = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_GO_TO_CAMP)
	_expect(travel_to_camp.get("success", false), "travel to camp succeeds")
	_expect(state.loop_location_id == SurvivalLoopRulesScript.LOCATION_CAMP, "travel to camp updates loop location")
	var store_at_camp = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_GROCERY_BEANS)
	_expect(not store_at_camp.get("enabled", false), "grocery purchases are blocked at camp")
	fire_ready = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE)
	_expect(fire_ready.get("enabled", false), "build fire is available at camp without a narrow evening lock")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE).get("success", false), "build fire succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_TEND_FIRE).get("success", false), "tend fire succeeds when scrap is available")
	_expect(state.get_camp_fire_status_label() == "Fire tended", "camp fire state is tracked")
	var return_to_town = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN)
	_expect(return_to_town.get("success", false), "return to town succeeds")
	_expect(state.loop_location_id == SurvivalLoopRulesScript.LOCATION_TOWN, "return to town updates loop location")
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)

	var fire_state = state
	var no_fire_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(no_fire_state, config)
	no_fire_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	no_fire_state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	fire_state.time_of_day_minutes = config.sleep_rough_window_start_minutes

	var sleep_after_evening = SurvivalLoopRulesScript.can_perform_action(no_fire_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(sleep_after_evening.get("enabled", false), "sleep unlocks at evening without mandatory camp-prep steps")
	no_fire_state.time_of_day_minutes = 60
	var sleep_after_midnight = SurvivalLoopRulesScript.can_perform_action(no_fire_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(sleep_after_midnight.get("enabled", false), "sleep remains available after midnight until sunup")
	no_fire_state.time_of_day_minutes = 720
	no_fire_state.passport_data.fatigue = 60
	var midday_sleep_blocked = SurvivalLoopRulesScript.can_perform_action(no_fire_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(midday_sleep_blocked.get("enabled", false), "camp rest can now happen during the day as well as at night")
	no_fire_state.passport_data.fatigue = 80
	var low_stamina_sleep = SurvivalLoopRulesScript.can_perform_action(no_fire_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(low_stamina_sleep.get("enabled", false), "sleep is available any time once stamina drops under the configured threshold")
	no_fire_state.passport_data.fatigue = 0
	no_fire_state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	fire_state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	var no_fire_sleep = SurvivalLoopRulesScript.apply_action(no_fire_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	var fire_sleep = SurvivalLoopRulesScript.apply_action(fire_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(no_fire_sleep.get("success", false), "sleep rough works without fire")
	_expect(fire_sleep.get("success", false), "sleep rough works with fire prepared")
	_expect(fire_state.passport_data.warmth > no_fire_state.passport_data.warmth, "fire preserves more warmth overnight")
	_expect(fire_state.passport_data.morale > no_fire_state.passport_data.morale, "fire preserves more morale overnight")

	var blanket_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(blanket_state, config)
	blanket_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	blanket_state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	var blanket_warmth_before = blanket_state.passport_data.warmth
	_expect(SurvivalLoopRulesScript.apply_action(blanket_state, config, catalog, SurvivalLoopRulesScript.ACTION_PREP_SLEEPING_SPOT).get("success", false), "blanket roll can be laid for rough sleep")
	_expect(SurvivalLoopRulesScript.apply_action(blanket_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH).get("success", false), "rough sleep with blanket succeeds")
	_expect(blanket_state.passport_data.warmth > blanket_warmth_before - config.sleep_rough_warmth_loss, "blanket buffer reduces overnight warmth loss")
	var day_rest_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(day_rest_state, config)
	day_rest_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	day_rest_state.time_of_day_minutes = 720
	day_rest_state.passport_data.fatigue = 80
	var night_rest_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(night_rest_state, config)
	night_rest_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	night_rest_state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	night_rest_state.passport_data.fatigue = 80
	_expect(SurvivalLoopRulesScript.apply_action(day_rest_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH, -1, {"hours": 4}).get("success", false), "short daytime rest succeeds with an explicit hour count")
	_expect(SurvivalLoopRulesScript.apply_action(night_rest_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH, -1, {"hours": 4}).get("success", false), "short night rest succeeds with an explicit hour count")
	_expect(night_rest_state.passport_data.fatigue < day_rest_state.passport_data.fatigue, "night rest restores more fatigue than daytime rest over the same hours")
	var sleep_item_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(sleep_item_state, config)
	sleep_item_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	sleep_item_state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	var warmth_before_sleep_item = sleep_item_state.passport_data.warmth
	_expect(SurvivalLoopRulesScript.apply_action(sleep_item_state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH, -1, {"hours": 4, "sleep_item_id": &"blanket_roll"}).get("success", false), "sleep action can use a carried bedroll directly from the rest context")
	_expect(sleep_item_state.passport_data.warmth > warmth_before_sleep_item - config.sleep_rough_warmth_loss, "sleeping item context reduces warmth loss during rest")

	var camp_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(camp_state, config)
	camp_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	camp_state.time_of_day_minutes = config.camp_prep_unlock_minutes
	_expect(SurvivalLoopRulesScript.apply_action(camp_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE).get("success", false), "fire can anchor a camp-prep sequence")
	_expect(SurvivalLoopRulesScript.apply_action(camp_state, config, catalog, SurvivalLoopRulesScript.ACTION_GATHER_KINDLING).get("success", false), "gather kindling succeeds during camp prep")
	_expect(camp_state.camp_kindling_prepared, "gather kindling marks campcraft state")
	_expect(SurvivalLoopRulesScript.apply_action(camp_state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER).get("success", false), "fetch water succeeds at camp")
	_expect(SurvivalLoopRulesScript.apply_action(camp_state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER).get("success", false), "boil water succeeds at camp")
	_expect(SurvivalLoopRulesScript.apply_action(camp_state, config, catalog, SurvivalLoopRulesScript.ACTION_WASH_UP).get("success", false), "wash up works during camp prep")
	_expect(camp_state.camp_washed_up, "wash up marks camp state")
	_expect(SurvivalLoopRulesScript.apply_action(camp_state, config, catalog, SurvivalLoopRulesScript.ACTION_QUIET_COMFORT).get("success", false), "quiet comfort works when a comfort source exists")
	_expect(camp_state.camp_quiet_comfort_done, "quiet comfort marks camp state")

	var comfort_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(comfort_state, config)
	comfort_state.money_cents = 500
	var morale_before = comfort_state.passport_data.morale
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_STEW).get("success", false), "buy stew succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_GROCERY_BEANS).get("success", false), "grocery beans purchase succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_GROCERY_POTTED_MEAT).get("success", false), "grocery potted meat purchase succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_COFFEE_GROUNDS).get("success", false), "grocery coffee grounds purchase succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_MATCHES).get("success", false), "hardware match safe purchase succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_EMPTY_CAN).get("success", false), "hardware tin can purchase succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_CORDAGE).get("success", false), "hardware cordage purchase succeeds")
	var stew_stack_index = _find_stack_index(comfort_state, config.stew_item_id)
	_expect(stew_stack_index >= 0, "stew stack can be selected")
	_expect(SurvivalLoopRulesScript.apply_action(comfort_state, config, catalog, SurvivalLoopRulesScript.ACTION_USE_SELECTED, stew_stack_index).get("success", false), "stew can be consumed")
	_expect(comfort_state.passport_data.morale > morale_before, "higher-quality food improves morale")

	_assert_direct_use_item(catalog, config, &"lye_soap", "lye soap direct use")
	_assert_direct_use_item(catalog, config, &"beans_can", "beans direct use")
	_assert_direct_use_item(catalog, config, &"potted_meat", "potted meat direct use")
	_assert_getting_ready_actions(catalog, config)
	_assert_camp_coffee(catalog, config)
	_assert_cooking_recipes(catalog, config)
	_assert_tin_can_heater_recipe(catalog, config)
	_assert_improvised_cooking_tool_differences(catalog, config)
	_assert_can_opening_requirements(catalog, config)
	_assert_sleep_warmth_breakdown(catalog, config)
	_assert_cross_midnight_fire_sleep_warmth(catalog, config)
	_assert_weekly_store_stock(catalog, config)
	_assert_three_week_loop_outcome(catalog, config)
	_assert_monthly_remittance_system(catalog, config)
	_assert_non_four_obligation_schedule(catalog)
	_assert_list_panel_sources(catalog, config)
	_assert_appearance_tiers(catalog, config)
	_assert_job_appearance_gating(catalog, config)
	_assert_job_decay_and_rotation(catalog)
	_assert_hobocraft_recipe(catalog, config)

	var day_two_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(day_two_state, config)
	day_two_state.current_day = 2
	day_two_state.time_of_day_minutes = config.day_start_minutes
	day_two_state.job_board_generated_day = 0
	SurvivalLoopRulesScript.normalize_state(day_two_state, config)
	_expect(day_two_state.daily_job_board.size() >= 1 and day_two_state.daily_job_board.size() <= 2, "a fresh board generates on the next morning")
	_assert_first_playable_loop_scene_instantiates()

	quit(1 if _failed else 0)


func _build_test_config():
	var config = SurvivalLoopConfigScript.new()
	config.support_goal_cents = 1500
	config.monthly_support_target_cents = 1500
	config.starter_money_cents = 150
	config.min_jobs_per_day = 2
	config.max_jobs_per_day = 2
	config.job_generation_seed = 99
	config.camp_prep_unlock_minutes = 960
	config.sleep_rough_unlock_minutes = 1080
	config.sleep_rough_window_start_minutes = 1140
	config.sleep_rough_window_end_minutes = 240
	config.rest_anytime_stamina_threshold = 25
	config.job_templates = [_build_persistent_job(), _build_one_day_job()]
	return config


func _build_persistent_job():
	var job = SurvivalJobTemplateScript.new()
	job.template_id = &"repair_call"
	job.title = "Repair Call"
	job.summary = "A handyman wants a second pair of hands and expects you to keep a hammer handy."
	job.weight = 10
	job.duration_minutes = 180
	job.pay_cents = 90
	job.nutrition_drain = 7
	job.fatigue_delta = 12
	job.morale_delta = 2
	job.hygiene_delta = -4
	job.available_from_minutes = 420
	job.available_until_minutes = 1020
	job.required_item_id = &"claw_hammer"
	job.can_persist = true
	job.persistence_chance_percent = 100
	job.persistent_days_min = 2
	job.persistent_days_max = 2
	return job


func _build_one_day_job():
	var job = SurvivalJobTemplateScript.new()
	job.template_id = &"yard_pull"
	job.title = "Yard Pull"
	job.summary = "Loose salvage and a little day money if you do not mind the dirt."
	job.weight = 10
	job.duration_minutes = 150
	job.pay_cents = 20
	job.nutrition_drain = 8
	job.fatigue_delta = 9
	job.morale_delta = -4
	job.hygiene_delta = -10
	job.available_from_minutes = 360
	job.available_until_minutes = 1080
	job.reward_item_id = &"scrap_tin"
	job.reward_item_quantity = 1
	return job


func _build_appearance_job(template_id: StringName, title: String, min_tier: StringName = &"", max_tier: StringName = &""):
	var job = SurvivalJobTemplateScript.new()
	job.template_id = template_id
	job.title = title
	job.summary = "A posted opening used to test how the board reads a man's condition."
	job.weight = 10
	job.duration_minutes = 120
	job.pay_cents = 70
	job.available_from_minutes = 360
	job.available_until_minutes = 1080
	job.min_appearance_tier = min_tier
	job.max_appearance_tier = max_tier
	return job


func _build_decay_job(decay_behavior: StringName):
	var job = SurvivalJobTemplateScript.new()
	job.template_id = StringName("%s_job" % decay_behavior)
	job.title = "%s Work" % String(decay_behavior).capitalize()
	job.summary = "A test opening for labor board decay."
	job.weight = 10
	job.duration_minutes = 120
	job.pay_cents = 100
	job.can_persist = true
	job.persistence_chance_percent = 100
	job.persistent_days_min = 3
	job.persistent_days_max = 3
	job.decay_behavior = decay_behavior
	job.pay_decay_cents_per_day = 10
	job.minimum_pay_cents = 65
	return job


func _find_stack_index(state, item_id: StringName) -> int:
	for index in range(state.inventory.stacks.size()):
		var stack = state.inventory.get_stack_at(index)
		if stack != null and stack.item.item_id == item_id:
			return index
	return -1


func _find_nonpersistent_job(job_board: Array) -> Dictionary:
	for job in job_board:
		if job is Dictionary and not bool(job.get("persistent", false)):
			return job
	return {}


func _assert_appearance_tiers(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.passport_data.hygiene = 75
	state.passport_data.presentability = 75
	_expect(StringName(SurvivalLoopRulesScript.get_appearance_tier(state, config).get("tier_id", &"")) == &"well_kept", "high hygiene and presentability reads as well kept")
	state.passport_data.hygiene = 55
	state.passport_data.presentability = 55
	_expect(StringName(SurvivalLoopRulesScript.get_appearance_tier(state, config).get("tier_id", &"")) == &"presentable", "middling hygiene and presentability reads as presentable")
	state.passport_data.hygiene = 25
	state.passport_data.presentability = 55
	_expect(StringName(SurvivalLoopRulesScript.get_appearance_tier(state, config).get("tier_id", &"")) == &"grimey", "low hygiene with kept clothes reads as grimey")
	state.passport_data.hygiene = 55
	state.passport_data.presentability = 25
	_expect(StringName(SurvivalLoopRulesScript.get_appearance_tier(state, config).get("tier_id", &"")) == &"disheveled", "washed but poorly kept reads as disheveled")
	state.passport_data.hygiene = 25
	state.passport_data.presentability = 25
	_expect(StringName(SurvivalLoopRulesScript.get_appearance_tier(state, config).get("tier_id", &"")) == &"filthy_unkept", "low hygiene and presentability reads as filthy and unkept")


func _assert_job_appearance_gating(catalog, config) -> void:
	var normal_config = _build_test_config()
	normal_config.min_jobs_per_day = 1
	normal_config.max_jobs_per_day = 1
	normal_config.job_templates = [_build_appearance_job(&"private_fence_repair", "Private Fence Repair", &"presentable")]
	var normal_state = PlayerStateFactoryScript.build_starter_state(catalog, normal_config)
	SurvivalLoopRulesScript.normalize_state(normal_state, normal_config)
	var normal_job = normal_state.daily_job_board[0]
	var blocked = SurvivalLoopRulesScript.can_perform_job(normal_state, normal_config, catalog, StringName(normal_job.get("instance_id", &"")))
	_expect(not blocked.get("enabled", false) and String(blocked.get("reason", "")).find("appearance") >= 0, "poor appearance blocks a normal trust-based job with a reason")
	normal_state.passport_data.hygiene = 55
	normal_state.passport_data.presentability = 55
	var allowed = SurvivalLoopRulesScript.can_perform_job(normal_state, normal_config, catalog, StringName(normal_job.get("instance_id", &"")))
	_expect(allowed.get("enabled", false), "presentable appearance opens the normal job")

	var charity_config = _build_test_config()
	charity_config.min_jobs_per_day = 1
	charity_config.max_jobs_per_day = 1
	charity_config.job_templates = [_build_appearance_job(&"church_wood_box", "Church Wood Box", &"", &"disheveled")]
	var charity_state = PlayerStateFactoryScript.build_starter_state(catalog, charity_config)
	SurvivalLoopRulesScript.normalize_state(charity_state, charity_config)
	var charity_job = charity_state.daily_job_board[0]
	var charity_allowed = SurvivalLoopRulesScript.can_perform_job(charity_state, charity_config, catalog, StringName(charity_job.get("instance_id", &"")))
	_expect(charity_allowed.get("enabled", false), "poor appearance can unlock charity work")
	charity_state.passport_data.hygiene = 75
	charity_state.passport_data.presentability = 75
	var charity_blocked = SurvivalLoopRulesScript.can_perform_job(charity_state, charity_config, catalog, StringName(charity_job.get("instance_id", &"")))
	_expect(not charity_blocked.get("enabled", false), "well kept appearance no longer qualifies for rough charity work")


func _assert_job_decay_and_rotation(catalog) -> void:
	var expire_config = _build_test_config()
	expire_config.min_jobs_per_day = 1
	expire_config.max_jobs_per_day = 1
	expire_config.job_templates = [_build_appearance_job(&"one_day_loading", "One Day Loading")]
	var expire_state = PlayerStateFactoryScript.build_starter_state(catalog, expire_config)
	SurvivalLoopRulesScript.normalize_state(expire_state, expire_config)
	var expired_instance = StringName(expire_state.daily_job_board[0].get("instance_id", &""))
	expire_state.current_day = 2
	expire_state.time_of_day_minutes = expire_config.day_start_minutes
	SurvivalLoopRulesScript.normalize_state(expire_state, expire_config)
	_expect(expire_state.get_job_by_instance_id(expired_instance).is_empty(), "one-day job expires after its duration")

	var decay_config = _build_test_config()
	decay_config.min_jobs_per_day = 1
	decay_config.max_jobs_per_day = 1
	decay_config.job_templates = [_build_decay_job(&"degrade_pay")]
	var decay_state = PlayerStateFactoryScript.build_starter_state(catalog, decay_config)
	SurvivalLoopRulesScript.normalize_state(decay_state, decay_config)
	decay_state.current_day = 2
	decay_state.time_of_day_minutes = decay_config.day_start_minutes
	SurvivalLoopRulesScript.normalize_state(decay_state, decay_config)
	_expect(int(decay_state.daily_job_board[0].get("pay_cents", 0)) == 90, "carried degrade-pay job loses pay after a day")

	var stable_config = _build_test_config()
	stable_config.min_jobs_per_day = 1
	stable_config.max_jobs_per_day = 1
	stable_config.job_templates = [_build_decay_job(&"stable")]
	var stable_state = PlayerStateFactoryScript.build_starter_state(catalog, stable_config)
	SurvivalLoopRulesScript.normalize_state(stable_state, stable_config)
	stable_state.current_day = 2
	stable_state.time_of_day_minutes = stable_config.day_start_minutes
	SurvivalLoopRulesScript.normalize_state(stable_state, stable_config)
	_expect(int(stable_state.daily_job_board[0].get("pay_cents", 0)) == 100, "stable carried job does not degrade")

	var rotation_config = _build_test_config()
	rotation_config.min_jobs_per_day = 0
	rotation_config.max_jobs_per_day = 0
	rotation_config.weekly_job_rotation_drop_chance_percent = 100
	rotation_config.store_refresh_days_per_week = 7
	var rotation_state = PlayerStateFactoryScript.build_starter_state(catalog, rotation_config)
	SurvivalLoopRulesScript.normalize_state(rotation_state, rotation_config)
	var rotating_job = _build_decay_job(&"degrade_pay").to_job_entry(7, &"rotating_job", 10)
	rotation_state.daily_job_board = [rotating_job]
	rotation_state.job_board_generated_day = 7
	rotation_state.current_day = 8
	rotation_state.time_of_day_minutes = rotation_config.day_start_minutes
	SurvivalLoopRulesScript.normalize_state(rotation_state, rotation_config)
	_expect(rotation_state.daily_job_board.is_empty(), "weekly rotation can drop non-stable carried jobs deterministically")


func _assert_direct_use_item(catalog, config, item_id: StringName, label: String) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	var stack_index = _find_stack_index(state, item_id)
	_expect(stack_index >= 0, "%s starts in inventory" % label)
	if stack_index < 0:
		return

	var item_count_before = state.inventory.count_item(item_id)
	var empty_can_count_before = state.inventory.count_item(&"empty_can")
	var nutrition_before = state.passport_data.nutrition
	var hygiene_before = state.passport_data.hygiene
	var presentability_before = state.passport_data.presentability
	var time_before = state.time_of_day_minutes
	var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_USE_SELECTED, stack_index)
	_expect(result.get("success", false), "%s succeeds" % label)
	_expect(String(result.get("message", "")).strip_edges() != "", "%s returns a message" % label)
	_expect(String(result.get("resolved_item_id", "")) == String(item_id), "%s reports the resolved item id" % label)
	_expect(state.time_of_day_minutes > time_before, "%s advances time" % label)
	_expect(state.inventory.count_item(item_id) < item_count_before, "%s removes one item" % label)
	match item_id:
		&"lye_soap":
			_expect(state.passport_data.hygiene > hygiene_before, "%s improves hygiene" % label)
			_expect(state.passport_data.presentability > presentability_before, "%s improves presentability" % label)
		&"beans_can", &"potted_meat":
			_expect(state.passport_data.nutrition > nutrition_before, "%s improves nutrition" % label)
			_expect(state.inventory.count_item(&"empty_can") > empty_can_count_before, "%s leaves an empty can" % label)


func _assert_getting_ready_actions(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	var blocked_in_town = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER)
	_expect(not blocked_in_town.get("enabled", false), "getting-ready water action is camp-only")
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	var blocked_before_water = SurvivalLoopRulesScript.can_perform_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS)
	_expect(not blocked_before_water.get("enabled", false), "normal getting-ready actions require water first")
	var water_result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER)
	_expect(water_result.get("success", false), "fetch water succeeds")
	_expect(state.camp_non_potable_water_units > 0, "fetch water creates non-potable water")
	var boil_result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER)
	_expect(boil_result.get("success", false), "boil water succeeds")
	_expect(state.camp_potable_water_units > 0, "boil water creates potable water")
	for action_id in [
		SurvivalLoopRulesScript.ACTION_READY_WASH_BODY,
		SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS,
		SurvivalLoopRulesScript.ACTION_READY_SHAVE,
		SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM,
		SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES,
		SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES
	]:
		var hygiene_before = state.passport_data.hygiene
		var presentability_before = state.passport_data.presentability
		var fatigue_before = state.passport_data.fatigue
		var morale_before = state.passport_data.morale
		var warmth_before = state.passport_data.warmth
		var time_before = state.time_of_day_minutes
		var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, action_id)
		_expect(result.get("success", false), "%s succeeds" % String(action_id))
		_expect(String(result.get("message", "")).strip_edges() != "", "%s returns a message" % String(action_id))
		_expect(state.time_of_day_minutes > time_before, "%s advances time" % String(action_id))
		_expect(
			state.passport_data.hygiene != hygiene_before
				or state.passport_data.presentability != presentability_before
				or state.passport_data.fatigue != fatigue_before
				or state.passport_data.morale != morale_before
				or state.passport_data.warmth != warmth_before,
			"%s changes condition state" % String(action_id)
		)


func _assert_camp_coffee(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.money_cents = 500
	state.time_of_day_minutes = config.camp_prep_unlock_minutes
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_COFFEE_GROUNDS).get("success", false), "camp coffee grounds can be bought")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_EMPTY_CAN).get("success", false), "camp coffee tin can can be bought")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_GO_TO_CAMP).get("success", false), "camp coffee travel to camp succeeds")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE).get("success", false), "camp coffee fire can be built")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER).get("success", false), "camp coffee water can be handled")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER).get("success", false), "camp coffee water can be boiled")
	var coffee_before = state.inventory.count_item(config.brew_camp_coffee_output_item_id)
	var grounds_before = state.inventory.count_item(config.brew_camp_coffee_input_item_id)
	var brew_result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BREW_CAMP_COFFEE)
	_expect(brew_result.get("success", false), "camp coffee brew succeeds with fire, water, grounds, and tin")
	_expect(String(brew_result.get("message", "")).strip_edges() != "", "camp coffee brew returns a message")
	_expect(state.camp_coffee_brewed, "camp coffee brew marks campcraft state")
	_expect(state.inventory.count_item(config.brew_camp_coffee_input_item_id) < grounds_before, "camp coffee consumes grounds")
	_expect(state.inventory.count_item(config.brew_camp_coffee_output_item_id) > coffee_before, "camp coffee adds hot coffee")


func _assert_weekly_store_stock(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	SurvivalLoopRulesScript.ensure_weekly_store_stock(state, config, catalog)
	var week_one_grocery = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_GROCERY)
	var week_one_hardware = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_HARDWARE)
	var week_one_general = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_GENERAL)
	_expect(week_one_grocery.size() >= 4 and week_one_grocery.size() <= 8, "grocery stocks 4-8 weekly items")
	_expect(week_one_hardware.size() >= 4 and week_one_hardware.size() <= 8, "hardware stocks 4-8 weekly items")
	_expect(week_one_general.size() >= 4 and week_one_general.size() <= 8, "general store stocks 4-8 weekly items")
	_assert_generated_store_entries(catalog, week_one_grocery, SurvivalLoopRulesScript.STORE_GROCERY, "week one grocery")
	_assert_generated_store_entries(catalog, week_one_hardware, SurvivalLoopRulesScript.STORE_HARDWARE, "week one hardware")
	_assert_generated_store_entries(catalog, week_one_general, SurvivalLoopRulesScript.STORE_GENERAL, "week one general store")
	_assert_generated_store_quality_cap(week_one_general, ItemDefinitionScript.QualityTier.GOOD, "week one general store")
	_expect(int(week_one_grocery[0].get("quality_tier", -1)) >= 0, "grocery stock carries a quality tier")
	_expect(_stock_has_item(week_one_grocery, &"coffee_grounds"), "weekly grocery guarantees coffee grounds for cooking tests")
	_expect(_stock_has_item(week_one_grocery, &"beans_can"), "weekly grocery guarantees beans for heating tests")
	_expect(_stock_has_item(week_one_grocery, &"potted_meat"), "weekly grocery guarantees potted meat for heating tests")
	_expect(_stock_has_item(week_one_hardware, &"baling_wire"), "week one hardware guarantees baling wire for craft tests")

	state.money_cents = 500
	var first_entry = week_one_grocery[0]
	var buy_result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK,
		0,
		{"store_id": SurvivalLoopRulesScript.STORE_GROCERY}
	)
	_expect(buy_result.get("success", false), "generic weekly grocery stock purchase succeeds")
	_expect(_has_stack_with_quality(state, StringName(first_entry.get("item_id", &"")), int(first_entry.get("quality_tier", 1))), "weekly store purchase preserves stack quality")
	state.money_cents = 500
	var first_general_entry = week_one_general[0]
	var general_buy_result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK,
		0,
		{"store_id": SurvivalLoopRulesScript.STORE_GENERAL}
	)
	_expect(general_buy_result.get("success", false), "general store weekly stock purchase succeeds")
	_expect(_has_stack_with_quality(state, StringName(first_general_entry.get("item_id", &"")), int(first_general_entry.get("quality_tier", 1))), "general store purchase preserves stack quality")

	state.current_day = 8
	SurvivalLoopRulesScript.ensure_weekly_store_stock(state, config, catalog)
	var week_two_grocery = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_GROCERY)
	var week_two_hardware = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_HARDWARE)
	var week_two_general = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_GENERAL)
	_expect(state.store_stock_week_index == 2, "store stock advances to week two")
	_assert_generated_store_entries(catalog, week_two_grocery, SurvivalLoopRulesScript.STORE_GROCERY, "week two grocery")
	_assert_generated_store_entries(catalog, week_two_hardware, SurvivalLoopRulesScript.STORE_HARDWARE, "week two hardware")
	_assert_generated_store_entries(catalog, week_two_general, SurvivalLoopRulesScript.STORE_GENERAL, "week two general store")
	_assert_generated_store_quality_cap(week_two_general, ItemDefinitionScript.QualityTier.GOOD, "week two general store")
	_expect(_stock_has_item(week_two_grocery, &"coffee_grounds"), "week two grocery keeps coffee test stock available")
	_expect(_stock_has_item(week_two_grocery, &"beans_can"), "week two grocery keeps beans test stock available")
	_expect(_stock_has_item(week_two_grocery, &"potted_meat"), "week two grocery keeps potted meat test stock available")
	_expect(_stock_has_item(week_two_hardware, &"baling_wire"), "week two hardware keeps baling wire test stock available")
	state.current_day = 15
	SurvivalLoopRulesScript.ensure_weekly_store_stock(state, config, catalog)
	var week_three_grocery = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_GROCERY)
	var week_three_hardware = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_HARDWARE)
	var week_three_general = SurvivalLoopRulesScript.get_store_stock(state, config, catalog, SurvivalLoopRulesScript.STORE_GENERAL)
	_expect(state.store_stock_week_index == 3, "store stock advances to week three")
	_assert_generated_store_entries(catalog, week_three_grocery, SurvivalLoopRulesScript.STORE_GROCERY, "week three grocery")
	_assert_generated_store_entries(catalog, week_three_hardware, SurvivalLoopRulesScript.STORE_HARDWARE, "week three hardware")
	_assert_generated_store_entries(catalog, week_three_general, SurvivalLoopRulesScript.STORE_GENERAL, "week three general store")
	_assert_generated_store_quality_cap(week_three_general, ItemDefinitionScript.QualityTier.GOOD, "week three general store")
	_expect(_stock_has_item(week_three_grocery, &"coffee_grounds"), "week three grocery keeps coffee test stock available")
	_expect(_stock_has_item(week_three_grocery, &"beans_can"), "week three grocery keeps beans test stock available")
	_expect(_stock_has_item(week_three_grocery, &"potted_meat"), "week three grocery keeps potted meat test stock available")
	_expect(_stock_has_item(week_three_hardware, &"baling_wire"), "week three hardware keeps baling wire test stock available")
	_expect(
		JSON.stringify(week_one_grocery) != JSON.stringify(week_two_grocery)
			or JSON.stringify(week_two_grocery) != JSON.stringify(week_three_grocery)
			or JSON.stringify(week_one_hardware) != JSON.stringify(week_two_hardware)
			or JSON.stringify(week_two_hardware) != JSON.stringify(week_three_hardware)
			or JSON.stringify(week_one_general) != JSON.stringify(week_two_general)
			or JSON.stringify(week_two_general) != JSON.stringify(week_three_general),
		"weekly stock visibly changes across three cycles"
	)


func _assert_hobocraft_recipe(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	state.inventory.add_item_with_quality(catalog.get_item(&"empty_can"), 1, &"pack", 1, 1.0)
	state.inventory.add_item_with_quality(catalog.get_item(&"baling_wire"), 1, &"pack", 2, 2.0)
	state.inventory.add_item_with_quality(catalog.get_item(&"scrap_tin"), 1, &"pack", 1, 1.0)
	var craft_result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
		-1,
		{"recipe_id": &"soup_can_stove"}
	)
	_expect(craft_result.get("success", false), "soup can stove hobocraft succeeds with store/scrap inputs")
	_expect(state.inventory.count_item(&"soup_can_stove") > 0, "hobocraft adds the crafted stove")
	_expect(String(craft_result.get("message", "")).strip_edges() != "", "hobocraft returns a message")


func _assert_tin_can_heater_recipe(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	_add_test_item(state, catalog, &"empty_can")
	_add_test_item(state, catalog, &"dry_kindling")
	var craft_result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
		-1,
		{"recipe_id": &"tin_can_heater"}
	)
	_expect(craft_result.get("success", false), "tin-can heater hobocraft succeeds with tin and dry kindling")
	_expect(state.inventory.count_item(&"tin_can_heater") > 0, "tin-can heater recipe adds the cooking tool")

	var braced_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(braced_state, config)
	braced_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	_add_test_item(braced_state, catalog, &"empty_can")
	_add_test_item(braced_state, catalog, &"dry_kindling")
	_add_test_item(braced_state, catalog, &"baling_wire")
	var braced_result = SurvivalLoopRulesScript.apply_action(
		braced_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
		-1,
		{"recipe_id": &"wire_braced_tin_can_heater"}
	)
	_expect(braced_result.get("success", false), "wire-braced tin-can heater variant remains craftable when baling wire is available")
	_expect(braced_state.inventory.count_item(&"wire_braced_tin_can_heater") > 0, "wire-braced variant adds the improved cooking tool")


func _assert_improvised_cooking_tool_differences(catalog, config) -> void:
	var soup_stove = catalog.get_item(&"soup_can_stove")
	var tin_heater = catalog.get_item(&"tin_can_heater")
	var braced_heater = catalog.get_item(&"wire_braced_tin_can_heater")
	_expect(soup_stove != null and tin_heater != null and braced_heater != null, "improvised cooking tools exist in catalog")
	if soup_stove == null or tin_heater == null or braced_heater == null:
		return
	_expect(int(tin_heater.cooking_max_uses) < int(braced_heater.cooking_max_uses), "wire-braced heater lasts longer than the crude tin can on a stick")
	_expect(int(braced_heater.cooking_max_uses) < int(soup_stove.cooking_max_uses), "soup can stove remains the steadier longer-use camp tool")
	_expect(float(tin_heater.cooking_efficiency) < float(braced_heater.cooking_efficiency), "crude tin can heater is less efficient than the braced variant")
	_expect(float(soup_stove.cooking_stability) > float(braced_heater.cooking_stability), "soup can stove has the best cooking stability")
	_expect(String(soup_stove.carry_profile).find("compact") >= 0, "soup can stove records a compact carry profile")

	var poor_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(poor_state, config)
	poor_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	poor_state.inventory.add_item_with_quality(catalog.get_item(&"empty_can"), 1, &"pack", 0, 0.0)
	poor_state.inventory.add_item_with_quality(catalog.get_item(&"dry_kindling"), 1, &"pack", 0, 0.0)
	var poor_result = SurvivalLoopRulesScript.apply_action(
		poor_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
		-1,
		{"recipe_id": &"tin_can_heater"}
	)
	_expect(poor_result.get("success", false), "poor materials can still make a crude tin-can heater")
	var poor_stack = _find_stack(poor_state, &"tin_can_heater")
	_expect(poor_stack != null and poor_stack.durability_uses_remaining == 2, "poor input quality reduces crude heater uses")

	var good_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(good_state, config)
	good_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	good_state.inventory.add_item_with_quality(catalog.get_item(&"empty_can"), 1, &"pack", 2, 2.0)
	good_state.inventory.add_item_with_quality(catalog.get_item(&"dry_kindling"), 1, &"pack", 2, 2.0)
	good_state.inventory.add_item_with_quality(catalog.get_item(&"baling_wire"), 1, &"pack", 2, 2.0)
	var good_result = SurvivalLoopRulesScript.apply_action(
		good_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE,
		-1,
		{"recipe_id": &"wire_braced_tin_can_heater"}
	)
	_expect(good_result.get("success", false), "better can and wire can make an improved braced heater")
	var good_stack = _find_stack(good_state, &"wire_braced_tin_can_heater")
	_expect(good_stack != null and good_stack.quality_tier >= 2, "better input quality carries into the braced heater output")
	_expect(good_stack != null and good_stack.durability_uses_remaining >= 8, "better input quality increases braced heater uses")

	var cook_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(cook_state, config)
	cook_state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	cook_state.time_of_day_minutes = config.camp_prep_unlock_minutes
	cook_state.set_camp_fire_level(1)
	cook_state.inventory.add_item_with_quality(tin_heater, 1, &"pack", 1, 1.0, 1)
	_add_test_item(cook_state, catalog, &"beans_can")
	var cook_result = SurvivalLoopRulesScript.apply_action(
		cook_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": &"heat_beans"}
	)
	_expect(cook_result.get("success", false), "cooking can consume a limited-use tin-can heater")
	_expect(cook_state.inventory.count_item(&"tin_can_heater") == 0, "tin-can heater is removed when its cooking uses run out")


func _assert_cooking_recipes(catalog, config) -> void:
	_assert_hot_food_recipe(catalog, config, &"heat_beans", &"beans_can", "heated beans")
	_assert_hot_food_recipe(catalog, config, &"heat_potted_meat", &"potted_meat", "heated potted meat")
	_assert_cooking_coffee(catalog, config)
	_assert_mulligan_stew(catalog, config, [&"beans_can", &"potted_meat"], "mulligan stew with canned goods")
	_assert_mulligan_stew(catalog, config, [&"dried_beans", &"salt_pouch"], "mulligan stew with dry staple and salt")


func _assert_hot_food_recipe(catalog, config, recipe_id: StringName, item_id: StringName, label: String) -> void:
	var state = _build_cooking_state(catalog, config)
	_add_test_item(state, catalog, item_id)
	var warmth_before = state.passport_data.warmth
	var morale_before = state.passport_data.morale
	var nutrition_before = state.passport_data.nutrition
	var item_count_before = state.inventory.count_item(item_id)
	var result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": recipe_id}
	)
	_expect(result.get("success", false), "%s cooking succeeds" % label)
	_expect(String(result.get("message", "")).strip_edges() != "", "%s cooking returns a message" % label)
	_expect(state.inventory.count_item(item_id) < item_count_before, "%s consumes the cold food" % label)
	_expect(state.inventory.count_item(&"empty_can") > 0, "%s leaves an empty tin" % label)
	_expect(state.passport_data.nutrition > nutrition_before, "%s improves nutrition" % label)
	_expect(state.passport_data.warmth > warmth_before, "%s improves warmth" % label)
	_expect(state.passport_data.morale > morale_before, "%s improves morale" % label)


func _assert_cooking_coffee(catalog, config) -> void:
	var state = _build_cooking_state(catalog, config)
	_add_test_item(state, catalog, &"coffee_grounds")
	_add_test_item(state, catalog, &"empty_can")
	state.camp_potable_water_units = 1
	var result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": &"brew_camp_coffee"}
	)
	_expect(result.get("success", false), "cooking panel camp coffee succeeds")
	_expect(state.inventory.count_item(&"hot_coffee") > 0, "cooking panel camp coffee adds hot coffee")
	_expect(state.camp_coffee_brewed, "cooking panel camp coffee marks camp coffee state")


func _assert_mulligan_stew(catalog, config, item_ids: Array, label: String) -> void:
	var state = _build_cooking_state(catalog, config)
	for item_id in item_ids:
		_add_test_item(state, catalog, StringName(item_id))
	state.camp_potable_water_units = 1
	var warmth_before = state.passport_data.warmth
	var morale_before = state.passport_data.morale
	var nutrition_before = state.passport_data.nutrition
	var result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": &"mulligan_stew"}
	)
	_expect(result.get("success", false), "%s succeeds" % label)
	_expect(String(result.get("message", "")).strip_edges() != "", "%s returns a message" % label)
	_expect(state.passport_data.nutrition > nutrition_before, "%s improves nutrition" % label)
	_expect(state.passport_data.warmth > warmth_before, "%s improves warmth" % label)
	_expect(state.passport_data.morale > morale_before, "%s improves morale" % label)


func _assert_sleep_warmth_breakdown(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	state.time_of_day_minutes = config.sleep_rough_window_start_minutes
	_add_test_item(state, catalog, &"scrap_tin")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_BUILD_FIRE).get("success", false), "warmth regression fire can be built")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_TEND_FIRE).get("success", false), "warmth regression fire can be tended")
	_expect(SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_PREP_SLEEPING_SPOT).get("success", false), "warmth regression bedroll can be laid")
	state.passport_data.warmth = 0
	var breakdown = SurvivalLoopRulesScript.get_sleep_warmth_breakdown(state, config)
	_expect(int(breakdown.get("net_warmth_change", 0)) > 0, "tended fire plus bedroll has positive net sleep warmth")
	var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(result.get("success", false), "warmth regression sleep succeeds")
	_expect(state.passport_data.warmth > 0, "tended fire plus blanket raises warmth from zero during sleep")


func _assert_cross_midnight_fire_sleep_warmth(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	state.current_day = 1
	state.time_of_day_minutes = 1430
	state.set_camp_fire_level(2)
	state.mark_sleeping_spot_ready(true)
	var wait_result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_WAIT)
	_expect(wait_result.get("success", false), "ordinary camp time can cross midnight before sleep")
	state.passport_data.warmth = 0
	var breakdown = SurvivalLoopRulesScript.get_sleep_warmth_breakdown(state, config)
	_expect(int(breakdown.get("fire_level", 0)) == 2, "post-midnight sleep still sees the tended fire from the same night")
	_expect(int(breakdown.get("net_warmth_change", 0)) > 0, "post-midnight tended fire plus bedding has positive sleep warmth")
	var result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_expect(result.get("success", false), "post-midnight rough sleep succeeds")
	_expect(state.passport_data.warmth > 0, "post-midnight fire plus bedding raises warmth in the authoritative sleep path")


func _assert_can_opening_requirements(catalog, config) -> void:
	var blocked_state = _build_cooking_state(catalog, config)
	blocked_state.inventory.remove_item(&"pocket_knife", 1)
	blocked_state.inventory.remove_item(&"church_key", 1)
	_add_test_item(blocked_state, catalog, &"beans_can")
	var blocked_stack_index = _find_stack_index(blocked_state, &"beans_can")
	var blocked_direct_use = SurvivalLoopRulesScript.can_perform_action(
		blocked_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_USE_SELECTED,
		blocked_stack_index
	)
	_expect(not blocked_direct_use.get("enabled", false), "direct canned use is blocked without a church key or pocket knife")
	var blocked_result = SurvivalLoopRulesScript.can_perform_action(
		blocked_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": &"heat_beans"}
	)
	_expect(not blocked_result.get("enabled", false), "canned cooking is blocked without a church key or pocket knife")

	var church_key_state = _build_cooking_state(catalog, config)
	church_key_state.inventory.remove_item(&"pocket_knife", 1)
	_add_test_item(church_key_state, catalog, &"church_key")
	_add_test_item(church_key_state, catalog, &"beans_can")
	var church_key_result = SurvivalLoopRulesScript.apply_action(
		church_key_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": &"heat_beans"}
	)
	_expect(church_key_result.get("success", false), "church key satisfies canned cooking opener requirement")
	_expect(church_key_state.inventory.count_item(&"church_key") > 0, "church key is not consumed by opening a can")

	var knife_state = _build_cooking_state(catalog, config)
	_add_test_item(knife_state, catalog, &"beans_can")
	var knife_result = SurvivalLoopRulesScript.apply_action(
		knife_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		-1,
		{"recipe_id": &"heat_beans"}
	)
	_expect(knife_result.get("success", false), "pocket knife satisfies canned cooking opener requirement")
	_expect(knife_state.inventory.count_item(&"pocket_knife") > 0, "pocket knife is not consumed by opening a can")


func _assert_three_week_loop_outcome(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.money_cents = 3000
	for _index in range(3):
		var send_result = SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_SEND_LARGE)
		_expect(send_result.get("success", false), "support send action succeeds during extended loop")
	_expect(state.support_sent_total_cents >= state.support_goal_cents, "support goal can be met before the run ends")
	_expect(state.prototype_loop_status == &"ongoing", "meeting support goal does not end the run before three weeks")
	state.current_day = state.day_limit + 1
	SurvivalLoopRulesScript.normalize_state(state, config)
	_expect(state.prototype_loop_status == &"success", "three-week run resolves success after the day limit when support goal is met")

	var failed_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(failed_state, config)
	failed_state.current_day = failed_state.day_limit + 1
	SurvivalLoopRulesScript.normalize_state(failed_state, config)
	_expect(failed_state.prototype_loop_status == &"failure", "three-week run still fails after the day limit if support goal is missed")


func _assert_monthly_remittance_system(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	_expect(state.day_limit == 28, "default remittance loop is seeded to 28 days")
	_expect(state.support_obligation_entries.size() == 4, "default remittance config seeds four checkpoint entries")
	_expect(int(state.support_obligation_entries[0].get("checkpoint_day", 0)) == 7, "first default checkpoint lands on Day 7")
	_expect(int(state.support_obligation_entries[0].get("target_cents", 0)) == 375, "default weekly remittance target is $3.75")
	_expect(state.monthly_support_target_cents == 1500, "default monthly remittance target is $15.00")
	state.money_cents = 1000
	state.current_day = 5
	state.time_of_day_minutes = config.day_start_minutes
	var mail_result = SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_SEND_SUPPORT,
		-1,
		{"amount_cents": 375, "method_id": &"mail"}
	)
	_expect(mail_result.get("success", false), "mail remittance action succeeds")
	_expect(state.support_committed_total_cents == 375, "mail records committed support")
	_expect(state.support_delivered_total_cents == 0, "mail does not count before arrival")
	_expect(state.pending_support_deliveries.size() == 1, "mail creates one pending delivery")
	_expect(int(state.pending_support_deliveries[0].get("arrival_day", 0)) == 7, "mail arrival uses configured two-day delay")
	_advance_to_next_day(state, config, catalog, 7)
	_expect(state.support_delivered_total_cents == 0, "mail still does not count during the arrival day before end-of-day")
	_advance_to_next_day(state, config, catalog, 8)
	_expect(state.support_delivered_total_cents == 375, "mail arriving on checkpoint day resolves before evaluation")
	_expect(String(state.support_obligation_entries[0].get("status", "")) == "hit", "Day 7 obligation is hit after same-day mail delivery resolves")

	var telegraph_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(telegraph_state, config)
	telegraph_state.money_cents = 1000
	var telegraph_result = SurvivalLoopRulesScript.apply_action(
		telegraph_state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_SEND_SUPPORT,
		-1,
		{"amount_cents": 375, "method_id": &"telegraph"}
	)
	_expect(telegraph_result.get("success", false), "telegraph remittance action succeeds")
	_expect(telegraph_state.support_delivered_total_cents == 375, "telegraph counts immediately")
	_expect(telegraph_state.pending_support_deliveries.is_empty(), "telegraph does not create pending mail")

	var mutable_state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(mutable_state, config)
	mutable_state.support_obligation_entries[0]["target_cents"] = 150
	mutable_state.monthly_support_target_cents = 450
	_expect(int(mutable_state.support_obligation_entries[0].get("target_cents", 0)) == 150, "weekly obligation target is mutable mid-run")
	_expect(mutable_state.monthly_support_target_cents == 450, "monthly obligation target is mutable mid-run")


func _assert_non_four_obligation_schedule(catalog) -> void:
	var config = _build_test_config()
	config.day_limit = 9
	config.support_goal_cents = 200
	config.monthly_support_target_cents = 200
	config.support_obligation_defaults = [
		{"obligation_id": &"early_due", "label": "Early Due", "checkpoint_day": 3, "target_cents": 75},
		{"obligation_id": &"late_due", "label": "Late Due", "checkpoint_day": 9, "target_cents": 125}
	]
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	_expect(state.support_obligation_entries.size() == 2, "obligation system accepts a non-four-entry schedule")
	state.money_cents = 1000
	_expect(SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_SEND_SUPPORT,
		-1,
		{"amount_cents": 75, "method_id": &"telegraph"}
	).get("success", false), "custom schedule first telegraph send succeeds")
	_advance_to_next_day(state, config, catalog, 4)
	_expect(String(state.support_obligation_entries[0].get("status", "")) == "hit", "custom Day 3 checkpoint evaluates without four-week assumptions")
	_expect(SurvivalLoopRulesScript.apply_action(
		state,
		config,
		catalog,
		SurvivalLoopRulesScript.ACTION_SEND_SUPPORT,
		-1,
		{"amount_cents": 125, "method_id": &"telegraph"}
	).get("success", false), "custom schedule second telegraph send succeeds")
	_advance_to_next_day(state, config, catalog, 10)
	_expect(state.prototype_loop_status == &"success", "custom schedule resolves monthly success at configured month end")


func _assert_list_panel_sources(catalog, config) -> void:
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	_expect(state.daily_job_board.size() > 0, "Jobs Board source list is not empty when jobs exist")
	var hobocraft = SurvivalLoopRulesScript.get_hobocraft_recipes()
	_expect(hobocraft.size() > 0, "Hobocraft source list is not empty when recipes are known")
	_expect(String(hobocraft[0].get("category", "")).strip_edges() != "", "Hobocraft recipes expose category navigation metadata")
	var all_cooking = SurvivalLoopRulesScript.get_cooking_recipes()
	_expect(all_cooking.size() > 0, "Cooking source list is not empty when recipes are known")
	var blocked_job = state.daily_job_board[0]
	state.passport_data.hygiene = 0
	state.passport_data.presentability = 0
	blocked_job["min_appearance_tier"] = &"well_kept"
	var availability = SurvivalLoopRulesScript.can_perform_job(state, config, catalog, StringName(blocked_job.get("instance_id", &"")))
	_expect(not bool(availability.get("enabled", true)) and String(availability.get("reason", "")).strip_edges() != "", "blocked jobs still produce a visible explanation")
	var known_count := 0
	for recipe in all_cooking:
		if recipe is Dictionary:
			known_count += 1
	_expect(known_count == all_cooking.size(), "All Known cooking filter source contains concrete recipe entries")


func _advance_to_next_day(state, config, catalog, target_day: int) -> void:
	while state.current_day < target_day:
		state.time_of_day_minutes = 1430
		SurvivalLoopRulesScript.apply_action(state, config, catalog, SurvivalLoopRulesScript.ACTION_WAIT)


func _build_cooking_state(catalog, config):
	var state = PlayerStateFactoryScript.build_starter_state(catalog, config)
	SurvivalLoopRulesScript.normalize_state(state, config)
	state.set_loop_location(SurvivalLoopRulesScript.LOCATION_CAMP)
	state.time_of_day_minutes = config.camp_prep_unlock_minutes
	state.set_camp_fire_level(1)
	_add_test_item(state, catalog, &"tin_can_heater")
	return state


func _add_test_item(state, catalog, item_id: StringName, quantity: int = 1) -> void:
	var item = catalog.get_item(item_id)
	_expect(item != null, "%s exists in catalog" % String(item_id))
	if item != null:
		state.inventory.add_item(item, quantity, &"pack")


func _has_stack_with_quality(state, item_id: StringName, quality_tier: int) -> bool:
	for stack in state.inventory.stacks:
		if stack != null and not stack.is_empty() and stack.item.item_id == item_id and stack.quality_tier == quality_tier:
			return true
	return false


func _find_stack(state, item_id: StringName):
	for stack in state.inventory.stacks:
		if stack != null and not stack.is_empty() and stack.item.item_id == item_id:
			return stack
	return null


func _stock_has_item(stock: Array, item_id: StringName) -> bool:
	for entry in stock:
		if entry is Dictionary and StringName(entry.get("item_id", &"")) == item_id:
			return true
	return false


func _assert_generated_store_entries(catalog, stock: Array, store_id: StringName, label: String) -> void:
	for entry in stock:
		_expect(entry is Dictionary, "%s entry is dictionary data" % label)
		if not (entry is Dictionary):
			continue
		var item_id = StringName(entry.get("item_id", &""))
		_expect(StringName(entry.get("store_id", &"")) == store_id, "%s entry records its store id" % label)
		_expect(item_id != &"", "%s entry records an item id" % label)
		_expect(catalog.get_item(item_id) != null, "%s entry item exists in catalog" % label)
		_expect(int(entry.get("price_cents", 0)) > 0, "%s entry has a positive price" % label)
		_expect(entry.has("quality_tier"), "%s entry has quality tier" % label)
		_expect(entry.has("quality_score"), "%s entry has quality score" % label)


func _assert_generated_store_quality_cap(stock: Array, max_quality: int, label: String) -> void:
	for entry in stock:
		if not (entry is Dictionary):
			continue
		_expect(int(entry.get("quality_tier", -1)) <= max_quality, "%s entry stays within quality cap" % label)


func _assert_first_playable_loop_scene_instantiates() -> void:
	var title_scene = load("res://scenes/front_end/title_front_end.tscn")
	_expect(title_scene != null, "title front end scene loads")
	if title_scene != null:
		var title_page = title_scene.instantiate()
		_expect(title_page != null, "title front end scene instantiates")
		if title_page != null:
			root.add_child(title_page)
			title_page.queue_free()
	var scene = load("res://scenes/front_end/first_playable_loop_page.tscn")
	_expect(scene != null, "first playable loop scene loads")
	if scene == null:
		return
	var page = scene.instantiate()
	_expect(page != null, "first playable loop scene instantiates")
	if page == null:
		return
	root.add_child(page)
	_expect(page.has_method("_finish_ready"), "first playable loop page exposes deferred setup")
	page.queue_free()
	var camp_scene = load("res://scenes/front_end/camp_isometric_play_layer.tscn")
	_expect(camp_scene != null, "camp isometric play layer scene loads")
	if camp_scene == null:
		return
	var camp_layer = camp_scene.instantiate()
	_expect(camp_layer != null, "camp isometric play layer instantiates")
	if camp_layer != null:
		_expect(camp_layer.has_method("set_interactions"), "camp layer exposes thin interaction input")
		_expect(camp_layer.has_method("set_input_enabled"), "camp layer exposes world input gating")
		_expect(camp_layer.has_signal("interaction_activated"), "camp layer exposes world interaction bridge")
		camp_layer.set_interactions([
			{
				"route_id": &"fire",
				"label": "Fire Spot",
				"action_id": SurvivalLoopRulesScript.ACTION_BUILD_FIRE,
				"page_id": &"",
				"cue": "heat",
				"consequence_text": "time and warmth"
			},
			{
				"route_id": &"craft",
				"label": "Craft Area",
				"action_id": &"",
				"page_id": &"hobocraft",
				"cue": "materials",
				"consequence_text": "time and future options"
			}
		])
		camp_layer.queue_free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
