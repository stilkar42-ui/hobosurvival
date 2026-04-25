class_name SurvivalLoopRules
extends RefCounted

const TRACE_LOGGING_ENABLED := false

const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")
const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")
const ItemQualityRulesScript := preload("res://scripts/gameplay/item_quality_rules.gd")
const RecipeCatalogScript := preload("res://scripts/data/recipe_catalog.gd")
const StoreInventoryCatalogScript := preload("res://scripts/data/store_inventory_catalog.gd")

const LOCATION_TOWN := &"town"
const LOCATION_CAMP := &"camp"
const STORE_GROCERY := &"grocery"
const STORE_HARDWARE := &"hardware"

const ACTION_GO_TO_CAMP := &"go_to_camp"
const ACTION_RETURN_TO_TOWN := &"return_to_town"
const ACTION_BUY_STORE_STOCK := &"buy_store_stock"
const ACTION_CRAFT_RECIPE := &"craft_recipe"
const ACTION_WAIT := &"wait"
const ACTION_SELL_SCRAP := &"sell_scrap"
const ACTION_BUY_BREAD := &"buy_bread"
const ACTION_BUY_COFFEE := &"buy_coffee"
const ACTION_BUY_STEW := &"buy_stew"
const ACTION_BUY_TOBACCO := &"buy_tobacco"
const ACTION_BUY_GROCERY_BEANS := &"buy_grocery_beans"
const ACTION_BUY_GROCERY_POTTED_MEAT := &"buy_grocery_potted_meat"
const ACTION_BUY_COFFEE_GROUNDS := &"buy_coffee_grounds"
const ACTION_BUY_HARDWARE_MATCHES := &"buy_hardware_matches"
const ACTION_BUY_HARDWARE_EMPTY_CAN := &"buy_hardware_empty_can"
const ACTION_BUY_HARDWARE_CORDAGE := &"buy_hardware_cordage"
const ACTION_SEND_SMALL := &"send_small"
const ACTION_SEND_LARGE := &"send_large"
const ACTION_SEND_SUPPORT := &"send_support"
const ACTION_BUILD_FIRE := &"build_fire"
const ACTION_TEND_FIRE := &"tend_fire"
const ACTION_GATHER_KINDLING := &"gather_kindling"
const ACTION_BREW_CAMP_COFFEE := &"brew_camp_coffee"
const ACTION_COOK_RECIPE := &"cook_recipe"
const ACTION_PREP_SLEEPING_SPOT := &"prep_sleeping_spot"
const ACTION_WASH_UP := &"wash_up"
const ACTION_QUIET_COMFORT := &"quiet_comfort"
const ACTION_SLEEP_ROUGH := &"sleep_rough"
const ACTION_USE_SELECTED := &"use_selected"
const ACTION_READY_FETCH_WATER := &"ready_fetch_water"
const ACTION_READY_WASH_BODY := &"ready_wash_body"
const ACTION_READY_WASH_FACE_HANDS := &"ready_wash_face_hands"
const ACTION_READY_SHAVE := &"ready_shave"
const ACTION_READY_COMB_GROOM := &"ready_comb_groom"
const ACTION_READY_AIR_OUT_CLOTHES := &"ready_air_out_clothes"
const ACTION_READY_BRUSH_CLOTHES := &"ready_brush_clothes"

const HOBOCRAFT_RECIPES := [
	{
		"recipe_id": &"soup_can_stove",
		"display_name": "Soup Can Stove",
		"category": "Fire & Heat",
		"summary": "A pierced tin stove for small fire and coffee work.",
		"output_item_id": &"soup_can_stove",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1},
			{"item_id": &"scrap_tin", "quantity": 1}
		]
	},
	{
		"recipe_id": &"repair_roll",
		"display_name": "Repair Roll",
		"category": "Repair",
		"summary": "Needle, thread, cloth, and cord kept together for road mending.",
		"output_item_id": &"repair_roll",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"needle_thread", "quantity": 1},
			{"item_id": &"cloth_patch", "quantity": 1},
			{"item_id": &"cordage", "quantity": 1}
		]
	},
	{
		"recipe_id": &"alarm_can_line",
		"display_name": "Alarm Can Line",
		"category": "Traps / Warning",
		"summary": "A tin-and-line warning rig for a nervous camp edge.",
		"output_item_id": &"alarm_can_line",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"cordage", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		]
	},
	{
		"recipe_id": &"road_cook_kit",
		"display_name": "Road Cook Kit",
		"category": "Food Prep",
		"summary": "A small camp cook bundle for boiling water and stretching staples.",
		"output_item_id": &"road_cook_kit",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"cordage", "quantity": 1},
			{"item_id": &"salt_pouch", "quantity": 1},
			{"item_id": &"dried_beans", "quantity": 1}
		]
	},
	{
		"recipe_id": &"tin_can_heater",
		"display_name": "Tin Can on a Stick",
		"category": "Fire & Heat",
		"summary": "A humble tin heater fixed to a dry kindling stick for warming small food over campfire coals.",
		"output_item_id": &"tin_can_heater",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1}
		]
	},
	{
		"recipe_id": &"wire_braced_tin_can_heater",
		"display_name": "Wire-Braced Tin Can on a Stick",
		"category": "Fire & Heat",
		"summary": "The same poor tin heater, steadied with baling wire when the store has some to spare.",
		"output_item_id": &"wire_braced_tin_can_heater",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		]
	}
]

const COOKING_HEAT_TOOL_ITEM_IDS := [&"tin_can_heater", &"wire_braced_tin_can_heater", &"road_cook_kit", &"soup_can_stove"]
const CAN_OPENER_ITEM_IDS := [&"church_key", &"pocket_knife"]
const SEALED_CAN_ITEM_IDS := [&"beans_can", &"potted_meat", &"stew_tin"]
const MULLIGAN_STAPLE_ITEM_IDS := [&"beans_can", &"dried_beans", &"oats_sack"]
const MULLIGAN_BODY_ITEM_IDS := [&"potted_meat", &"lard_tin", &"salt_pouch"]

const COOKING_RECIPES := [
	{
		"recipe_id": &"boil_water",
		"display_name": "Fetch / Boil Water",
		"category": "Water",
		"summary": "Fetches camp water if none is on hand, or boils non-potable water into potable water.",
		"inputs_text": "camp water source; fire preferred for boiling",
		"effects_text": "+non-potable water, or converts it to potable water"
	},
	{
		"recipe_id": &"brew_camp_coffee",
		"display_name": "Brew Camp Coffee",
		"category": "Drink",
		"summary": "Coffee made over the fire from bought grounds, water, and a tin. Cheaper than a counter cup.",
		"inputs_text": "coffee grounds + potable water + empty tin + fire",
		"effects_text": "adds hot coffee"
	},
	{
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans",
		"category": "Hot Food",
		"summary": "Warm a can of beans over the fire and eat it hot instead of cold from the tin.",
		"inputs_text": "can of beans + fire + small cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; leaves an empty tin"
	},
	{
		"recipe_id": &"heat_potted_meat",
		"display_name": "Heat Potted Meat",
		"category": "Hot Food",
		"summary": "Warm preserved meat just enough to make a poor meal sit better.",
		"inputs_text": "potted meat tin + fire + small cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; leaves an empty tin"
	},
	{
		"recipe_id": &"mulligan_stew",
		"display_name": "Mulligan Stew",
		"category": "Camp Meal",
		"summary": "A flexible camp stew that stretches water, staples, and whatever small body the pack can spare.",
		"inputs_text": "potable water + one staple + one meat/fat/flavor support + fire + cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; uses flexible substitutions"
	}
]

static func can_perform_action(player_state, config, item_catalog, action_id: StringName, selected_stack_index: int = -1, context: Dictionary = {}) -> Dictionary:
	if player_state == null or config == null:
		return _blocked("Loop state is unavailable.")
	ensure_weekly_store_stock(player_state, config, item_catalog)
	if player_state.prototype_loop_status != &"ongoing":
		return _blocked("This run is already over.")
	if action_id == ACTION_GO_TO_CAMP:
		if _is_at_camp(player_state):
			return _blocked("You are already at camp.")
		return _allowed()
	if action_id == ACTION_RETURN_TO_TOWN:
		if not _is_at_camp(player_state):
			return _blocked("You are already in town.")
		return _allowed()
	if action_id == ACTION_READY_FETCH_WATER:
		if not _is_at_camp(player_state):
			return _blocked("Getting ready belongs at camp for this prototype.")
		if player_state.has_potable_water(1):
			return _blocked("Potable water is already ready for washing.")
		return _allowed()
	if _is_normal_getting_ready_action(action_id):
		if not _is_at_camp(player_state):
			return _blocked("Getting ready belongs at camp for this prototype.")
		if not player_state.has_potable_water(1):
			return _blocked("Fetch water and boil it before washing or grooming.")
		return _allowed()

	match action_id:
		ACTION_WAIT:
			return _allowed()
		ACTION_SELL_SCRAP:
			if not _is_at_town(player_state):
				return _blocked("The scrap dealer is back in town.")
			if not _is_in_window(player_state.time_of_day_minutes, config.sell_scrap_start_minutes, config.sell_scrap_end_minutes):
				return _blocked("The scrap dealer is only around during the day.")
			if not player_state.inventory_state.has_item(&"scrap_tin", config.sell_scrap_quantity):
				return _blocked("You need scrap in hand before anyone will pay for it.")
			return _allowed()
		ACTION_BUY_STORE_STOCK:
			return _check_store_stock_purchase(player_state, config, item_catalog, StringName(context.get("store_id", &"")), selected_stack_index)
		ACTION_CRAFT_RECIPE:
			return _check_craft_recipe(player_state, item_catalog, StringName(context.get("recipe_id", &"")))
		ACTION_COOK_RECIPE:
			return _check_cooking_recipe(player_state, config, item_catalog, StringName(context.get("recipe_id", &"")))
		ACTION_BUY_BREAD:
			return _check_town_purchase(player_state, item_catalog, config.bread_item_id, config.bread_price_cents)
		ACTION_BUY_COFFEE:
			return _check_town_purchase(player_state, item_catalog, config.coffee_item_id, config.coffee_price_cents)
		ACTION_BUY_STEW:
			return _check_town_purchase(player_state, item_catalog, config.stew_item_id, config.stew_price_cents)
		ACTION_BUY_TOBACCO:
			return _check_town_purchase(player_state, item_catalog, config.tobacco_item_id, config.tobacco_price_cents)
		ACTION_BUY_GROCERY_BEANS:
			return _check_town_purchase(player_state, item_catalog, config.grocery_beans_item_id, config.grocery_beans_price_cents)
		ACTION_BUY_GROCERY_POTTED_MEAT:
			return _check_town_purchase(player_state, item_catalog, config.grocery_potted_meat_item_id, config.grocery_potted_meat_price_cents)
		ACTION_BUY_COFFEE_GROUNDS:
			return _check_town_purchase(player_state, item_catalog, config.grocery_coffee_grounds_item_id, config.grocery_coffee_grounds_price_cents)
		ACTION_BUY_HARDWARE_MATCHES:
			return _check_town_purchase(player_state, item_catalog, config.hardware_matches_item_id, config.hardware_matches_price_cents)
		ACTION_BUY_HARDWARE_EMPTY_CAN:
			return _check_town_purchase(player_state, item_catalog, config.hardware_empty_can_item_id, config.hardware_empty_can_price_cents)
		ACTION_BUY_HARDWARE_CORDAGE:
			return _check_town_purchase(player_state, item_catalog, config.hardware_cordage_item_id, config.hardware_cordage_price_cents)
		ACTION_SEND_SMALL:
			if not _is_at_town(player_state):
				return _blocked("Money orders and public errands are back in town.")
			return _check_send_home(player_state, config, config.send_small_amount_cents, &"mail")
		ACTION_SEND_LARGE:
			if not _is_at_town(player_state):
				return _blocked("Money orders and public errands are back in town.")
			return _check_send_home(player_state, config, config.send_large_amount_cents, &"telegraph")
		ACTION_SEND_SUPPORT:
			if not _is_at_town(player_state):
				return _blocked("Money orders and public errands are back in town.")
			return _check_send_home(
				player_state,
				config,
				int(context.get("amount_cents", config.send_small_amount_cents)),
				StringName(context.get("method_id", &"mail"))
			)
		ACTION_BUILD_FIRE:
			if not _is_at_camp(player_state):
				return _blocked("You need to be at camp to build a fire.")
			if _has_active_fire(player_state, config):
				return _blocked("A fire is already laid for tonight.")
			return _allowed()
		ACTION_TEND_FIRE:
			if not _is_at_camp(player_state):
				return _blocked("You need to be at camp to tend the fire.")
			if not _has_active_fire(player_state, config):
				return _blocked("Build a fire first.")
			if player_state.camp_fire_level >= 2:
				return _blocked("The fire is already tended as well as this prototype allows.")
			if config.tend_fire_scrap_cost > 0 and not player_state.inventory_state.has_item(&"scrap_tin", config.tend_fire_scrap_cost):
				return _blocked("You need a little scrap on hand to brace and feed the fire.")
			return _allowed()
		ACTION_GATHER_KINDLING:
			if not _is_at_camp(player_state):
				return _blocked("Kindling belongs at camp, not on the town board.")
			if player_state.camp_kindling_prepared:
				return _blocked("You have already gathered kindling for this camp.")
			if item_catalog == null or item_catalog.get_item(config.gather_kindling_item_id) == null:
				return _blocked("Kindling is not available in the item catalog.")
			return _allowed()
		ACTION_BREW_CAMP_COFFEE:
			return _check_brew_camp_coffee(player_state, config, item_catalog)
		ACTION_PREP_SLEEPING_SPOT:
			if not _is_at_camp(player_state):
				return _blocked("You need to be at camp to settle a sleeping spot.")
			if player_state.camp_sleeping_spot_ready:
				return _blocked("Your sleeping spot is already set for this rest.")
			return _allowed()
		ACTION_WASH_UP:
			if not _is_at_camp(player_state):
				return _blocked("Washing up belongs at camp for now.")
			if not player_state.has_potable_water(1):
				return _blocked("Boil potable water before washing up.")
			if player_state.camp_washed_up:
				return _blocked("You have already washed up for this camp.")
			return _allowed()
		ACTION_QUIET_COMFORT:
			if not _is_at_camp(player_state):
				return _blocked("Quiet comfort belongs at camp for now.")
			if player_state.camp_quiet_comfort_done:
				return _blocked("You have already taken a little quiet for this camp.")
			if not _has_quiet_comfort_source(player_state, config):
				return _blocked("You need a letter, a little tobacco, or a fire to settle yourself with.")
			return _allowed()
		ACTION_SLEEP_ROUGH:
			if not _is_at_camp(player_state):
				return _blocked("You need to leave town and reach camp before sleeping rough.")
			if _can_sleep_rough(player_state, config, context):
				return _allowed()
			return _blocked("You cannot bed down right now.")
		ACTION_USE_SELECTED:
			return _check_selected_usable(player_state, selected_stack_index)
		_:
			return _blocked("Unknown loop action.")


