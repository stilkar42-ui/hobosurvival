class_name PlayerPassportData
extends Resource

@export_group("Identity")
@export var full_name := "Thomas Hale"
@export_range(14, 90, 1) var age := 34
@export var home_town := "Muncie, Indiana"
@export var family_status := "Married, two children back home"
@export_multiline var current_goal := "Find steady rail-yard labor before week's end and send money home."

@export_group("Base Attributes")
@export_range(1, 10, 1) var strength := 5
@export_range(1, 10, 1) var endurance := 6
@export_range(1, 10, 1) var wits := 5
@export_range(1, 10, 1) var presence := 4
@export_range(1, 10, 1) var agility := 4

@export_group("Condition Stats")
@export_range(0, 100, 1) var nutrition := 58
@export_range(0, 100, 1) var fatigue := 58
@export_range(0, 100, 1) var morale := 47
@export_range(0, 100, 1) var hygiene := 36
@export_range(0, 100, 1) var presentability := 32
@export_range(0, 100, 1) var warmth := 63

@export_group("Skills")
@export_range(0, 10, 1) var hobo_lore := 3
@export_range(0, 10, 1) var labor := 5
@export_range(0, 10, 1) var fighting := 2
@export_range(0, 10, 1) var crafting := 4
@export_range(0, 10, 1) var speech := 3
@export_range(0, 10, 1) var stealth := 2
@export_range(0, 10, 1) var scavenging := 4

@export_group("Placeholders")
@export var traits_perks: PackedStringArray = PackedStringArray(["Callused Hands", "Keeps His Word"])
@export var reputation_standing: PackedStringArray = PackedStringArray(["Unknown in this town", "No police trouble on record"])
@export var affiliations: PackedStringArray = PackedStringArray(["Family in Indiana", "Knows a rail cook outside Terre Haute"])


func get_sections() -> Array:
	return [
		_make_section(&"identity", "Identity", "Who he is, where he comes from, and what still pulls him forward.", get_identity_fields()),
		_make_section(&"base_attributes", "Base Attributes", "The hard limits and strengths of the man himself.", get_attribute_fields()),
		_make_section(&"condition_stats", "Condition Stats", "The living pressure of nourishment, weather, exhaustion, and morale.", get_condition_fields()),
		_make_section(&"skills", "Skills", "Learned road knowledge, work habits, and survival competence.", get_skill_fields()),
		_make_section(&"traits_perks", "Traits / Perks", "Personal edges, habits, and marks that may later shape opportunities.", get_traits_perks_fields()),
		_make_section(&"reputation_standing", "Reputation / Standing", "How camps, towns, bosses, and law may come to read him over time.", get_reputation_fields()),
		_make_section(&"affiliations", "Affiliations", "People, obligations, and ties that locate him in the wider world.", get_affiliation_fields())
	]


func get_section_by_id(section_id: StringName) -> Dictionary:
	for section in get_sections():
		if StringName(section.get("id", &"")) == section_id:
			return section
	return {}


func get_identity_fields() -> Array:
	return [
		_make_field(&"full_name", "Name", full_name, "The name the player carries into camps, rail yards, and hiring lines."),
		_make_field(&"age", "Age", str(age), "Age will later help frame labor expectations, frailty, and how others read him."),
		_make_field(&"home_town", "Home Town", home_town, "Home town grounds the character in a real life left behind rather than a blank survival avatar."),
		_make_field(&"family_status", "Family Status", family_status, "Family status gives moral pressure to work, travel, and send money home."),
		_make_field(&"current_goal", "Current Goal", current_goal, "The immediate reason he keeps moving. This will later help anchor short-term direction.")
	]


