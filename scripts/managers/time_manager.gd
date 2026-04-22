class_name TimeManager
extends RefCounted


func advance_time(player_state, minutes: int) -> void:
	if player_state == null or not player_state.has_method("advance_time"):
		return
	player_state.advance_time(minutes)


func format_duration(minutes: int) -> String:
	if minutes >= 60 and minutes % 60 == 0:
		return "%dh" % int(minutes / 60)
	if minutes >= 60:
		return "%dh %02dm" % [int(minutes / 60), minutes % 60]
	return "%dm" % minutes


func get_time_of_day_label(player_state) -> String:
	if player_state == null or not player_state.has_method("get_time_of_day_label"):
		return ""
	return player_state.get_time_of_day_label()


func get_current_day(player_state) -> int:
	if player_state == null:
		return 0
	return int(player_state.current_day)