static func apply_action(player_state, config, item_catalog, action_id: StringName, selected_stack_index: int = -1, context: Dictionary = {}) -> Dictionary:
	_trace_apply_action("start", player_state, action_id, selected_stack_index)
	ensure_weekly_store_stock(player_state, config, item_catalog)
	var availability = can_perform_action(player_state, config, item_catalog, action_id, selected_stack_index, context)
	if not availability.get("enabled", false):
		var blocked_result = _result(false, String(availability.get("reason", "That action is unavailable.")))
		_trace_action_result("blocked", action_id, selected_stack_index, blocked_result)
		return blocked_result
	if _is_getting_ready_action(action_id):
		var ready_result = _apply_getting_ready_action_by_id(player_state, config, action_id)
		_trace_action_result("finish", action_id, selected_stack_index, ready_result)
		return ready_result

	var message := ""
	var result: Dictionary
	match action_id:
		ACTION_GO_TO_CAMP:
			_advance_awake_time(player_state, config, config.town_to_camp_travel_minutes)
			player_state.set_loop_location(LOCATION_CAMP)
			message = "You leave town for camp. The walk costs %s and the public day falls behind you." % _format_duration(config.town_to_camp_travel_minutes)
		ACTION_RETURN_TO_TOWN:
			_advance_awake_time(player_state, config, config.camp_to_town_travel_minutes)
			player_state.set_loop_location(LOCATION_TOWN)
			message = "You walk back toward town. The return costs %s." % _format_duration(config.camp_to_town_travel_minutes)
		ACTION_WAIT:
			_advance_awake_time(player_state, config, config.wait_action_minutes)
			message = "You let half an hour pass and watch the day move on."
		ACTION_SELL_SCRAP:
			player_state.inventory_state.remove_item(&"scrap_tin", config.sell_scrap_quantity)
			_advance_awake_time(player_state, config, config.sell_scrap_minutes)
			player_state.apply_money_delta(config.sell_scrap_pay_cents)
			message = "A dealer takes the scrap off your hands for a few coins."
		ACTION_BUY_STORE_STOCK:
			return _purchase_store_stock(player_state, config, item_catalog, StringName(context.get("store_id", &"")), selected_stack_index)
		ACTION_CRAFT_RECIPE:
			return _craft_recipe(player_state, config, item_catalog, StringName(context.get("recipe_id", &"")))
		ACTION_COOK_RECIPE:
			return _cook_recipe(player_state, config, item_catalog, StringName(context.get("recipe_id", &"")))
		ACTION_BUY_BREAD:
			return _purchase_item(player_state, config, item_catalog, config.bread_item_id, config.bread_price_cents, "You buy a loaf to keep yourself working.")
		ACTION_BUY_COFFEE:
			return _purchase_item(player_state, config, item_catalog, config.coffee_item_id, config.coffee_price_cents, "You buy hot coffee, fast and dear, best drunk before it cools.", config.prepared_food_purchase_minutes)
		ACTION_BUY_STEW:
			return _purchase_item(player_state, config, item_catalog, config.stew_item_id, config.stew_price_cents, "You pay extra for hot stew and a little dignity with it.", config.prepared_food_purchase_minutes)
		ACTION_BUY_TOBACCO:
			return _purchase_item(player_state, config, item_catalog, config.tobacco_item_id, config.tobacco_price_cents, "You buy a little tobacco to take the edge off the road.")
		ACTION_BUY_GROCERY_BEANS:
			return _purchase_item(player_state, config, item_catalog, config.grocery_beans_item_id, config.grocery_beans_price_cents, "You buy a can of beans, heavy but dependable.")
		ACTION_BUY_GROCERY_POTTED_MEAT:
			return _purchase_item(player_state, config, item_catalog, config.grocery_potted_meat_item_id, config.grocery_potted_meat_price_cents, "You buy a small tin of potted meat that will keep in the pack.")
		ACTION_BUY_COFFEE_GROUNDS:
			return _purchase_item(player_state, config, item_catalog, config.grocery_coffee_grounds_item_id, config.grocery_coffee_grounds_price_cents, "You buy loose coffee grounds for camp, cheaper than a counter cup.")
		ACTION_BUY_HARDWARE_MATCHES:
			return _purchase_item(player_state, config, item_catalog, config.hardware_matches_item_id, config.hardware_matches_price_cents, "You buy a match safe, small insurance against a wet night.")
		ACTION_BUY_HARDWARE_EMPTY_CAN:
			return _purchase_item(player_state, config, item_catalog, config.hardware_empty_can_item_id, config.hardware_empty_can_price_cents, "You buy a clean empty tin for boiling, patching, or camp use.")
		ACTION_BUY_HARDWARE_CORDAGE:
			return _purchase_item(player_state, config, item_catalog, config.hardware_cordage_item_id, config.hardware_cordage_price_cents, "You buy a short length of cordage for camp and repairs.")
		ACTION_SEND_SMALL:
			return _send_support(player_state, config, config.send_small_amount_cents, &"mail")
		ACTION_SEND_LARGE:
			return _send_support(player_state, config, config.send_large_amount_cents, &"telegraph")
		ACTION_SEND_SUPPORT:
			return _send_support(
				player_state,
				config,
				int(context.get("amount_cents", config.send_small_amount_cents)),
				StringName(context.get("method_id", &"mail"))
			)
		ACTION_BUILD_FIRE:
			_advance_awake_time(player_state, config, config.build_fire_minutes)
			player_state.set_camp_fire_level(1)
			player_state.apply_morale_delta(config.build_fire_morale_gain)
			FadingMeterSystemScript.record_social_grounding(player_state, 1)
			message = "You scrape together a campfire so the night will not cut so deep."
		ACTION_TEND_FIRE:
			if config.tend_fire_scrap_cost > 0:
				player_state.inventory_state.remove_item(&"scrap_tin", config.tend_fire_scrap_cost)
			_advance_awake_time(player_state, config, config.tend_fire_minutes)
			player_state.set_camp_fire_level(2)
			player_state.apply_morale_delta(config.tend_fire_morale_gain)
			FadingMeterSystemScript.record_social_grounding(player_state, 1)
			message = "You bank and brace the fire so it will hold better through the dark."
		ACTION_GATHER_KINDLING:
			var kindling_item = item_catalog.get_item(config.gather_kindling_item_id)
			_advance_awake_time(player_state, config, config.gather_kindling_minutes)
			player_state.apply_fatigue_tick(config.gather_kindling_fatigue_delta)
			player_state.apply_morale_delta(config.gather_kindling_morale_gain)
			player_state.mark_kindling_prepared()
			_add_item_to_inventory(player_state.inventory_state, kindling_item, config.gather_kindling_quantity)
			FadingMeterSystemScript.record_self_maintenance(player_state, 1)
			message = "You gather dry bits and splinters, the kind of small preparation that keeps a fire from becoming a fight."
		ACTION_BREW_CAMP_COFFEE:
			return _apply_brew_camp_coffee(player_state, config, item_catalog)
		ACTION_PREP_SLEEPING_SPOT:
			var with_bedroll = player_state.inventory_state.has_item(&"blanket_roll", 1)
			_advance_awake_time(player_state, config, config.lay_bedroll_minutes if with_bedroll else config.prepare_sleeping_spot_minutes)
			player_state.mark_sleeping_spot_ready(with_bedroll)
			player_state.apply_morale_delta(config.lay_bedroll_morale_gain if with_bedroll else config.prepare_sleeping_spot_morale_gain)
			FadingMeterSystemScript.record_self_maintenance(player_state, 1)
			message = "You lay out the bedroll and claim a place to sleep." if with_bedroll else "You scrape together a sleeping spot so the ground will take a little less out of you."
		ACTION_WASH_UP:
			_advance_awake_time(player_state, config, config.wash_up_minutes)
			player_state.mark_washed_up()
			player_state.passport_profile.hygiene = clampi(player_state.passport_profile.hygiene + config.wash_up_hygiene_gain, 0, 100)
			player_state.apply_warmth_delta(config.wash_up_warmth_delta)
			player_state.apply_morale_delta(config.wash_up_morale_gain)
			FadingMeterSystemScript.record_self_maintenance(player_state, 1)
			message = "You wash up as best you can and feel a little more fit to face morning."
		ACTION_QUIET_COMFORT:
			_advance_awake_time(player_state, config, config.quiet_comfort_minutes)
			player_state.mark_quiet_comfort_done()
			player_state.apply_morale_delta(config.quiet_comfort_morale_gain)
			player_state.passport_profile.fatigue = clampi(player_state.passport_profile.fatigue - config.quiet_comfort_fatigue_relief, 0, 100)
			FadingMeterSystemScript.record_social_grounding(player_state, 1)
			message = "You take a little quiet for yourself before sleep and let the road loosen its grip for a moment."
		ACTION_SLEEP_ROUGH:
			var sleep_hours = _resolve_sleep_hours(config, context)
			_apply_sleep_rough(player_state, config, context)
			message = "You bed down for %d hour%s and hope the rest leaves enough of you for tomorrow." % [sleep_hours, "" if sleep_hours == 1 else "s"]
		ACTION_USE_SELECTED:
			result = _consume_selected_stack(player_state, config, item_catalog, selected_stack_index)
			_trace_action_result("finish", action_id, selected_stack_index, result)
			return result
		_:
			result = _result(false, "Unknown loop action.")
			_trace_action_result("unknown", action_id, selected_stack_index, result)
			return result

	normalize_state(player_state, config)
	result = _result(true, message)
	_trace_action_result("finish", action_id, selected_stack_index, result)
	return result


static func can_perform_job(player_state, config, item_catalog, instance_id: StringName) -> Dictionary:
	if player_state == null or config == null:
		return _blocked("Loop state is unavailable.")
	if player_state.prototype_loop_status != &"ongoing":
		return _blocked("This run is already over.")
	if not _is_at_town(player_state):
		return _blocked("Town work boards are back in town.")

	var job = player_state.get_job_by_instance_id(instance_id)
	if job.is_empty():
		return _blocked("That job is no longer on the board.")
	if not _is_in_window(player_state.time_of_day_minutes, int(job.get("available_from_minutes", 0)), int(job.get("available_until_minutes", 1439))):
		return _blocked("That opening is not running at this hour.")
	if player_state.passport_profile.nutrition <= config.work_block_nutrition_threshold:
		return _blocked("You are too underfed to hold up under real work right now.")
	if player_state.passport_profile.fatigue >= config.work_block_fatigue_threshold:
		return _blocked("You are too worn down to take this work safely.")

	var appearance_check = can_meet_job_appearance(job, player_state, config)
	if not bool(appearance_check.get("enabled", false)):
		return appearance_check

	var required_item_id = StringName(job.get("required_item_id", &""))
	if required_item_id != &"" and not player_state.inventory_state.has_item(required_item_id, 1):
		return _blocked("You are missing what this job expects you to bring.")
	return _allowed()


