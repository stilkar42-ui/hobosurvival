class_name CharacterRules
extends RefCounted


func get_derived_snapshot(player_state, deps: Dictionary = {}) -> Dictionary:
	if player_state == null:
		return {}

	var stats_manager = deps.get("stats_manager", null)
	var inventory_manager = deps.get("inventory_manager", null)
	var location_manager = deps.get("location_manager", null)

	var condition = stats_manager.get_condition_snapshot(player_state) if stats_manager != null and stats_manager.has_method("get_condition_snapshot") else {}
	var inventory = inventory_manager.get_inventory(player_state) if inventory_manager != null and inventory_manager.has_method("get_inventory") else null
	var carried_weight = inventory.get_total_weight_kg() if inventory != null and inventory.has_method("get_total_weight_kg") else 0.0
	var has_heat = player_state.has_method("get_camp_fire_status_label") and String(player_state.get_camp_fire_status_label()).findn("No") == -1
	var is_camp = location_manager != null and location_manager.has_method("is_camp_location") and location_manager.is_camp_location(StringName(player_state.loop_location_id))
	var hygiene = int(condition.get("hygiene", 0))
	var presentability = int(condition.get("presentability", 0))
	var warmth = int(condition.get("warmth", 0))
	var nutrition = int(condition.get("nutrition", 0))
	var stamina = int(condition.get("stamina", 0))
	var morale = int(condition.get("morale", 0))

	var labor_readiness = clampi(int((nutrition + stamina + morale) / 3.0), 0, 100)
	var travel_readiness = clampi(int((stamina + warmth + nutrition) / 3.0) - int(carried_weight * 2.0), 0, 100)
	var appearance_readiness = clampi(int((hygiene + presentability + morale) / 3.0), 0, 100)
	var camp_recovery = clampi(int((warmth + morale + (20 if has_heat else 0) + (10 if is_camp else -10)) / 4.0), 0, 100)

	return {
		"labor_readiness": _build_readiness_entry(
			labor_readiness,
			"Labor Readiness",
			"The body still has enough food, morale, and usable strength to take a day's work.",
			["nutrition", "stamina", "morale"]
		),
		"travel_readiness": _build_readiness_entry(
			travel_readiness,
			"Travel Readiness",
			"Travel readiness reads the road body: warmth, food, strength, and how heavy the carried stake has become.",
			["nutrition", "stamina", "warmth", "carry_weight"]
		),
		"appearance_readiness": _build_readiness_entry(
			appearance_readiness,
			"Appearance Readiness",
			"Appearance readiness is only a surface read for now. Later fade and social pressure can distort how clearly this is understood.",
			["hygiene", "presentability", "morale"]
		),
		"camp_recovery": _build_readiness_entry(
			camp_recovery,
			"Camp Recovery",
			"Camp recovery is a rough estimate of whether this camp can return some dignity and usable strength before tomorrow.",
			["warmth", "morale", "camp_heat", "environment"]
		)
	}


func build_passport_sections(snapshot: Dictionary) -> Array:
	if snapshot.is_empty():
		return []
	return [{
		"id": &"derived_readiness",
		"title": "Road Readiness",
		"summary": "Readiness is computed from the body's present condition, the carried stake, and where the player is trying to stand in the world.",
		"fields": [
			_build_readiness_field(&"labor_readiness", snapshot.get("labor_readiness", {})),
			_build_readiness_field(&"travel_readiness", snapshot.get("travel_readiness", {})),
			_build_readiness_field(&"appearance_readiness", snapshot.get("appearance_readiness", {})),
			_build_readiness_field(&"camp_recovery", snapshot.get("camp_recovery", {}))
		]
	}]


func _build_readiness_entry(value: int, label: String, notes: String, inputs: Array) -> Dictionary:
	return {
		"value": clampi(value, 0, 100),
		"label": label,
		"descriptor": _get_readiness_descriptor(value),
		"notes": notes,
		"inputs": inputs.duplicate()
	}


func _build_readiness_field(field_id: StringName, entry: Dictionary) -> Dictionary:
	var value = clampi(int(entry.get("value", 0)), 0, 100)
	var descriptor = String(entry.get("descriptor", "Unclear"))
	return {
		"id": field_id,
		"label": String(entry.get("label", "Readiness")),
		"value": "%d / 100" % value,
		"descriptor_value": descriptor,
		"hidden_value": "Unnoticed State",
		"display_mode": "descriptor",
		"display_as_bar": true,
		"current": value,
		"max": 100,
		"notes": "%s\nInputs watched: %s." % [
			String(entry.get("notes", "Computed from current condition.")),
			", ".join(entry.get("inputs", []))
		]
	}


func _get_readiness_descriptor(value: int) -> String:
	if value >= 80:
		return "Steady"
	if value >= 60:
		return "Workable"
	if value >= 40:
		return "Thin"
	if value >= 20:
		return "Frayed"
	return "Spent"