func get_attribute_fields() -> Array:
	return [
		_make_field(&"strength", "Strength", str(strength), "Raw lifting, hauling, striking, and brute work potential."),
		_make_field(&"endurance", "Endurance", str(endurance), "How long he can keep walking, working, and enduring hardship before giving out."),
		_make_field(&"wits", "Wits", str(wits), "Judgment, practical thinking, and reading bad situations before they close."),
		_make_field(&"presence", "Presence", str(presence), "How steady, convincing, or trustworthy he appears to other people."),
		_make_field(&"agility", "Agility", str(agility), "Quickness of body for climbing, slipping away, and moving with care.")
	]


func get_condition_fields() -> Array:
	return [
		_make_condition_field(&"nutrition", "Nutrition", nutrition, "Tracks how well fed and physically supported the body is for labor, travel, and holding together under strain."),
		_make_condition_field(&"stamina", "Stamina", get_stamina(), "Tracks remaining energy for work, travel, and holding together under strain. Low stamina means exhaustion is closing in."),
		_make_condition_field(&"morale", "Morale", morale, "A rough measure of hope, steadiness, and whether the road still feels survivable."),
		_make_condition_field(&"hygiene", "Hygiene", hygiene, "Later this can influence illness, first impressions, police attention, and job access."),
		_make_condition_field(&"presentability", "Presentability", presentability, "How ready he appears for hiring lines, social contact, and being treated as a working man rather than trouble."),
		_make_condition_field(&"warmth", "Warmth", warmth, "Warmth reflects cold exposure, shelter quality, clothing, and fire access.")
	]


func get_stamina() -> int:
	return clampi(100 - fatigue, 0, 100)


func get_skill_fields() -> Array:
	return [
		_make_field(&"hobo_lore", "Hobo Lore", str(hobo_lore), "Road knowledge, signs, camp sense, and understanding how to move without getting blindsided."),
		_make_field(&"labor", "Labor", str(labor), "Capacity for hired work, rough tasks, and proving useful when a foreman needs hands."),
		_make_field(&"fighting", "Fighting", str(fighting), "A blunt measure of self-defense and surviving ugly confrontations."),
		_make_field(&"crafting", "Crafting", str(crafting), "Improvising repairs, making use of scraps, and building survival tools from poor materials."),
		_make_field(&"speech", "Speech", str(speech), "Talking for work, leniency, information, and human goodwill."),
		_make_field(&"stealth", "Stealth", str(stealth), "Keeping quiet, staying out of sight, and moving where trouble is likely."),
		_make_field(&"scavenging", "Scavenging", str(scavenging), "Finding what others miss in yards, camps, and cast-off places.")
	]


func get_identity_summary() -> String:
	return "%s, %d | %s" % [full_name, age, home_town]


func get_traits_perks_fields() -> Array:
	return _make_placeholder_fields(&"traits", traits_perks, "Temporary placeholder entry. Later this section can carry passive bonuses, personality edges, or long-term marks left by the road.")


func get_reputation_fields() -> Array:
	return _make_placeholder_fields(&"reputation", reputation_standing, "Temporary placeholder entry. Later this section can reflect how camps, law, employers, and towns presently regard the player.")


func get_affiliation_fields() -> Array:
	return _make_placeholder_fields(&"affiliation", affiliations, "Temporary placeholder entry. Later this section can track family, camp ties, work contacts, and meaningful social bonds.")


func duplicate_data() -> PlayerPassportData:
	var duplicate_passport = PlayerPassportData.new()
	duplicate_passport.from_save_data(to_save_data())
	return duplicate_passport


func to_save_data() -> Dictionary:
	return {
		"full_name": full_name,
		"age": age,
		"home_town": home_town,
		"family_status": family_status,
		"current_goal": current_goal,
		"strength": strength,
		"endurance": endurance,
		"wits": wits,
		"presence": presence,
		"agility": agility,
		"nutrition": nutrition,
		"fatigue": fatigue,
		"morale": morale,
		"hygiene": hygiene,
		"presentability": presentability,
		"warmth": warmth,
		"hobo_lore": hobo_lore,
		"labor": labor,
		"fighting": fighting,
		"crafting": crafting,
		"speech": speech,
		"stealth": stealth,
		"scavenging": scavenging,
		"traits_perks": Array(traits_perks),
		"reputation_standing": Array(reputation_standing),
		"affiliations": Array(affiliations)
	}