static func apply_job(player_state, config, item_catalog, instance_id: StringName) -> Dictionary:
	var availability = can_perform_job(player_state, config, item_catalog, instance_id)
	if not availability.get("enabled", false):
		return _result(false, String(availability.get("reason", "That job is unavailable.")))

	var job = player_state.get_job_by_instance_id(instance_id)
	_advance_awake_time(player_state, config, int(job.get("duration_minutes", 0)))
	player_state.apply_nutrition_drain(int(job.get("nutrition_drain", max(int(job.get("hunger_delta", 0)), 0))))
	player_state.apply_fatigue_tick(int(job.get("fatigue_delta", 0)))
	player_state.apply_morale_delta(int(job.get("morale_delta", 0)))
	player_state.apply_hygiene_delta(int(job.get("hygiene_delta", 0)))
	player_state.apply_money_delta(int(job.get("pay_cents", 0)))
	FadingMeterSystemScript.record_job_completion(player_state, config, job)

	var reward_item_id = StringName(job.get("reward_item_id", &""))
	var reward_quantity = int(job.get("reward_item_quantity", 0))
	if reward_item_id != &"" and reward_quantity > 0 and item_catalog != null:
		var reward_item = item_catalog.get_item(reward_item_id)
		if reward_item != null:
			_add_item_to_inventory(player_state.inventory_state, reward_item, reward_quantity)

	var title = String(job.get("title", "Job"))
	player_state.remove_job_from_board(instance_id)
	normalize_state(player_state, config)
	return _result(true, "You get through %s and come away with what it offered." % title)


static func normalize_state(player_state, config) -> void:
	_prepare_state(player_state, config)
	_refresh_outcome(player_state, config)
	FadingMeterSystemScript.normalize_player_state(player_state, config)
	_ensure_job_board_for_current_day(player_state, config)


static func get_store_stock(player_state, config, item_catalog, store_id: StringName) -> Array:
	ensure_weekly_store_stock(player_state, config, item_catalog)
	if player_state == null or not player_state.has_method("get_store_stock"):
		return []
	return player_state.get_store_stock(store_id)


static func get_hobocraft_recipes() -> Array:
	return RecipeCatalogScript.get_recipes_by_category("hobocraft")


static func get_cooking_recipes() -> Array:
	return RecipeCatalogScript.get_recipes_by_category("cooking")


static func get_hobocraft_recipe_material_snapshot(player_state, recipe: Dictionary, item_catalog = null) -> Array:
	var inventory = _get_inventory_state(player_state)
	if inventory == null:
		return []
	var entries: Array = []
	for input in recipe.get("inputs", []):
		if not (input is Dictionary):
			continue
		var item_id := StringName(input.get("item_id", &""))
		entries.append(_build_recipe_snapshot_entry(
			item_id,
			inventory.count_item(item_id),
			max(int(input.get("quantity", 1)), 1),
			item_catalog
		))
	return entries


static func get_cooking_recipe_material_snapshot(player_state, config, recipe: Dictionary, item_catalog = null) -> Array:
	var inventory = _get_inventory_state(player_state)
	if inventory == null:
		return []
	var entries: Array = []
	var recipe_id := StringName(recipe.get("recipe_id", &""))
	match recipe_id:
		&"brew_camp_coffee":
			entries.append(_build_recipe_snapshot_entry(&"coffee_grounds", inventory.count_item(&"coffee_grounds"), 1, item_catalog))
			entries.append({
				"label": "Potable Water",
				"have": get_available_potable_water_units(player_state, config),
				"need": 1,
				"item_id": &"potable_water"
			})
			entries.append(_build_recipe_snapshot_entry(&"empty_can", inventory.count_item(&"empty_can"), 1, item_catalog))
		&"heat_beans":
			entries.append(_build_recipe_snapshot_entry(&"beans_can", inventory.count_item(&"beans_can"), 1, item_catalog))
		&"heat_potted_meat":
			entries.append(_build_recipe_snapshot_entry(&"potted_meat", inventory.count_item(&"potted_meat"), 1, item_catalog))
		&"mulligan_stew":
			entries.append({
				"label": "Potable Water",
				"have": get_available_potable_water_units(player_state, config),
				"need": 1,
				"item_id": &"potable_water"
			})
			entries.append({
				"label": "Staple Choice",
				"have": _count_item_group(inventory, MULLIGAN_STAPLE_ITEM_IDS),
				"need": 1,
				"item_id": &"mulligan_staple_choice"
			})
			entries.append({
				"label": "Body / Flavor Choice",
				"have": _count_item_group(inventory, MULLIGAN_BODY_ITEM_IDS),
				"need": 1,
				"item_id": &"mulligan_body_choice"
			})
		&"boil_water":
			entries.append({
				"label": "Water To Work",
				"have": int(player_state.camp_non_potable_water_units) + int(player_state.camp_potable_water_units),
				"need": 1,
				"item_id": &"water_to_work"
			})
	return entries


static func get_recipe_relevant_item_snapshot(player_state, recipe: Dictionary, is_cooking: bool, item_catalog = null) -> Array:
	var inventory = _get_inventory_state(player_state)
	if inventory == null:
		return []
	var relevant_ids: Array = []
	var recipe_id := StringName(recipe.get("recipe_id", &""))
	if is_cooking:
		if recipe_id == &"heat_beans" or recipe_id == &"heat_potted_meat" or recipe_id == &"mulligan_stew":
			relevant_ids.append_array(COOKING_HEAT_TOOL_ITEM_IDS)
			relevant_ids.append_array(CAN_OPENER_ITEM_IDS)
		elif recipe_id == &"brew_camp_coffee":
			relevant_ids.append(&"hot_coffee")
			relevant_ids.append_array(COOKING_HEAT_TOOL_ITEM_IDS)
	else:
		var output_item_id := StringName(recipe.get("output_item_id", &""))
		if output_item_id != &"":
			relevant_ids.append(output_item_id)

	var result: Array = []
	var seen := {}
	for item_id in relevant_ids:
		var resolved_item_id := StringName(item_id)
		if bool(seen.get(resolved_item_id, false)):
			continue
		seen[resolved_item_id] = true
		var count = inventory.count_item(resolved_item_id)
		if count <= 0:
			continue
		result.append({
			"item_id": resolved_item_id,
			"label": _get_recipe_snapshot_label(resolved_item_id, item_catalog),
			"count": count
		})
	return result


static func get_available_potable_water_units(player_state, config) -> int:
	var available := 0
	if player_state != null:
		available += int(player_state.camp_potable_water_units)
	var inventory = _get_inventory_state(player_state)
	if inventory == null or config == null:
		return available
	var water_item_id := StringName(config.brew_camp_coffee_water_item_id)
	if water_item_id != &"":
		available += inventory.count_item(water_item_id)
	return available


static func get_appearance_tier(player_state, config) -> Dictionary:
	if player_state == null or player_state.passport_profile == null or config == null:
		return _get_appearance_tier_entry(&"filthy_unkept", config)
	var hygiene = clampi(int(player_state.passport_profile.hygiene), 0, 100)
	var presentability = clampi(int(player_state.passport_profile.presentability), 0, 100)
	for rule in config.appearance_rules:
		if not (rule is Dictionary):
			continue
		if hygiene >= int(rule.get("min_hygiene", 0)) \
				and hygiene <= int(rule.get("max_hygiene", 100)) \
				and presentability >= int(rule.get("min_presentability", 0)) \
				and presentability <= int(rule.get("max_presentability", 100)):
			return _get_appearance_tier_entry(StringName(rule.get("tier_id", &"filthy_unkept")), config)
	return _get_appearance_tier_entry(&"filthy_unkept", config)


static func get_appearance_rank(tier_id: StringName, config) -> int:
	var tier = _get_appearance_tier_entry(tier_id, config)
	return int(tier.get("rank", 0))


static func get_appearance_label(tier_id: StringName, config) -> String:
	var tier = _get_appearance_tier_entry(tier_id, config)
	return String(tier.get("label", String(tier_id).replace("_", " ").capitalize()))


static func can_meet_job_appearance(job: Dictionary, player_state, config) -> Dictionary:
	if job.is_empty() or config == null:
		return _allowed()
	var current_tier = get_appearance_tier(player_state, config)
	var current_rank = int(current_tier.get("rank", 0))
	var current_label = String(current_tier.get("label", "Unkept"))
	var min_tier_id = StringName(job.get("min_appearance_tier", &""))
	if min_tier_id != &"":
		var min_rank = get_appearance_rank(min_tier_id, config)
		if current_rank < min_rank:
			return _blocked("Your appearance reads as %s. This work expects at least %s." % [
				current_label,
				get_appearance_label(min_tier_id, config)
			])
	var max_tier_id = StringName(job.get("max_appearance_tier", &""))
	if max_tier_id != &"":
		var max_rank = get_appearance_rank(max_tier_id, config)
		if current_rank > max_rank:
			return _blocked("Your appearance reads as %s. This opening is being held for men in rougher straits." % current_label)
	return _allowed()


static func ensure_weekly_store_stock(player_state, config, item_catalog) -> void:
	if player_state == null or config == null:
		return
	var week_index = _get_store_week_index(player_state, config)
	if player_state.store_stock_week_index == week_index \
			and not player_state.grocery_store_stock.is_empty() \
			and not player_state.hardware_store_stock.is_empty():
		return
	var grocery_stock = _generate_store_stock(STORE_GROCERY, StoreInventoryCatalogScript.get_store_pool(STORE_GROCERY), week_index, config, item_catalog)
	var hardware_stock = _generate_store_stock(STORE_HARDWARE, StoreInventoryCatalogScript.get_store_pool(STORE_HARDWARE), week_index, config, item_catalog)
	player_state.set_store_stock(week_index, grocery_stock, hardware_stock)


static func _get_store_week_index(player_state, config) -> int:
	return _get_store_week_index_for_day(player_state.current_day, config)


static func _generate_store_stock(store_id: StringName, pool: Array, week_index: int, config, item_catalog) -> Array:
	var valid_pool: Array = []
	for entry in pool:
		if not (entry is Dictionary):
			continue
		var item_id = StringName(entry.get("item_id", &""))
		if item_id == &"":
			continue
		if item_catalog != null and item_catalog.get_item(item_id) == null:
			continue
		valid_pool.append(entry)
	if valid_pool.is_empty():
		return []

	var rng = RandomNumberGenerator.new()
	rng.seed = int(config.store_stock_seed) + int(week_index * 7919) + (101 if store_id == STORE_GROCERY else 509)
	var target_count = clampi(rng.randi_range(int(config.min_store_stock_items), int(config.max_store_stock_items)), 4, 8)
	target_count = min(target_count, valid_pool.size())

	var stock: Array = []
	var used_item_ids: Array = []
	for required_item_id in _get_required_store_stock_item_ids(store_id):
		if stock.size() >= target_count:
			break
		var required_entry = _find_stock_pool_entry(valid_pool, StringName(required_item_id))
		if required_entry.is_empty():
			continue
		var required_quality_tier = _pick_store_quality_tier(required_entry, rng)
		stock.append(_make_store_stock_entry(store_id, required_entry, required_quality_tier, week_index))
		used_item_ids.append(StringName(required_item_id))
	while stock.size() < target_count:
		var picked = _pick_weighted_stock_entry(valid_pool, used_item_ids, rng)
		if picked.is_empty():
			break
		var quality_tier = _pick_store_quality_tier(picked, rng)
		stock.append(_make_store_stock_entry(store_id, picked, quality_tier, week_index))
		used_item_ids.append(StringName(picked.get("item_id", &"")))
	return stock


static func _get_required_store_stock_item_ids(store_id: StringName) -> Array:
	return StoreInventoryCatalogScript.get_required_stock_item_ids(store_id)


static func _find_stock_pool_entry(pool: Array, item_id: StringName) -> Dictionary:
	for entry in pool:
		if entry is Dictionary and StringName(entry.get("item_id", &"")) == item_id:
			return entry.duplicate(true)
	return {}


