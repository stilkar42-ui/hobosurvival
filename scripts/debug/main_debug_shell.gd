extends Control

const PAGE_START := &"start"
const PAGE_PASSPORT := &"passport"
const PAGE_INVENTORY := &"inventory"
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")
const PlayerStateServiceScript := preload("res://scripts/player/player_state_service.gd")

const PASSPORT_SCENE := preload("res://scenes/debug/hobo_passport_debug_scene.tscn")
const INVENTORY_SCENE := preload("res://scenes/debug/inventory_debug_scene.tscn")

@onready var page_title_label = $Root/Sidebar/SidebarRoot/PageTitle
@onready var page_status_label = $Root/Sidebar/SidebarRoot/PageStatus
@onready var start_button = $Root/Sidebar/SidebarRoot/StartButton
@onready var passport_button = $Root/Sidebar/SidebarRoot/PassportButton
@onready var inventory_button = $Root/Sidebar/SidebarRoot/InventoryButton
@onready var state_summary_label = $Root/Sidebar/SidebarRoot/StateSummary
@onready var save_button = $Root/Sidebar/SidebarRoot/SaveButton
@onready var load_button = $Root/Sidebar/SidebarRoot/LoadButton
@onready var reset_button = $Root/Sidebar/SidebarRoot/ResetButton
@onready var state_action_label = $Root/Sidebar/SidebarRoot/StateAction
@onready var content_host = $Root/ContentPanel/ContentHost

var _page_scenes := {
	PAGE_PASSPORT: PASSPORT_SCENE,
	PAGE_INVENTORY: INVENTORY_SCENE
}

var _page_instances := {}
var _current_page: StringName = &""


func _ready() -> void:
	start_button.pressed.connect(Callable(self, "_on_nav_pressed").bind(PAGE_START))
	passport_button.pressed.connect(Callable(self, "_on_nav_pressed").bind(PAGE_PASSPORT))
	inventory_button.pressed.connect(Callable(self, "_on_nav_pressed").bind(PAGE_INVENTORY))
	_connect_state_controls()
	_refresh_state_summary()
	_show_page(PAGE_START)


func _on_nav_pressed(page_id: StringName) -> void:
	_show_page(page_id)


func _show_page(page_id: StringName) -> void:
	if _current_page == page_id and content_host.get_child_count() > 0:
		return

	_clear_content_host()
	var page = _get_or_create_page(page_id)
	content_host.add_child(page)
	_current_page = page_id
	_refresh_navigation()
	_update_page_text()


func _get_or_create_page(page_id: StringName) -> Control:
	if _page_instances.has(page_id):
		return _page_instances[page_id]

	var page: Control
	if page_id == PAGE_START:
		page = _build_start_page()
	else:
		var packed_scene: PackedScene = _page_scenes.get(page_id)
		page = packed_scene.instantiate()

	page.name = "%sPage" % String(page_id).capitalize()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_instances[page_id] = page
	return page


func _build_start_page() -> Control:
	var scroller = ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root = VBoxContainer.new()
	root.name = "StartPage"
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.add_child(root)

	var title = Label.new()
	title.text = "Hobo Survival Prototype Shell"
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var intro = Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "This front-end shell is the rough camp table for the current prototype. Use the buttons on the left to move between the character passport and the inventory rig instead of launching each subsystem directly."
	root.add_child(intro)

	var notes_panel = PanelContainer.new()
	notes_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(notes_panel)

	var notes = VBoxContainer.new()
	notes.add_theme_constant_override("separation", 8)
	notes_panel.add_child(notes)

	var notes_title = Label.new()
	notes_title.text = "Current Prototype Pages"
	notes_title.add_theme_font_size_override("font_size", 18)
	notes.add_child(notes_title)

	notes.add_child(_make_note_label("- Passport: identity, condition, skills, and placeholder standing data."))
	notes.add_child(_make_note_label("- Inventory: gear-based carry and storage debug rig."))
	notes.add_child(_make_note_label("- Shared player state: passport profile, inventory state, hand/loadout ownership, money, time, and future hooks now live together in one authoritative backbone."))
	notes.add_child(_make_note_label("- More pages can be plugged into this shell later without changing the navigation pattern."))

	return scroller


