class_name ReputationManager
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


func get_reputation_standing(player_state = null) -> PackedStringArray:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return PackedStringArray()
	return passport_profile.reputation_standing.duplicate()


func set_reputation_standing(entries: PackedStringArray, player_state = null) -> bool:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return false
	passport_profile.reputation_standing = entries.duplicate()
	return true


func get_affiliations(player_state = null) -> PackedStringArray:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return PackedStringArray()
	return passport_profile.affiliations.duplicate()


func set_affiliations(entries: PackedStringArray, player_state = null) -> bool:
	var passport_profile = get_passport_profile(player_state)
	if passport_profile == null:
		return false
	passport_profile.affiliations = entries.duplicate()
	return true


func get_snapshot(player_state = null) -> Dictionary:
	return {
		"standing": Array(get_reputation_standing(player_state)),
		"affiliations": Array(get_affiliations(player_state))
	}


func _get_player_state():
	if _player_state_service == null or not _player_state_service.has_method("get_player_state"):
		return null
	return _player_state_service.get_player_state()