func from_save_data(data: Dictionary) -> void:
	full_name = String(data.get("full_name", full_name))
	age = clampi(int(data.get("age", age)), 14, 90)
	home_town = String(data.get("home_town", home_town))
	family_status = String(data.get("family_status", family_status))
	current_goal = String(data.get("current_goal", current_goal))

	strength = clampi(int(data.get("strength", strength)), 1, 10)
	endurance = clampi(int(data.get("endurance", endurance)), 1, 10)
	wits = clampi(int(data.get("wits", wits)), 1, 10)
	presence = clampi(int(data.get("presence", presence)), 1, 10)
	agility = clampi(int(data.get("agility", agility)), 1, 10)

	var saved_nutrition = data.get("nutrition", null)
	if saved_nutrition == null and data.has("hunger"):
		saved_nutrition = 100 - int(data.get("hunger", 100 - nutrition))
	nutrition = clampi(int(saved_nutrition if saved_nutrition != null else nutrition), 0, 100)
	fatigue = clampi(int(data.get("fatigue", fatigue)), 0, 100)
	morale = clampi(int(data.get("morale", morale)), 0, 100)
	hygiene = clampi(int(data.get("hygiene", hygiene)), 0, 100)
	presentability = clampi(int(data.get("presentability", presentability)), 0, 100)
	warmth = clampi(int(data.get("warmth", warmth)), 0, 100)

	hobo_lore = clampi(int(data.get("hobo_lore", hobo_lore)), 0, 10)
	labor = clampi(int(data.get("labor", labor)), 0, 10)
	fighting = clampi(int(data.get("fighting", fighting)), 0, 10)
	crafting = clampi(int(data.get("crafting", crafting)), 0, 10)
	speech = clampi(int(data.get("speech", speech)), 0, 10)
	stealth = clampi(int(data.get("stealth", stealth)), 0, 10)
	scavenging = clampi(int(data.get("scavenging", scavenging)), 0, 10)

	traits_perks = _to_packed_string_array(data.get("traits_perks", traits_perks))
	reputation_standing = _to_packed_string_array(data.get("reputation_standing", reputation_standing))
	affiliations = _to_packed_string_array(data.get("affiliations", affiliations))


func _make_section(section_id: StringName, title: String, summary: String, fields: Array) -> Dictionary:
	return {
		"id": section_id,
		"title": title,
		"summary": summary,
		"fields": fields
	}


func _make_field(field_id: StringName, label: String, value: String, notes: String) -> Dictionary:
	return {
		"id": field_id,
		"label": label,
		"value": value.strip_edges(),
		"notes": notes
	}


func _make_condition_field(field_id: StringName, label: String, current_value: int, notes: String) -> Dictionary:
	var field = _make_field(field_id, label, _format_percent_stat(current_value), notes)
	field["current"] = clampi(current_value, 0, 100)
	field["max"] = 100
	field["display_as_bar"] = true
	return field


func _make_placeholder_fields(section_prefix: StringName, items: PackedStringArray, notes: String) -> Array:
	var fields: Array = []
	if items.is_empty():
		fields.append(_make_field(StringName("%s_empty" % section_prefix), "No entry yet", "-", "This section is still a placeholder."))
		return fields

	for index in range(items.size()):
		fields.append(_make_field(
			StringName("%s_entry_%d" % [section_prefix, index]),
			String(items[index]),
			"Recorded",
			notes
		))
	return fields


func _format_percent_stat(value: int) -> String:
	return "%d / 100" % clampi(value, 0, 100)


func _to_packed_string_array(value) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		for entry in value:
			result.append(String(entry))
		return result
	if value is Array:
		for entry in value:
			result.append(String(entry))
	return result