static func _make_store_stock_entry(store_id: StringName, pool_entry: Dictionary, quality_tier: int, week_index: int) -> Dictionary:
	return {
		"store_id": store_id,
		"item_id": StringName(pool_entry.get("item_id", &"")),
		"price_cents": _price_for_quality(int(pool_entry.get("base_price_cents", 1)), quality_tier),
		"quality_tier": quality_tier,
		"quality_score": float(quality_tier),
		"week_index": week_index
	}


static func _pick_weighted_stock_entry(pool: Array, used_item_ids: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total_weight := 0
	var candidates: Array = []
	for entry in pool:
		var item_id = StringName(entry.get("item_id", &""))
		if used_item_ids.has(item_id):
			continue
		candidates.append(entry)
		total_weight += int(entry.get("weight", 1))
	if candidates.is_empty() or total_weight <= 0:
		return {}
	var roll = rng.randi_range(1, total_weight)
	var running := 0
	for entry in candidates:
		running += int(entry.get("weight", 1))
		if roll <= running:
			return entry.duplicate(true)
	return candidates[0].duplicate(true)


static func _pick_store_quality_tier(pool_entry: Dictionary, rng: RandomNumberGenerator) -> int:
	var min_quality = clampi(int(pool_entry.get("min_quality", ItemDefinitionScript.QualityTier.POOR)), ItemDefinitionScript.QualityTier.POOR, ItemDefinitionScript.QualityTier.LEGENDARY)
	var max_quality = clampi(int(pool_entry.get("max_quality", ItemDefinitionScript.QualityTier.GOOD)), min_quality, ItemDefinitionScript.QualityTier.LEGENDARY)
	var roll = rng.randi_range(1, 100)
	var tier = ItemDefinitionScript.QualityTier.POOR
	if roll > 88:
		tier = ItemDefinitionScript.QualityTier.GOOD
	elif roll > 35:
		tier = ItemDefinitionScript.QualityTier.COMMON
	return clampi(tier, min_quality, max_quality)


static func _price_for_quality(base_price_cents: int, quality_tier: int) -> int:
	var multiplier = 0.75
	match quality_tier:
		ItemDefinitionScript.QualityTier.POOR:
			multiplier = 0.75
		ItemDefinitionScript.QualityTier.COMMON:
			multiplier = 1.0
		ItemDefinitionScript.QualityTier.GOOD:
			multiplier = 1.25
		ItemDefinitionScript.QualityTier.SUPERIOR:
			multiplier = 1.6
		_:
			multiplier = 2.0
	return max(int(round(float(max(base_price_cents, 1)) * multiplier)), 1)


static func _purchase_item(player_state, config, item_catalog, item_id: StringName, price_cents: int, success_message: String, minutes: int = -1) -> Dictionary:
	var item = item_catalog.get_item(item_id)
	if item == null:
		return _result(false, "The supply could not be found in the item catalog.")
	player_state.apply_money_delta(-price_cents)
	_advance_awake_time(player_state, config, config.buy_supply_minutes if minutes < 0 else minutes)
	var rejected = _add_item_to_inventory(player_state.inventory_state, item, 1)
	if rejected > 0:
		player_state.apply_money_delta(price_cents)
		return _result(false, "You cannot carry that purchase right now.")
	normalize_state(player_state, config)
	return _result(true, success_message)


static func _purchase_store_stock(player_state, config, item_catalog, store_id: StringName, stock_index: int) -> Dictionary:
	var stock_entry = _get_store_stock_entry(player_state, store_id, stock_index)
	if stock_entry.is_empty():
		return _result(false, "That store shelf is empty now.")
	var item_id = StringName(stock_entry.get("item_id", &""))
	var item = item_catalog.get_item(item_id)
	if item == null:
		return _result(false, "That store item is missing from the catalog.")
	var price_cents = int(stock_entry.get("price_cents", 0))
	var quality_tier = clampi(int(stock_entry.get("quality_tier", int(item.quality_tier))), ItemDefinitionScript.QualityTier.POOR, ItemDefinitionScript.QualityTier.LEGENDARY)
	var quality_score = clampf(float(stock_entry.get("quality_score", float(quality_tier))), float(ItemDefinitionScript.QualityTier.POOR), float(ItemDefinitionScript.QualityTier.LEGENDARY))

	player_state.apply_money_delta(-price_cents)
	_advance_awake_time(player_state, config, config.buy_supply_minutes)
	var rejected = _add_item_to_inventory_with_quality(player_state.inventory_state, item, 1, quality_tier, quality_score)
	if rejected > 0:
		player_state.apply_money_delta(price_cents)
		return _result(false, "You cannot carry that purchase right now.")
	normalize_state(player_state, config)
	return _result(true, "You buy %s %s for %s." % [
		item.get_quality_name(quality_tier),
		item.display_name,
		_format_cents(price_cents)
	])


static func _craft_recipe(player_state, config, item_catalog, recipe_id: StringName) -> Dictionary:
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return _result(false, "That recipe is not available at camp.")
	var output_item_id = StringName(recipe.get("output_item_id", &""))
	var output_item = item_catalog.get_item(output_item_id)
	if output_item == null:
		return _result(false, "That craft output is missing from the item catalog.")
	var output_quantity = max(int(recipe.get("output_quantity", 1)), 1)

	var input_quality_entries = _collect_recipe_input_quality_entries(player_state.inventory_state, recipe)
	for input in recipe.get("inputs", []):
		if not (input is Dictionary):
			continue
		player_state.inventory_state.remove_item(StringName(input.get("item_id", &"")), max(int(input.get("quantity", 1)), 1))
	_advance_awake_time(player_state, config, config.hobocraft_action_minutes)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(config.store_stock_seed) + int(player_state.current_day * 3571) + int(String(recipe_id).hash())
	var output_quality = ItemQualityRulesScript.calculate_output_quality(input_quality_entries, rng)
	var output_uses = _get_crafted_tool_uses(output_item, output_quality, recipe)
	var rejected = _add_item_to_inventory_with_quality(player_state.inventory_state, output_item, output_quantity, output_quality, float(output_quality), output_uses)
	if rejected > 0:
		return _result(false, "The finished piece had nowhere to go.")
	FadingMeterSystemScript.record_self_maintenance(player_state, 1)
	normalize_state(player_state, config)
	return _result(true, "You make %s %s from what the road and stores could spare." % [
		output_item.get_quality_name(output_quality),
		output_item.display_name
	])


static func _cook_recipe(player_state, config, item_catalog, recipe_id: StringName) -> Dictionary:
	match recipe_id:
		&"boil_water":
			return _apply_fetch_or_boil_water(player_state, config)
		&"brew_camp_coffee":
			return _apply_brew_camp_coffee(player_state, config, item_catalog)
		&"heat_beans":
			return _cook_and_eat_item(player_state, config, item_catalog, &"beans_can", 15, 6, 2, "You heat beans over the coals and eat them warm, with an empty tin left for later.")
		&"heat_potted_meat":
			return _cook_and_eat_item(player_state, config, item_catalog, &"potted_meat", 12, 5, 2, "You warm the potted meat just enough to make a poor meal easier to take.")
		&"mulligan_stew":
			return _apply_mulligan_stew(player_state, config, item_catalog)
	return _result(false, "That cooking recipe has no rule handler.")


static func _apply_brew_camp_coffee(player_state, config, item_catalog) -> Dictionary:
	player_state.inventory_state.remove_item(config.brew_camp_coffee_input_item_id, 1)
	if player_state.inventory_state.has_item(config.brew_camp_coffee_water_item_id, 1):
		player_state.inventory_state.remove_item(config.brew_camp_coffee_water_item_id, 1)
	else:
		player_state.consume_potable_water(1)
	_advance_awake_time(player_state, config, config.brew_camp_coffee_minutes)
	player_state.apply_morale_delta(config.brew_camp_coffee_morale_gain)
	player_state.mark_camp_coffee_brewed()
	_add_item_to_inventory(player_state.inventory_state, item_catalog.get_item(config.brew_camp_coffee_output_item_id), 1)
	FadingMeterSystemScript.record_self_maintenance(player_state, 1)
	normalize_state(player_state, config)
	return _result(true, "You boil camp coffee over the fire. It costs time and fuss, not counter money.")


static func _cook_and_eat_item(player_state, config, item_catalog, item_id: StringName, minutes: int, warmth_gain: int, morale_gain: int, message: String) -> Dictionary:
	var item = item_catalog.get_item(item_id) if item_catalog != null else null
	if item == null:
		return _result(false, "That cooking item is missing from the catalog.")
	var source_zone = _get_first_item_zone(player_state.inventory_state, item_id)
	if player_state.inventory_state.remove_item(item_id, 1) <= 0:
		return _result(false, "That food is not in your pack.")
	var tool_result = _apply_cooking_tool_wear(player_state)
	_advance_awake_time(player_state, config, minutes)
	var tool_modifier = float(tool_result.get("efficiency", 1.0))
	player_state.apply_item_use_effects(
		item_id,
		item.nutrition_value,
		item.fatigue_relief,
		max(item.warmth_value, roundi(float(warmth_gain) * tool_modifier)),
		item.hygiene_value,
		item.presentability_value,
		item.morale_value + max(1, roundi(float(morale_gain) * tool_modifier)),
		true
	)
	_spawn_use_outputs(player_state.inventory_state, item_catalog, item, source_zone)
	FadingMeterSystemScript.record_item_consumed(player_state, item)
	FadingMeterSystemScript.record_self_maintenance(player_state, 1)
	normalize_state(player_state, config)
	return _result(true, "%s %s" % [message, String(tool_result.get("message", "")).strip_edges()])


static func _apply_mulligan_stew(player_state, config, item_catalog) -> Dictionary:
	if item_catalog == null:
		return _result(false, "Cooking catalog is unavailable.")
	var staple_id = _find_first_available_cooking_input(player_state, MULLIGAN_STAPLE_ITEM_IDS)
	var body_id = _find_first_available_cooking_input(player_state, MULLIGAN_BODY_ITEM_IDS)
	if staple_id == &"" or body_id == &"":
		return _result(false, "Mulligan stew is missing something to stretch.")
	if player_state.inventory_state.has_item(config.brew_camp_coffee_water_item_id, 1):
		player_state.inventory_state.remove_item(config.brew_camp_coffee_water_item_id, 1)
	else:
		player_state.consume_potable_water(1)
	var staple_item = item_catalog.get_item(staple_id)
	var body_item = item_catalog.get_item(body_id)
	var staple_zone = _get_first_item_zone(player_state.inventory_state, staple_id)
	var body_zone = _get_first_item_zone(player_state.inventory_state, body_id)
	player_state.inventory_state.remove_item(staple_id, 1)
	if body_id != staple_id:
		player_state.inventory_state.remove_item(body_id, 1)
	var tool_result = _apply_cooking_tool_wear(player_state)
	_advance_awake_time(player_state, config, 40)
	var tool_modifier = float(tool_result.get("efficiency", 1.0))
	var nutrition_gain = max(38, int(staple_item.nutrition_value if staple_item != null else 0) + int(body_item.nutrition_value if body_item != null else 0) + 6)
	player_state.apply_item_use_effects(&"mulligan_stew", nutrition_gain, 0, roundi(10.0 * tool_modifier), 0, 0, max(2, roundi(5.0 * tool_modifier)), true)
	_spawn_use_outputs(player_state.inventory_state, item_catalog, staple_item, staple_zone)
	if body_id != staple_id:
		_spawn_use_outputs(player_state.inventory_state, item_catalog, body_item, body_zone)
	FadingMeterSystemScript.record_self_maintenance(player_state, 1)
	normalize_state(player_state, config)
	return _result(true, "You stretch water, staples, and a little support into mulligan stew. It is not plenty, but it is hot. %s" % String(tool_result.get("message", "")).strip_edges())


static func _send_support(player_state, config, amount_cents: int, method_id: StringName) -> Dictionary:
	var method = _get_support_send_method(config, method_id)
	if method.is_empty():
		return _result(false, "That way of sending money is not available in this town.")
	var fee_cents = max(int(method.get("fee_cents", 0)), 0)
	var delay_days = max(int(method.get("delivery_delay_days", 0)), 0)
	var total_cost = max(amount_cents, 0) + fee_cents
	var sent_day = player_state.current_day
	player_state.apply_money_delta(-total_cost)
	_advance_awake_time(player_state, config, config.send_support_minutes)
	player_state.record_support_committed(amount_cents)
	var arrival_day = sent_day + delay_days
	var method_name = String(method.get("display_name", String(method_id).capitalize()))
	if delay_days <= 0:
		player_state.record_support_delivered(amount_cents, method_id, sent_day, player_state.current_day)
		player_state.apply_morale_delta(config.send_support_morale_gain)
		FadingMeterSystemScript.record_support_sent(player_state, config, amount_cents)
		normalize_state(player_state, config)
		return _result(true, "You wire %s home through the %s. The fee hurts, but it counts today." % [_format_cents(amount_cents), method_name])
	player_state.add_pending_support_delivery({
		"amount_cents": amount_cents,
		"fee_cents": fee_cents,
		"method_id": method_id,
		"display_name": method_name,
		"sent_day": sent_day,
		"arrival_day": arrival_day
	})
	normalize_state(player_state, config)
	return _result(true, "You mail %s home through the %s. It should count after it arrives on Day %d." % [_format_cents(amount_cents), method_name, arrival_day])


static func _consume_selected_stack(player_state, config, item_catalog, selected_stack_index: int) -> Dictionary:
	var stack = player_state.inventory_state.get_stack_at(selected_stack_index)
	if stack == null or stack.item == null or not stack.item.can_use():
		var missing_result = _result(false, "Select a usable item first.")
		_trace_use_selected("blocked", selected_stack_index, "", 0, "", false, player_state, missing_result)
		return missing_result

	var item = stack.item
	var source_zone = StringName(stack.carry_zone)
	var item_id = item.item_id
	var item_name = item.display_name
	var starting_quantity = stack.quantity
	var removes_one: bool = item.can_consume()
	var use_message = "You use %s and keep yourself moving." % item_name

	_advance_awake_time(player_state, config, config.item_use_minutes)
	if _item_has_player_effects(item):
		player_state.apply_item_use_effects(
			item_id,
			item.nutrition_value,
			item.fatigue_relief,
			item.warmth_value,
			item.hygiene_value,
			item.presentability_value,
			item.morale_value,
			item.can_consume() and (item.food_type != ItemDefinitionScript.FoodType.NONE or item.nutrition_value > 0)
		)
	if item.can_consume() or int(item.fading_comfort_load) > 0:
		FadingMeterSystemScript.record_item_consumed(player_state, item)

	match item.use_result_type:
		ItemDefinitionScript.UseResultType.CONSUME_DESTROY:
			removes_one = true
		ItemDefinitionScript.UseResultType.CONSUME_LEAVE_RESIDUE:
			removes_one = true
			use_message = "You use %s and keep what is left." % item_name
		ItemDefinitionScript.UseResultType.USE_REDUCE_QUANTITY:
			removes_one = true
		ItemDefinitionScript.UseResultType.USE_TRANSFORM:
			removes_one = true
			use_message = "You use %s and it changes into something useful." % item_name
		ItemDefinitionScript.UseResultType.READ_PERSISTENT:
			removes_one = false
			use_message = "You read %s and keep it close." % item_name
		ItemDefinitionScript.UseResultType.NONE:
			if item.can_read() and not item.can_consume():
				removes_one = false
				use_message = "You read %s and keep it close." % item_name
	_trace_use_selected("before", selected_stack_index, String(item_id), starting_quantity, String(source_zone), removes_one, player_state, {})

	if removes_one:
		var remove_result = player_state.inventory_state.remove_quantity_from_stack(selected_stack_index, 1)
		_trace_use_selected("remove", selected_stack_index, String(item_id), starting_quantity, String(source_zone), removes_one, player_state, remove_result)
		if not bool(remove_result.get("success", false)):
			var removal_failed_result = _result(false, "Use failed because the selected stack could not be consumed.")
			removal_failed_result["remove_result_message"] = String(remove_result.get("message", ""))
			removal_failed_result["resolved_item_id"] = String(item_id)
			_trace_use_selected("remove_failed", selected_stack_index, String(item_id), starting_quantity, String(source_zone), removes_one, player_state, removal_failed_result)
			return removal_failed_result
		var output_count = _spawn_use_outputs(player_state.inventory_state, item_catalog, item, source_zone)
		if output_count > 0:
			use_message = "%s %s remains." % [use_message, item_catalog.get_item(item.get_use_output_item_id()).display_name]

	if player_state.has_method("sync_equipped_items_with_hands"):
		player_state.sync_equipped_items_with_hands()
	normalize_state(player_state, config)
	var result = _result(true, use_message)
	result["resolved_item_id"] = String(item_id)
	var remaining_quantity = player_state.inventory_state.count_item(item_id)
	_trace_use_selected("after", selected_stack_index, String(item_id), remaining_quantity, String(source_zone), removes_one, player_state, result)
	return result


static func _apply_getting_ready_action_by_id(player_state, config, action_id: StringName) -> Dictionary:
	match action_id:
		ACTION_READY_FETCH_WATER:
			return _apply_fetch_or_boil_water(player_state, config)
		ACTION_READY_WASH_BODY:
			return _apply_getting_ready_action(
				player_state,
				config,
				config.ready_wash_body_minutes,
				config.ready_wash_body_hygiene_gain,
				config.ready_wash_body_presentability_gain,
				config.ready_wash_body_fatigue_delta,
				config.ready_wash_body_morale_gain,
				config.ready_wash_body_warmth_delta,
				"You wash as much of the road off your body as the place and water allow."
			)
		ACTION_READY_WASH_FACE_HANDS:
			return _apply_getting_ready_action(
				player_state,
				config,
				config.ready_wash_face_hands_minutes,
				config.ready_wash_face_hands_hygiene_gain,
				config.ready_wash_face_hands_presentability_gain,
				config.ready_wash_face_hands_fatigue_delta,
				config.ready_wash_face_hands_morale_gain,
				0,
				"You wash your face and hands, enough to meet another man without looking away first."
			)
		ACTION_READY_SHAVE:
			return _apply_getting_ready_action(
				player_state,
				config,
				config.ready_shave_minutes,
				config.ready_shave_hygiene_gain,
				config.ready_shave_presentability_gain,
				config.ready_shave_fatigue_delta,
				config.ready_shave_morale_gain,
				0,
				"You shave as best you can and put a little order back into your face."
			)
		ACTION_READY_COMB_GROOM:
			return _apply_getting_ready_action(
				player_state,
				config,
				config.ready_comb_groom_minutes,
				config.ready_comb_groom_hygiene_gain,
				config.ready_comb_groom_presentability_gain,
				config.ready_comb_groom_fatigue_delta,
				config.ready_comb_groom_morale_gain,
				0,
				"You comb and settle yourself, small work that helps you look like you are still trying."
			)
		ACTION_READY_AIR_OUT_CLOTHES:
			return _apply_getting_ready_action(
				player_state,
				config,
				config.ready_air_out_clothes_minutes,
				config.ready_air_out_clothes_hygiene_gain,
				config.ready_air_out_clothes_presentability_gain,
				config.ready_air_out_clothes_fatigue_delta,
				config.ready_air_out_clothes_morale_gain,
				config.ready_air_out_clothes_warmth_delta,
				"You air out your clothes and shake loose some of the day's stale grit."
			)
		ACTION_READY_BRUSH_CLOTHES:
			return _apply_getting_ready_action(
				player_state,
				config,
				config.ready_brush_clothes_minutes,
				config.ready_brush_clothes_hygiene_gain,
				config.ready_brush_clothes_presentability_gain,
				config.ready_brush_clothes_fatigue_delta,
				config.ready_brush_clothes_morale_gain,
				0,
				"You brush the worst dust from your coat and cuffs, enough to look more ready for a foreman."
			)
	return _result(false, "Unknown getting-ready action.")


static func _apply_fetch_or_boil_water(player_state, config) -> Dictionary:
	if player_state.camp_non_potable_water_units <= 0:
		_advance_awake_time(player_state, config, config.ready_fetch_water_minutes)
		player_state.add_non_potable_water(config.ready_fetch_water_quantity)
		player_state.apply_morale_delta(config.ready_fetch_water_morale_gain)
		FadingMeterSystemScript.record_self_maintenance(player_state, 1)
		normalize_state(player_state, config)
		return _result(true, "You fetch water for camp. It is not fit for washing yet; boil it before getting ready.")

	_advance_awake_time(player_state, config, config.ready_boil_water_minutes)
	var converted = player_state.boil_camp_water(config.ready_fetch_water_quantity)
	player_state.apply_morale_delta(config.ready_fetch_water_morale_gain)
	FadingMeterSystemScript.record_self_maintenance(player_state, 1)
	normalize_state(player_state, config)
	return _result(true, "You boil %d water for morning washing and camp coffee." % converted)


static func _apply_getting_ready_action(player_state, config, minutes: int, hygiene_gain: int, presentability_gain: int, fatigue_delta: int, morale_gain: int, warmth_delta: int, message: String) -> Dictionary:
	var before_state = _capture_rule_state(player_state, -1)
	_advance_awake_time(player_state, config, minutes)
	player_state.apply_hygiene_delta(hygiene_gain)
	player_state.apply_presentability_delta(presentability_gain)
	if fatigue_delta > 0:
		player_state.apply_fatigue_tick(fatigue_delta)
	player_state.apply_morale_delta(morale_gain)
	if warmth_delta != 0:
		player_state.apply_warmth_delta(warmth_delta)
	FadingMeterSystemScript.record_self_maintenance(player_state, 1)
	normalize_state(player_state, config)
	var result = _result(true, message)
	_trace_getting_ready_state(message, before_state, _capture_rule_state(player_state, -1), result)
	return result


static func _item_has_player_effects(item) -> bool:
	return item != null and (
		item.nutrition_value != 0
		or item.fatigue_relief != 0
		or item.warmth_value != 0
		or item.hygiene_value != 0
		or item.presentability_value != 0
		or item.morale_value != 0
	)


static func _trace_apply_action(phase: String, player_state, action_id: StringName, selected_stack_index: int) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	var stack_summary = _describe_stack_for_trace(player_state, selected_stack_index)
	print("[SurvivalLoopRules.trace] phase=", phase,
		" action=", String(action_id),
		" selected_stack=", selected_stack_index,
		" item=", stack_summary.get("item_id", ""),
		" zone=", stack_summary.get("zone", ""),
		" quantity=", int(stack_summary.get("quantity", 0)))


static func _trace_action_result(phase: String, action_id: StringName, selected_stack_index: int, result: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	print("[SurvivalLoopRules.trace] phase=", phase,
		" action=", String(action_id),
		" selected_stack=", selected_stack_index,
		" success=", bool(result.get("success", false)),
		" state_changed=", bool(result.get("state_changed", result.get("success", false))),
		" resolved_item_id=", String(result.get("resolved_item_id", "")),
		" message=", String(result.get("message", "")))


static func _trace_use_selected(phase: String, selected_stack_index: int, item_id: String, quantity: int, zone: String, removes_one: bool, player_state, result: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	var state_snapshot = _capture_rule_state(player_state, selected_stack_index)
	print("[SurvivalLoopRules.use_selected] phase=", phase,
		" selected_stack=", selected_stack_index,
		" item=", item_id,
		" zone=", zone,
		" quantity=", quantity,
		" removes_one=", removes_one,
		" remove_success=", bool(result.get("success", false)),
		" message=", String(result.get("message", "")),
		" money_cents=", int(state_snapshot.get("money_cents", 0)),
		" time=", int(state_snapshot.get("time", 0)),
		" selected_item_after=", String(state_snapshot.get("selected_item_id", "")),
		" selected_quantity_after=", int(state_snapshot.get("selected_stack_quantity", 0)))


static func _trace_getting_ready_state(label: String, before_state: Dictionary, after_state: Dictionary, result: Dictionary) -> void:
	if not TRACE_LOGGING_ENABLED:
		return
	print("[SurvivalLoopRules.ready] action=", label,
		" success=", bool(result.get("success", false)),
		" hygiene_before=", int(before_state.get("hygiene", 0)),
		" hygiene_after=", int(after_state.get("hygiene", 0)),
		" presentability_before=", int(before_state.get("presentability", 0)),
		" presentability_after=", int(after_state.get("presentability", 0)),
		" fatigue_before=", int(before_state.get("fatigue", 0)),
		" fatigue_after=", int(after_state.get("fatigue", 0)),
		" morale_before=", int(before_state.get("morale", 0)),
		" morale_after=", int(after_state.get("morale", 0)),
		" warmth_before=", int(before_state.get("warmth", 0)),
		" warmth_after=", int(after_state.get("warmth", 0)),
		" time_before=", int(before_state.get("time", 0)),
		" time_after=", int(after_state.get("time", 0)),
		" message=", String(result.get("message", "")))


static func _describe_stack_for_trace(player_state, stack_index: int) -> Dictionary:
	if player_state == null or player_state.inventory_state == null or stack_index < 0:
		return {}
	var stack = player_state.inventory_state.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return {}
	return {
		"item_id": String(stack.item.item_id),
		"zone": String(stack.carry_zone),
		"quantity": stack.quantity
	}


static func _capture_rule_state(player_state, selected_stack_index: int) -> Dictionary:
	if player_state == null:
		return {}
	var snapshot := {
		"time": int(player_state.time_of_day_minutes),
		"money_cents": int(player_state.money_cents),
		"selected_item_id": "",
		"selected_stack_quantity": 0
	}
	if player_state.passport_profile != null:
		snapshot["hygiene"] = int(player_state.passport_profile.hygiene)
		snapshot["presentability"] = int(player_state.passport_profile.presentability)
		snapshot["fatigue"] = int(player_state.passport_profile.fatigue)
		snapshot["morale"] = int(player_state.passport_profile.morale)
		snapshot["warmth"] = int(player_state.passport_profile.warmth)
	if player_state.inventory_state != null:
		var stack = player_state.inventory_state.get_stack_at(selected_stack_index)
		if stack != null and stack.item != null:
			snapshot["selected_item_id"] = String(stack.item.item_id)
			snapshot["selected_stack_quantity"] = int(stack.quantity)
	return snapshot


static func _spawn_use_outputs(inventory, item_catalog, source_item, source_zone: StringName) -> int:
	if inventory == null or item_catalog == null or source_item == null:
		return 0
	var output_item_id = source_item.get_use_output_item_id()
	if output_item_id == &"":
		return 0
	var output_item = item_catalog.get_item(output_item_id)
	if output_item == null:
		return 0
	var output_quantity = source_item.get_use_output_quantity()
	var remaining = inventory.add_item(output_item, output_quantity, source_zone)
	if remaining > 0:
		remaining = _add_item_to_inventory(inventory, output_item, remaining)
	return output_quantity - remaining


static func get_sleep_warmth_breakdown(player_state, config) -> Dictionary:
	if player_state == null or config == null:
		return {}
	var fire_level = _get_active_camp_fire_level(player_state, config)
	var warmth_change = -config.sleep_rough_warmth_loss
	var contributors: Array = [
		{"label": "overnight cold", "value": -config.sleep_rough_warmth_loss}
	]

	if fire_level <= 0:
		warmth_change -= config.no_fire_extra_warmth_loss
		contributors.append({"label": "no fire", "value": -config.no_fire_extra_warmth_loss})
	elif fire_level == 1:
		warmth_change += config.fire_warmth_buffer
		contributors.append({"label": "fire", "value": config.fire_warmth_buffer})
	else:
		warmth_change += config.tended_fire_warmth_buffer
		contributors.append({"label": "tended fire", "value": config.tended_fire_warmth_buffer})

	if player_state.camp_sleeping_spot_ready:
		warmth_change += config.sleeping_spot_warmth_buffer
		contributors.append({"label": "sleeping spot", "value": config.sleeping_spot_warmth_buffer})
	if player_state.camp_bedroll_laid:
		warmth_change += config.laid_bedroll_warmth_buffer
		contributors.append({"label": "bedroll", "value": config.laid_bedroll_warmth_buffer})
		warmth_change += config.blanket_warmth_buffer
		contributors.append({"label": "blanket", "value": config.blanket_warmth_buffer})
	return {
		"fire_level": fire_level,
		"contributors": contributors,
		"net_warmth_change": warmth_change
	}


static func _calculate_sleep_rest_result(player_state, config, context: Dictionary = {}) -> Dictionary:
	var fire_level = _get_active_camp_fire_level(player_state, config)
	var warmth_breakdown = get_sleep_warmth_breakdown(player_state, config)
	var sleep_hours = _resolve_sleep_hours(config, context)
	var duration_ratio = float(sleep_hours) / float(max(config.sleep_rough_hours, 1))
	var night_ratio = _calculate_sleep_night_ratio(player_state, config, sleep_hours * 60)
	var fatigue_recovery = int(round(config.sleep_rough_fatigue_recovery * duration_ratio * lerpf(0.72, 1.0, night_ratio)))
	var morale_change = int(round(config.sleep_rough_morale * duration_ratio))
	var sleep_quality := 0
	if fire_level <= 0:
		morale_change += config.no_fire_extra_morale_penalty
		sleep_quality -= 1
	elif fire_level == 1:
		fatigue_recovery += config.fire_fatigue_bonus
		morale_change += config.fire_morale_bonus
		sleep_quality += 1
	else:
		fatigue_recovery += config.tended_fire_fatigue_bonus
		morale_change += config.tended_fire_morale_bonus
		sleep_quality += 2
	if player_state.camp_sleeping_spot_ready:
		fatigue_recovery += config.sleeping_spot_fatigue_bonus
		sleep_quality += 1
	if player_state.camp_bedroll_laid:
		fatigue_recovery += config.laid_bedroll_fatigue_bonus
		fatigue_recovery += config.blanket_fatigue_bonus
		sleep_quality += 1
	if player_state.camp_washed_up:
		morale_change += 1
		sleep_quality += 1
	if player_state.camp_quiet_comfort_done:
		morale_change += 2
		sleep_quality += 1

	if player_state.passport_profile.warmth <= config.low_warmth_threshold:
		fatigue_recovery = max(fatigue_recovery - config.low_warmth_extra_fatigue, 0)
		morale_change += config.low_warmth_morale_penalty
		sleep_quality -= 1
	if night_ratio >= 0.5:
		sleep_quality += 1
		morale_change += 1
	elif night_ratio <= 0.0:
		sleep_quality -= 1
	return {
		"fire_level": fire_level,
		"fatigue_recovery": fatigue_recovery,
		"warmth_change": int(round(int(warmth_breakdown.get("net_warmth_change", 0)) * duration_ratio)),
		"morale_change": morale_change,
		"sleep_quality": sleep_quality,
		"warmth_breakdown": warmth_breakdown,
		"sleep_hours": sleep_hours,
		"night_ratio": night_ratio,
		"nutrition_drain": int(round(config.sleep_rough_nutrition_drain * duration_ratio))
	}


static func _apply_sleep_rough(player_state, config, context: Dictionary = {}) -> void:
	var evaluated_day = player_state.current_day
	var used_temp_bedroll = _apply_context_sleep_item_state(player_state, context)
	var rest_result = _calculate_sleep_rest_result(player_state, config, context)
	var fire_level = int(rest_result.get("fire_level", 0))
	var sleep_hours = int(rest_result.get("sleep_hours", config.sleep_rough_hours))
	var time_result = _advance_loop_time(player_state, config, sleep_hours * 60)
	var days_passed = int(time_result.get("days_passed", 0))
	player_state.nutrition_tick_bank_minutes = 0
	player_state.fatigue_tick_bank_minutes = 0

	var unsafe_sleep = fire_level <= 0 and not player_state.camp_sleeping_spot_ready and not player_state.camp_bedroll_laid

	player_state.record_rest(
		sleep_hours,
		int(rest_result.get("fatigue_recovery", config.sleep_rough_fatigue_recovery)),
		int(rest_result.get("nutrition_drain", config.sleep_rough_nutrition_drain)),
		int(rest_result.get("warmth_change", 0)),
		int(rest_result.get("morale_change", config.sleep_rough_morale))
	)
	# Sleep is the one daily checkpoint where the loop already resolves rest, so fading
	# evaluation happens here as a rolling end-of-day assessment instead of per-action.
	FadingMeterSystemScript.record_sleep_outcome(player_state, int(rest_result.get("sleep_quality", 0)), unsafe_sleep)
	FadingMeterSystemScript.evaluate_end_of_day(player_state, config, evaluated_day)

	if days_passed > 0:
		player_state.reset_daily_loop_counters()
		player_state.job_board_generated_day = 0
	else:
		player_state.set_camp_fire_level(0)
		player_state.clear_camp_prep_state()
	if used_temp_bedroll:
		player_state.clear_camp_prep_state()


static func _advance_awake_time(player_state, config, minutes: int) -> void:
	_advance_loop_time(player_state, config, minutes)


static func _advance_loop_time(player_state, config, minutes: int) -> Dictionary:
	if minutes <= 0:
		return {"days_passed": 0}
	var previous_day = player_state.current_day
	var days_passed = player_state.advance_time(minutes)
	if days_passed > 0:
		for ended_day in range(previous_day, player_state.current_day):
			_resolve_end_of_day_support_pressure(player_state, config, ended_day)
		if _is_post_midnight_sleep_continuation(player_state, config, previous_day, days_passed):
			player_state.wages_earned_today_cents = 0
			player_state.support_sent_today_cents = 0
		else:
			player_state.reset_daily_loop_counters()
		if player_state.current_day != previous_day:
			player_state.job_board_generated_day = 0

	player_state.nutrition_tick_bank_minutes += minutes
	while player_state.nutrition_tick_bank_minutes >= config.passive_nutrition_minutes_per_point:
		player_state.nutrition_tick_bank_minutes -= config.passive_nutrition_minutes_per_point
		player_state.apply_nutrition_drain(1)

	player_state.fatigue_tick_bank_minutes += minutes
	while player_state.fatigue_tick_bank_minutes >= config.passive_fatigue_minutes_per_point:
		player_state.fatigue_tick_bank_minutes -= config.passive_fatigue_minutes_per_point
		player_state.apply_fatigue_tick(1)
	return {"days_passed": days_passed, "previous_day": previous_day, "current_day": player_state.current_day}


static func _resolve_end_of_day_support_pressure(player_state, config, day_index: int) -> void:
	if player_state == null or config == null:
		return
	var due_deliveries = player_state.pop_due_support_deliveries(day_index)
	for delivery in due_deliveries:
		if not (delivery is Dictionary):
			continue
		var amount_cents = int(delivery.get("amount_cents", 0))
		player_state.record_support_delivered(
			amount_cents,
			StringName(delivery.get("method_id", &"")),
			int(delivery.get("sent_day", 0)),
			int(delivery.get("arrival_day", day_index))
		)
		player_state.apply_morale_delta(config.send_support_morale_gain)
		FadingMeterSystemScript.record_support_sent(player_state, config, amount_cents)
	player_state.resolve_support_obligations_due_on(
		day_index,
		config.support_obligation_hit_morale_gain,
		config.support_obligation_miss_morale_penalty
	)
	if day_index >= player_state.day_limit and not player_state.monthly_support_resolved:
		player_state.monthly_support_resolved = true
		if player_state.support_delivered_total_cents < player_state.monthly_support_target_cents:
			player_state.apply_morale_delta(config.monthly_support_failure_morale_penalty)
	player_state.future_system_flags["support_pressure_resolved_through_day"] = max(
		int(player_state.future_system_flags.get("support_pressure_resolved_through_day", 0)),
		day_index
	)


static func _resolve_overdue_support_pressure(player_state, config) -> void:
	if player_state == null or config == null:
		return
	var last_resolved_day = max(int(player_state.future_system_flags.get("support_pressure_resolved_through_day", 0)), 0)
	var target_day = max(player_state.current_day - 1, 0)
	if target_day <= last_resolved_day:
		return
	for day_index in range(last_resolved_day + 1, target_day + 1):
		_resolve_end_of_day_support_pressure(player_state, config, day_index)
	player_state.future_system_flags["support_pressure_resolved_through_day"] = target_day


static func _ensure_job_board_for_current_day(player_state, config) -> void:
	if player_state == null or config == null:
		return
	if player_state.job_board_generated_day == player_state.current_day and not player_state.daily_job_board.is_empty():
		return

	var rng = RandomNumberGenerator.new()
	rng.seed = int(config.job_generation_seed) + int(player_state.current_day * 7919)
	var previous_generation_day = max(int(player_state.job_board_generated_day), 0)
	var crossed_week_boundary = previous_generation_day > 0 and _get_store_week_index_for_day(previous_generation_day, config) != _get_store_week_index(player_state, config)

	var carried_jobs: Array = []
	var existing_template_ids: Array = []
	for job in player_state.daily_job_board:
		if not (job is Dictionary):
			continue
		if int(job.get("expires_on_day", 0)) >= player_state.current_day:
			var carried = job.duplicate(true)
			if _should_rotate_carried_job(carried, player_state.current_day, crossed_week_boundary, config, rng):
				continue
			_apply_job_decay(carried, player_state.current_day)
			carried["persistent"] = int(carried.get("expires_on_day", 0)) > player_state.current_day
			carried_jobs.append(carried)
			existing_template_ids.append(StringName(carried.get("template_id", &"")))

	var target_count = rng.randi_range(config.min_jobs_per_day, config.max_jobs_per_day)
	while carried_jobs.size() < target_count:
		var template = _pick_weighted_template(config, existing_template_ids, rng)
		if template == null:
			break
		var duration_days = 1
		if template.can_persist and rng.randi_range(1, 100) <= template.persistence_chance_percent:
			duration_days = rng.randi_range(template.persistent_days_min, template.persistent_days_max)
		var expires_on_day = player_state.current_day + duration_days - 1
		var instance_id = StringName("%s_day_%d_%d" % [template.template_id, player_state.current_day, carried_jobs.size()])
		carried_jobs.append(template.to_job_entry(player_state.current_day, instance_id, expires_on_day))
		existing_template_ids.append(template.template_id)

	player_state.set_daily_job_board(carried_jobs)


static func _pick_weighted_template(config, excluded_template_ids: Array, rng: RandomNumberGenerator):
	var templates: Array = []
	var total_weight := 0
	for template in config.job_templates:
		if template == null or not template.is_valid_template():
			continue
		if excluded_template_ids.has(template.template_id):
			continue
		templates.append(template)
		total_weight += int(template.weight)

	if templates.is_empty() or total_weight <= 0:
		return null

	var roll = rng.randi_range(1, total_weight)
	var running := 0
	for template in templates:
		running += int(template.weight)
		if roll <= running:
			return template
	return templates[0]


static func _get_appearance_tier_entry(tier_id: StringName, config) -> Dictionary:
	if config != null:
		for tier in config.appearance_tiers:
			if tier is Dictionary and StringName(tier.get("tier_id", &"")) == tier_id:
				return tier.duplicate(true)
	return {"tier_id": tier_id, "label": String(tier_id).replace("_", " ").capitalize(), "rank": 0}


static func _apply_job_decay(job: Dictionary, current_day: int) -> void:
	var behavior = StringName(job.get("decay_behavior", &"expire"))
	if behavior != &"degrade_pay":
		return
	var generated_day = int(job.get("generated_day", current_day))
	var days_old = max(current_day - generated_day, 0)
	var base_pay = max(int(job.get("base_pay_cents", job.get("pay_cents", 0))), 0)
	var decay_per_day = max(int(job.get("pay_decay_cents_per_day", 0)), 0)
	var minimum_pay = max(int(job.get("minimum_pay_cents", 0)), 0)
	job["pay_cents"] = max(base_pay - (days_old * decay_per_day), minimum_pay)
	job["decay_days_old"] = days_old


static func _should_rotate_carried_job(job: Dictionary, current_day: int, crossed_week_boundary: bool, config, rng: RandomNumberGenerator) -> bool:
	if int(job.get("expires_on_day", 0)) < current_day:
		return true
	if StringName(job.get("decay_behavior", &"expire")) == &"stable":
		return false
	if not crossed_week_boundary:
		return false
	var chance = clampi(int(config.weekly_job_rotation_drop_chance_percent), 0, 100)
	return chance > 0 and rng.randi_range(1, 100) <= chance


static func _get_store_week_index_for_day(day_index: int, config) -> int:
	var days_per_week = max(int(config.store_refresh_days_per_week), 1)
	return int(floor(float(max(day_index, 1) - 1) / float(days_per_week))) + 1


static func _check_purchase(player_state, item_catalog, item_id: StringName, price_cents: int) -> Dictionary:
	if item_catalog == null or item_catalog.get_item(item_id) == null:
		return _blocked("That supply is not available in this prototype.")
	if player_state.money_cents < price_cents:
		return _blocked("You do not have enough cash on hand.")
	return _allowed()


static func _check_town_purchase(player_state, item_catalog, item_id: StringName, price_cents: int) -> Dictionary:
	if not _is_at_town(player_state):
		return _blocked("Town supplies are back in town.")
	return _check_purchase(player_state, item_catalog, item_id, price_cents)


static func _check_store_stock_purchase(player_state, config, item_catalog, store_id: StringName, stock_index: int) -> Dictionary:
	if not _is_at_town(player_state):
		return _blocked("Town stores are back in town.")
	if store_id != STORE_GROCERY and store_id != STORE_HARDWARE:
		return _blocked("Choose a town store shelf first.")
	ensure_weekly_store_stock(player_state, config, item_catalog)
	var stock_entry = _get_store_stock_entry(player_state, store_id, stock_index)
	if stock_entry.is_empty():
		return _blocked("That store shelf is empty now.")
	var item_id = StringName(stock_entry.get("item_id", &""))
	if item_catalog == null or item_catalog.get_item(item_id) == null:
		return _blocked("That store item is not available in this prototype.")
	if player_state.money_cents < int(stock_entry.get("price_cents", 0)):
		return _blocked("You do not have enough cash on hand.")
	return _allowed()


static func _check_craft_recipe(player_state, item_catalog, recipe_id: StringName) -> Dictionary:
	if not _is_at_camp(player_state):
		return _blocked("Hobocraft belongs at camp.")
	var recipe = _get_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return _blocked("That recipe is not available at this camp.")
	if item_catalog == null or item_catalog.get_item(StringName(recipe.get("output_item_id", &""))) == null:
		return _blocked("That craft output is not available in the item catalog.")
	for input in recipe.get("inputs", []):
		if not (input is Dictionary):
			continue
		var item_id = StringName(input.get("item_id", &""))
		var quantity = max(int(input.get("quantity", 1)), 1)
		if not player_state.inventory_state.has_item(item_id, quantity):
			return _blocked("Missing %s x%d." % [String(item_id).replace("_", " "), quantity])
	return _allowed()


static func _check_brew_camp_coffee(player_state, config, item_catalog) -> Dictionary:
	if not _is_at_camp(player_state):
		return _blocked("Camp coffee belongs at camp.")
	if player_state.camp_coffee_brewed:
		return _blocked("You have already brewed camp coffee for this camp.")
	if not _has_active_fire(player_state, config):
		return _blocked("Build a fire before brewing coffee.")
	if not player_state.has_potable_water(1) and not player_state.inventory_state.has_item(config.brew_camp_coffee_water_item_id, 1):
		return _blocked("Boil potable water before brewing coffee.")
	if not player_state.inventory_state.has_item(config.brew_camp_coffee_input_item_id, 1):
		return _blocked("You need coffee grounds.")
	if not player_state.inventory_state.has_item(config.brew_camp_coffee_tool_item_id, 1) and not _has_any_item(player_state.inventory_state, COOKING_HEAT_TOOL_ITEM_IDS):
		return _blocked("You need a tin can or small cookware to brew it in.")
	if item_catalog == null or item_catalog.get_item(config.brew_camp_coffee_output_item_id) == null:
		return _blocked("Camp coffee output is not available in the item catalog.")
	return _allowed()


static func _check_cooking_recipe(player_state, config, item_catalog, recipe_id: StringName) -> Dictionary:
	if not _is_at_camp(player_state):
		return _blocked("Cooking belongs at camp.")
	var recipe = _get_cooking_recipe_by_id(recipe_id)
	if recipe.is_empty():
		return _blocked("That cooking recipe is not known in this prototype.")
	match recipe_id:
		&"boil_water":
			if player_state.has_potable_water(1) and player_state.camp_non_potable_water_units <= 0:
				return _blocked("Potable water is already ready.")
			if player_state.camp_non_potable_water_units > 0 and not _has_active_fire(player_state, config):
				return _blocked("Build a fire before boiling water.")
			return _allowed()
		&"brew_camp_coffee":
			return _check_brew_camp_coffee(player_state, config, item_catalog)
		&"heat_beans":
			return _check_hot_food_recipe(player_state, config, &"beans_can")
		&"heat_potted_meat":
			return _check_hot_food_recipe(player_state, config, &"potted_meat")
		&"mulligan_stew":
			return _check_mulligan_stew(player_state, config)
	return _blocked("That cooking recipe has no rule handler.")


static func _check_hot_food_recipe(player_state, config, item_id: StringName) -> Dictionary:
	if not _has_active_fire(player_state, config):
		return _blocked("Build a fire before heating food.")
	if not _has_any_item(player_state.inventory_state, COOKING_HEAT_TOOL_ITEM_IDS):
		return _blocked("You need a tin-can heater, soup can stove, or road cook kit.")
	if not player_state.inventory_state.has_item(item_id, 1):
		return _blocked("Missing %s." % String(item_id).replace("_", " "))
	var opener_check = _check_can_opener_for_item(player_state, item_id)
	if not bool(opener_check.get("enabled", false)):
		return opener_check
	return _allowed()


static func _check_mulligan_stew(player_state, config) -> Dictionary:
	if not _has_active_fire(player_state, config):
		return _blocked("Build a fire before making stew.")
	if not _has_any_item(player_state.inventory_state, COOKING_HEAT_TOOL_ITEM_IDS):
		return _blocked("You need a tin-can heater, soup can stove, or road cook kit.")
	if not player_state.has_potable_water(1) and not player_state.inventory_state.has_item(config.brew_camp_coffee_water_item_id, 1):
		return _blocked("You need potable water for stew.")
	var staple_id = _find_first_available_cooking_input(player_state, MULLIGAN_STAPLE_ITEM_IDS)
	if staple_id == &"":
		return _blocked("Mulligan stew needs a staple like beans, dried beans, or oats.")
	var body_id = _find_first_available_cooking_input(player_state, MULLIGAN_BODY_ITEM_IDS)
	if body_id == &"":
		return _blocked("Mulligan stew needs preserved meat, fat, or salt to carry it.")
	if _item_requires_can_opener(staple_id) or _item_requires_can_opener(body_id):
		var opener_check = _check_can_opener(player_state)
		if not bool(opener_check.get("enabled", false)):
			return opener_check
	return _allowed()


static func _get_store_stock_entry(player_state, store_id: StringName, stock_index: int) -> Dictionary:
	if player_state == null or stock_index < 0 or not player_state.has_method("get_store_stock"):
		return {}
	var stock = player_state.get_store_stock(store_id)
	if stock_index >= stock.size():
		return {}
	var entry = stock[stock_index]
	if entry is Dictionary:
		return entry.duplicate(true)
	return {}


static func _get_recipe_by_id(recipe_id: StringName) -> Dictionary:
	var recipe = RecipeCatalogScript.get_recipe(recipe_id)
	if String(recipe.get("recipe_category", "")).to_lower() != "hobocraft":
		return {}
	return recipe


static func _get_cooking_recipe_by_id(recipe_id: StringName) -> Dictionary:
	var recipe = RecipeCatalogScript.get_recipe(recipe_id)
	if String(recipe.get("recipe_category", "")).to_lower() != "cooking":
		return {}
	return recipe


static func _collect_recipe_input_quality_entries(inventory, recipe: Dictionary) -> Array:
	var entries: Array = []
	if inventory == null:
		return entries
	for input in recipe.get("inputs", []):
		if not (input is Dictionary):
			continue
		var item_id = StringName(input.get("item_id", &""))
		var needed = max(int(input.get("quantity", 1)), 1)
		for stack in inventory.stacks:
			if needed <= 0:
				break
			if stack == null or stack.is_empty() or stack.item == null or stack.item.item_id != item_id:
				continue
			var taken = min(needed, stack.quantity)
			for _unit in range(taken):
				entries.append({
					"item": stack.item,
					"quality_tier": stack.quality_tier,
					"quality_score": stack.quality_score
				})
			needed -= taken
	return entries


static func _get_crafted_tool_uses(output_item, quality_tier: int, recipe: Dictionary) -> int:
	if output_item == null or int(output_item.cooking_max_uses) <= 0:
		return -1
	var recipe_bonus = int(recipe.get("use_bonus", 0))
	var quality_bonus = max(quality_tier - ItemDefinitionScript.QualityTier.COMMON, 0) * 2
	var poor_penalty = 1 if quality_tier <= ItemDefinitionScript.QualityTier.POOR else 0
	return max(int(output_item.cooking_max_uses) + recipe_bonus + quality_bonus - poor_penalty, 1)


static func _find_best_cooking_tool_stack(player_state) -> Dictionary:
	if player_state == null or player_state.inventory_state == null:
		return {}
	var best: Dictionary = {}
	for index in range(player_state.inventory_state.stacks.size()):
		var stack = player_state.inventory_state.get_stack_at(index)
		if stack == null or stack.is_empty() or stack.item == null:
			continue
		if not COOKING_HEAT_TOOL_ITEM_IDS.has(stack.item.item_id):
			continue
		var score = float(stack.item.cooking_stability) + float(stack.item.cooking_efficiency) + (float(stack.quality_tier) * 0.15)
		if best.is_empty() or score > float(best.get("score", 0.0)):
			best = {"stack_index": index, "stack": stack, "score": score}
	return best


static func _apply_cooking_tool_wear(player_state) -> Dictionary:
	var best_tool = _find_best_cooking_tool_stack(player_state)
	if best_tool.is_empty():
		return {"efficiency": 1.0, "message": ""}
	var stack = best_tool.get("stack")
	var stack_index = int(best_tool.get("stack_index", -1))
	if stack == null or stack.item == null:
		return {"efficiency": 1.0, "message": ""}
	if int(stack.item.cooking_max_uses) <= 0:
		return {"efficiency": float(stack.item.cooking_efficiency), "message": ""}
	if stack.durability_uses_remaining < 0:
		stack.durability_uses_remaining = _get_crafted_tool_uses(stack.item, stack.quality_tier, {})
	stack.durability_uses_remaining -= max(int(stack.item.cooking_use_cost), 1)
	if stack.durability_uses_remaining <= 0:
		var tool_name = stack.item.display_name
		player_state.inventory_state.remove_quantity_from_stack(stack_index, 1)
		return {
			"efficiency": float(stack.item.cooking_efficiency),
			"message": "%s gives out after the cooking." % tool_name
		}
	return {
		"efficiency": float(stack.item.cooking_efficiency),
		"message": "%s has %d cooking use%s left." % [
			stack.item.display_name,
			stack.durability_uses_remaining,
			"" if stack.durability_uses_remaining == 1 else "s"
		]
	}


static func _check_send_home(player_state, config, amount_cents: int, method_id: StringName) -> Dictionary:
	if amount_cents <= 0:
		return _blocked("No support amount was configured.")
	var method = _get_support_send_method(config, method_id)
	if method.is_empty():
		return _blocked("That way of sending money is not available in this prototype.")
	var total_cost = amount_cents + max(int(method.get("fee_cents", 0)), 0)
	if player_state.money_cents < total_cost:
		return _blocked("You do not have enough cash for the amount and the fee.")
	return _allowed()


static func _get_support_send_method(config, method_id: StringName) -> Dictionary:
	if config == null:
		return {}
	for method in config.support_send_methods:
		if method is Dictionary and StringName(method.get("method_id", &"")) == method_id:
			return method.duplicate(true)
	return {}


static func get_support_send_methods(config) -> Array:
	var result: Array = []
	if config == null:
		return result
	for method in config.support_send_methods:
		if method is Dictionary:
			result.append(method.duplicate(true))
	return result


static func _check_selected_usable(player_state, selected_stack_index: int) -> Dictionary:
	var stack = player_state.inventory_state.get_stack_at(selected_stack_index)
	if stack == null:
		return _blocked("Open inventory and select a usable item first.")
	if stack.item == null or not stack.item.can_use():
		return _blocked("That selected item is not usable.")
	var opener_check = _check_can_opener_for_item(player_state, stack.item.item_id)
	if not bool(opener_check.get("enabled", false)):
		return opener_check
	return _allowed()


static func _check_can_opener_for_item(player_state, item_id: StringName) -> Dictionary:
	if not _item_requires_can_opener(item_id):
		return _allowed()
	return _check_can_opener(player_state)


static func _check_can_opener(player_state) -> Dictionary:
	if player_state != null and _has_any_item(player_state.inventory_state, CAN_OPENER_ITEM_IDS):
		return _allowed()
	return _blocked("You need a church key or pocket knife to open that tin.")


static func _item_requires_can_opener(item_id: StringName) -> bool:
	return SEALED_CAN_ITEM_IDS.has(item_id)


static func _is_getting_ready_action(action_id: StringName) -> bool:
	return action_id == ACTION_READY_FETCH_WATER or _is_normal_getting_ready_action(action_id)


static func _is_normal_getting_ready_action(action_id: StringName) -> bool:
	return action_id == ACTION_READY_WASH_BODY \
		or action_id == ACTION_READY_WASH_FACE_HANDS \
		or action_id == ACTION_READY_SHAVE \
		or action_id == ACTION_READY_COMB_GROOM \
		or action_id == ACTION_READY_AIR_OUT_CLOTHES \
		or action_id == ACTION_READY_BRUSH_CLOTHES


static func _is_at_town(player_state) -> bool:
	return player_state != null and StringName(player_state.loop_location_id) == LOCATION_TOWN


static func _is_at_camp(player_state) -> bool:
	return player_state != null and StringName(player_state.loop_location_id) == LOCATION_CAMP


static func _can_sleep_rough(player_state, config, context: Dictionary = {}) -> bool:
	if _resolve_sleep_hours(config, context) > 0:
		return true
	if _get_stamina_value(player_state) < config.rest_anytime_stamina_threshold:
		return true
	return _is_in_wrapping_window(
		player_state.time_of_day_minutes,
		config.sleep_rough_window_start_minutes,
		config.sleep_rough_window_end_minutes
	)


static func _resolve_sleep_hours(config, context: Dictionary = {}) -> int:
	if config == null:
		return 0
	return clampi(int(context.get("hours", config.sleep_rough_hours)), 1, 12)


static func _apply_context_sleep_item_state(player_state, context: Dictionary = {}) -> bool:
	if player_state == null:
		return false
	var sleep_item_id = StringName(context.get("sleep_item_id", &""))
	if sleep_item_id == &"blanket_roll" and player_state.inventory_state != null and player_state.inventory_state.has_item(&"blanket_roll", 1):
		player_state.mark_sleeping_spot_ready(true)
		return true
	return false


static func _calculate_sleep_night_ratio(player_state, config, duration_minutes: int) -> float:
	if player_state == null or config == null or duration_minutes <= 0:
		return 0.0
	var night_minutes := 0
	var minute = int(player_state.time_of_day_minutes)
	for _index in range(duration_minutes):
		if _is_in_wrapping_window(minute, config.sleep_rough_window_start_minutes, config.sleep_rough_window_end_minutes):
			night_minutes += 1
		minute = (minute + 1) % 1440
	return float(night_minutes) / float(duration_minutes)


static func _get_stamina_value(player_state) -> int:
	if player_state == null or player_state.passport_profile == null:
		return 0
	if player_state.passport_profile.has_method("get_stamina"):
		return player_state.passport_profile.get_stamina()
	return clampi(100 - player_state.passport_profile.fatigue, 0, 100)


static func _has_minimum_camp_setup(player_state) -> bool:
	return player_state.camp_sleeping_spot_ready \
		or _has_active_fire(player_state)


static func _has_active_fire(player_state, config = null) -> bool:
	return _get_active_camp_fire_level(player_state, config) > 0


static func _get_active_camp_fire_level(player_state, config = null) -> int:
	if player_state == null or player_state.camp_fire_level <= 0:
		return 0
	if player_state.camp_fire_day == player_state.current_day:
		return player_state.camp_fire_level
	if config != null \
			and config.sleep_rough_window_start_minutes > config.sleep_rough_window_end_minutes \
			and player_state.time_of_day_minutes <= config.sleep_rough_window_end_minutes \
			and player_state.camp_fire_day == player_state.current_day - 1:
		return player_state.camp_fire_level
	return 0


static func _is_post_midnight_sleep_continuation(player_state, config, previous_day: int, days_passed: int) -> bool:
	if player_state == null or config == null or days_passed != 1:
		return false
	if not _is_at_camp(player_state):
		return false
	if config.sleep_rough_window_start_minutes <= config.sleep_rough_window_end_minutes:
		return false
	return player_state.current_day == previous_day + 1 \
		and player_state.time_of_day_minutes <= config.sleep_rough_window_end_minutes


static func _has_any_item(inventory, item_ids: Array) -> bool:
	return _find_first_available_item(inventory, item_ids) != &""


static func _count_item_group(inventory, item_ids: Array) -> int:
	var total := 0
	if inventory == null:
		return total
	for item_id in item_ids:
		total += inventory.count_item(StringName(item_id))
	return total


static func _get_inventory_state(player_state):
	if player_state == null:
		return null
	if player_state.get("inventory_state") != null:
		return player_state.get("inventory_state")
	return player_state.get("inventory")


static func _build_recipe_snapshot_entry(item_id: StringName, have: int, need: int, item_catalog = null) -> Dictionary:
	return {
		"item_id": item_id,
		"label": _get_recipe_snapshot_label(item_id, item_catalog),
		"have": have,
		"need": need
	}


static func _get_recipe_snapshot_label(item_id: StringName, item_catalog = null) -> String:
	if item_catalog != null and item_catalog.has_method("get_item"):
		var item = item_catalog.get_item(item_id)
		if item != null:
			return item.display_name
	return String(item_id).replace("_", " ").capitalize()


static func _find_first_available_item(inventory, item_ids: Array) -> StringName:
	if inventory == null:
		return &""
	for item_id in item_ids:
		var resolved_item_id = StringName(item_id)
		if inventory.has_item(resolved_item_id, 1):
			return resolved_item_id
	return &""


static func _find_first_available_cooking_input(player_state, item_ids: Array) -> StringName:
	if player_state == null or player_state.inventory_state == null:
		return &""
	var has_opener = _has_any_item(player_state.inventory_state, CAN_OPENER_ITEM_IDS)
	for item_id in item_ids:
		var resolved_item_id = StringName(item_id)
		if _item_requires_can_opener(resolved_item_id) and not has_opener:
			continue
		if player_state.inventory_state.has_item(resolved_item_id, 1):
			return resolved_item_id
	return &""


static func _get_first_item_zone(inventory, item_id: StringName) -> StringName:
	if inventory == null:
		return InventoryScript.CARRY_PACK
	for stack in inventory.stacks:
		if stack != null and not stack.is_empty() and stack.item != null and stack.item.item_id == item_id:
			return StringName(stack.carry_zone)
	return InventoryScript.CARRY_PACK


static func _has_quiet_comfort_source(player_state, config = null) -> bool:
	if player_state.inventory_state.has_item(&"family_letter", 1):
		return true
	if player_state.inventory_state.has_item(&"smoke_tobacco", 1):
		return true
	return _has_active_fire(player_state, config)


static func _prepare_state(player_state, config) -> void:
	if player_state == null or config == null:
		return
	player_state.ensure_core_resources()
	player_state.set_loop_defaults(config.support_goal_cents, config.day_limit, config)
	_resolve_overdue_support_pressure(player_state, config)
	player_state.refresh_loop_goal_text()


static func _refresh_outcome(player_state, config) -> void:
	if player_state == null or config == null:
		return

	if player_state.passport_profile.nutrition <= 0 or player_state.passport_profile.fatigue >= 100:
		player_state.prototype_loop_status = &"failure"
	elif player_state.current_day > player_state.day_limit:
		if player_state.monthly_support_target_cents <= 0 or player_state.support_delivered_total_cents >= player_state.monthly_support_target_cents:
			player_state.prototype_loop_status = &"success"
		else:
			player_state.prototype_loop_status = &"failure"
	else:
		player_state.prototype_loop_status = &"ongoing"
	player_state.refresh_loop_goal_text()


static func _add_item_to_inventory(inventory, item, quantity: int) -> int:
	if inventory == null or item == null or quantity <= 0:
		return quantity
	var remaining = inventory.add_item(item, quantity, InventoryScript.CARRY_PACK)
	if remaining > 0:
		remaining = inventory.add_item(item, remaining, InventoryScript.CARRY_GROUND)
	return remaining


static func _add_item_to_inventory_with_quality(inventory, item, quantity: int, quality_tier: int, quality_score: float, durability_uses_remaining: int = -1) -> int:
	if inventory == null or item == null or quantity <= 0:
		return quantity
	var remaining = inventory.add_item_with_quality(item, quantity, InventoryScript.CARRY_PACK, quality_tier, quality_score, durability_uses_remaining)
	if remaining > 0:
		remaining = inventory.add_item_with_quality(item, remaining, InventoryScript.CARRY_GROUND, quality_tier, quality_score, durability_uses_remaining)
	return remaining


static func _is_in_window(time_minutes: int, start_minutes: int, end_minutes: int) -> bool:
	return time_minutes >= start_minutes and time_minutes <= end_minutes


static func _is_in_wrapping_window(time_minutes: int, start_minutes: int, end_minutes: int) -> bool:
	if start_minutes <= end_minutes:
		return _is_in_window(time_minutes, start_minutes, end_minutes)
	return time_minutes >= start_minutes or time_minutes <= end_minutes


static func _allowed() -> Dictionary:
	return {
		"enabled": true,
		"reason": ""
	}


static func _blocked(reason: String) -> Dictionary:
	return {
		"enabled": false,
		"reason": reason
	}


static func _result(success: bool, message: String) -> Dictionary:
	return {
		"success": success,
		"message": message
	}


static func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(max(amount_cents, 0)) / 100.0)


static func _format_duration(minutes: int) -> String:
	if minutes >= 60 and minutes % 60 == 0:
		return "%dh" % int(minutes / 60)
	if minutes >= 60:
		return "%dh %02dm" % [int(minutes / 60), minutes % 60]
	return "%dm" % minutes
