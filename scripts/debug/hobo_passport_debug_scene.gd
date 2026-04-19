extends Control

const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")

@onready var passport_panel = $Root/HoboPassportPanel
@onready var status_label = $Root/Sidebar/SidebarRoot/StatusLabel

var _player_state_service = null


func _ready() -> void:
	_player_state_service = PlayerStateRuntimeScript.get_or_create_service(self)
	if _player_state_service == null:
		passport_panel.set_passport_data(null)
		_set_status("No shared player state service is available.")
		return

	if not _player_state_service.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
		_player_state_service.player_state_changed.connect(Callable(self, "_on_player_state_changed"))
	_apply_player_state(_player_state_service.get_player_state())


func _exit_tree() -> void:
	# The debug shell caches this page and swaps it back into view later, so the shared
	# state connection should survive temporary tree exits.
	pass


func _on_player_state_changed(player_state) -> void:
	_apply_player_state(player_state)


func _apply_player_state(player_state) -> void:
	if player_state == null or player_state.passport_profile == null:
		passport_panel.set_passport_data(null)
		_set_status("Shared player state is live, but no passport profile is assigned.")
		return

	passport_panel.set_passport_data(player_state.passport_profile)
	_set_status("Passport now reads directly from PlayerState.passport_profile for %s. Identity, condition, standing, and future dialogue/work hooks all share the same authoritative backbone." % player_state.passport_profile.full_name)


func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message