func _make_note_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _refresh_navigation() -> void:
	start_button.disabled = _current_page == PAGE_START
	passport_button.disabled = _current_page == PAGE_PASSPORT
	inventory_button.disabled = _current_page == PAGE_INVENTORY


func _update_page_text() -> void:
	match _current_page:
		PAGE_START:
			page_title_label.text = "Start Page"
			page_status_label.text = "Default landing page for the prototype shell."
		PAGE_PASSPORT:
			page_title_label.text = "Passport"
			page_status_label.text = "Showing the existing Hobo Passport prototype, now reading from shared player state."
		PAGE_INVENTORY:
			page_title_label.text = "Inventory"
			page_status_label.text = "Showing the existing inventory debug rig, now reading from shared player state."
		_:
			page_title_label.text = "Unknown Page"
			page_status_label.text = "No page description available."


func _connect_state_controls() -> void:
	save_button.pressed.connect(Callable(self, "_on_save_pressed"))
	load_button.pressed.connect(Callable(self, "_on_load_pressed"))
	reset_button.pressed.connect(Callable(self, "_on_reset_pressed"))

	var player_state_service = _get_player_state_service()
	if player_state_service == null:
		state_summary_label.text = "Shared player state service is unavailable."
		state_action_label.text = "Save/Load controls are disabled."
		save_button.disabled = true
		load_button.disabled = true
		reset_button.disabled = true
		return

	save_button.disabled = false
	load_button.disabled = false
	reset_button.disabled = false
	state_action_label.text = "Shared state live at %s." % player_state_service.get_path()

	if not player_state_service.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
		player_state_service.player_state_changed.connect(Callable(self, "_on_player_state_changed"))
	if not player_state_service.save_finished.is_connected(Callable(self, "_on_save_finished")):
		player_state_service.save_finished.connect(Callable(self, "_on_save_finished"))
	if not player_state_service.load_finished.is_connected(Callable(self, "_on_load_finished")):
		player_state_service.load_finished.connect(Callable(self, "_on_load_finished"))
	if not player_state_service.reset_finished.is_connected(Callable(self, "_on_reset_finished")):
		player_state_service.reset_finished.connect(Callable(self, "_on_reset_finished"))


func _on_save_pressed() -> void:
	var player_state_service = _get_player_state_service()
	if player_state_service != null:
		player_state_service.save_current_state()


func _on_load_pressed() -> void:
	var player_state_service = _get_player_state_service()
	if player_state_service != null:
		player_state_service.load_current_state()


func _on_reset_pressed() -> void:
	var player_state_service = _get_player_state_service()
	if player_state_service != null:
		player_state_service.execute_action(String(PlayerStateServiceScript.ACTION_RESET_TO_STARTER))


func _on_player_state_changed(_player_state) -> void:
	_refresh_state_summary()


func _on_save_finished(_success: bool, message: String) -> void:
	state_action_label.text = message
	_refresh_state_summary()


func _on_load_finished(_success: bool, message: String) -> void:
	state_action_label.text = message
	_refresh_state_summary()


func _on_reset_finished(_success: bool, message: String) -> void:
	state_action_label.text = message
	_refresh_state_summary()


func _refresh_state_summary() -> void:
	var player_state_service = _get_player_state_service()
	if player_state_service == null:
		state_summary_label.text = "Shared player state service is unavailable."
		return
	var player_state = player_state_service.get_player_state()
	var passport_status = "passport missing"
	var inventory_status = "inventory missing"
	if player_state != null and player_state.passport_profile != null:
		passport_status = "passport assigned"
	if player_state != null and player_state.inventory_state != null:
		inventory_status = "inventory assigned"
	state_summary_label.text = "%s\n%s\n%s | %s" % [
		String(player_state_service.get_path()),
		player_state_service.get_debug_summary(),
		passport_status,
		inventory_status
	]


func _clear_content_host() -> void:
	for child in content_host.get_children():
		content_host.remove_child(child)


func _get_player_state_service():
	return PlayerStateRuntimeScript.get_or_create_service(self)
