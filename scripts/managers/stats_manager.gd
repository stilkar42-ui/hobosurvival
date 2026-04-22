class_name StatsManager
extends RefCounted

var _player_state_service = null


func configure(player_state_service):
	_player_state_service = player_state_service
	return self


func get_passport_profile(player_state = null):
	var resolved_player_state = player_state if player_state != null else _get_player_state()
	if resolved_player_state == null:
		return null
	return resolved_player_state.passport_profile


func get_stat(player_state, stat_name: StringName, default_value = 0):
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return default_value
	return passport_profile.get(stat_name) if passport_profile.get(stat_name) != null else default_value


func set_stat(player_state, stat_name: StringName, value) -> bool:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return false
	passport_profile.set(stat_name, value)
	return true


func get_stamina(player_state = null) -> int:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null or not passport_profile.has_method("get_stamina"):
		return 0
	return passport_profile.get_stamina()


func get_condition_snapshot(player_state = null) -> Dictionary:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return {}
	return {
		"nutrition": passport_profile.nutrition,
		"fatigue": passport_profile.fatigue,
		"morale": passport_profile.morale,
		"hygiene": passport_profile.hygiene,
		"presentability": passport_profile.presentability,
		"warmth": passport_profile.warmth,
		"stamina": get_stamina(player_state)
	}


func _get_player_state():
	if _player_state_service == null or not _player_state_service.has_method("get_player_state"):
		return null
	return _player_state_service.get_player_state()
