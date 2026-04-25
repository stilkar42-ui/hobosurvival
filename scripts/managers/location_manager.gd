class_name LocationManager
extends RefCounted

const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const PAGE_TOWN := &"town"
const PAGE_JOBS_BOARD := &"jobs_board"
const PAGE_SEND_MONEY := &"send_money"
const PAGE_CAMP := &"camp"
const PAGE_GROCERY := &"grocery"
const PAGE_HARDWARE := &"hardware"
const PAGE_GENERAL_STORE := &"general_store"
const PAGE_DOCTOR_APOTHECARY := &"doctor_apothecary"
const PAGE_GETTING_READY := &"getting_ready"
const PAGE_REST_CAMP := &"rest_camp"
const PAGE_HOBOCRAFT := &"hobocraft"
const PAGE_COOKING := &"cooking"
const ROUTE_LOCATION_PAGE := &"location_page"
const ROUTE_CRAFTING_PAGE := &"crafting_page"
const ROUTE_REST_PAGE := &"rest_camp_page"
const ROUTE_INVENTORY := &"inventory_ui"
const ROUTE_PASSPORT := &"passport_stats"
const ROUTE_EVENT := &"event_encounter"
const ROUTE_TRAVEL := &"travel_ui"

const TOWN_ONLY_PAGES := [PAGE_TOWN, PAGE_JOBS_BOARD, PAGE_SEND_MONEY, PAGE_GROCERY, PAGE_HARDWARE, PAGE_GENERAL_STORE, PAGE_DOCTOR_APOTHECARY, ROUTE_LOCATION_PAGE]
const CAMP_ONLY_PAGES := [PAGE_CAMP, PAGE_GETTING_READY, PAGE_REST_CAMP, PAGE_HOBOCRAFT, PAGE_COOKING, ROUTE_CRAFTING_PAGE, ROUTE_REST_PAGE]
const CAMP_SUB_PAGES := [PAGE_GETTING_READY, PAGE_REST_CAMP, PAGE_HOBOCRAFT, PAGE_COOKING, ROUTE_CRAFTING_PAGE, ROUTE_REST_PAGE]
const OVERLAY_ROUTES := [ROUTE_INVENTORY, ROUTE_PASSPORT, ROUTE_EVENT]

const CAMP_INTERACTION_PAGE_IDS := {
	&"hobocraft": PAGE_HOBOCRAFT,
	&"cooking": PAGE_COOKING,
	&"getting_ready": PAGE_GETTING_READY
}

const TOWN_INTERACTION_PAGE_IDS := {
	&"jobs_board": PAGE_JOBS_BOARD,
	&"send_money": PAGE_SEND_MONEY,
	&"grocery": PAGE_GROCERY,
	&"hardware": PAGE_HARDWARE,
	&"general_store": PAGE_GENERAL_STORE,
	&"doctor_apothecary": PAGE_DOCTOR_APOTHECARY
}

const ROUTE_DESTINATIONS := {
	&"rest": {"action_id": &"sleep_rough", "page_id": &""},
	&"craft": {"action_id": &"", "page_id": PAGE_HOBOCRAFT},
	&"cooking": {"action_id": &"", "page_id": PAGE_COOKING},
	&"exit": {"action_id": &"return_to_town", "page_id": &""},
	&"stash": {"action_id": &"", "page_id": &"inventory_ui"},
	&"ready": {"action_id": &"", "page_id": PAGE_GETTING_READY},
	&"town_jobs": {"action_id": &"", "page_id": PAGE_JOBS_BOARD},
	&"town_send_money": {"action_id": &"", "page_id": PAGE_SEND_MONEY},
	&"town_grocery": {"action_id": &"", "page_id": PAGE_GROCERY},
	&"town_hardware": {"action_id": &"", "page_id": PAGE_HARDWARE},
	&"town_general_store": {"action_id": &"", "page_id": PAGE_GENERAL_STORE},
	&"town_doctor_apothecary": {"action_id": &"", "page_id": PAGE_DOCTOR_APOTHECARY},
	&"town_foreman": {"action_id": &"", "page_id": PAGE_JOBS_BOARD},
	&"town_exit": {"action_id": &"go_to_camp", "page_id": &""}
}


func get_town_world_page() -> StringName:
	return PAGE_TOWN


func get_camp_world_page() -> StringName:
	return PAGE_CAMP


func get_town_only_pages() -> Array:
	return TOWN_ONLY_PAGES.duplicate()


func get_camp_only_pages() -> Array:
	return CAMP_ONLY_PAGES.duplicate()


func get_camp_sub_pages() -> Array:
	return CAMP_SUB_PAGES.duplicate()


func get_camp_interaction_page_ids() -> Dictionary:
	return CAMP_INTERACTION_PAGE_IDS.duplicate(true)


func get_town_interaction_page_ids() -> Dictionary:
	return TOWN_INTERACTION_PAGE_IDS.duplicate(true)


func get_route_destination(route_id: StringName) -> Dictionary:
	return ROUTE_DESTINATIONS.get(route_id, {}).duplicate(true)


func get_default_route_for_location(location_id: StringName) -> StringName:
	if is_camp_location(location_id):
		return PAGE_CAMP
	return PAGE_TOWN


func get_default_location_route_for_location(location_id: StringName) -> StringName:
	if is_town_location(location_id):
		return PAGE_JOBS_BOARD
	return &""


func get_default_crafting_route_for_location(location_id: StringName) -> StringName:
	if is_camp_location(location_id):
		return PAGE_HOBOCRAFT
	return &""


func get_default_rest_route_for_location(location_id: StringName) -> StringName:
	if is_camp_location(location_id):
		return PAGE_REST_CAMP
	return &""


func normalize_route_for_location(active_route: StringName, location_id: StringName) -> StringName:
	if is_overlay_route(active_route):
		return active_route
	if is_camp_location(location_id) and active_route in TOWN_ONLY_PAGES:
		return PAGE_CAMP
	if is_town_location(location_id) and active_route in CAMP_ONLY_PAGES:
		return PAGE_TOWN
	if active_route == &"":
		return get_default_route_for_location(location_id)
	return active_route


func is_overlay_route(route_id: StringName) -> bool:
	return route_id in OVERLAY_ROUTES


func is_town_location(location_id: StringName) -> bool:
	return location_id == SurvivalLoopRulesScript.LOCATION_TOWN


func is_camp_location(location_id: StringName) -> bool:
	return location_id == SurvivalLoopRulesScript.LOCATION_CAMP
