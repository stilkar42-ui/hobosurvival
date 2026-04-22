extends Control

signal request_debug_page
signal request_return_to_menu
signal request_quit_game

const FirstPlayableLoopActionControllerScript := preload("res://scripts/front_end/first_playable_loop_action_controller.gd")
const OverlayBuilderScript := preload("res://scripts/front_end/adapters/overlay_builder.gd")
const DataManagerScript := preload("res://scripts/managers/data_manager.gd")
const EntityManagerScript := preload("res://scripts/managers/entity_manager.gd")
const GameStateManagerScript := preload("res://scripts/managers/game_state_manager.gd")
const InventoryManagerScript := preload("res://scripts/managers/inventory_manager.gd")
const LocationManagerScript := preload("res://scripts/managers/location_manager.gd")
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")
const ReputationManagerScript := preload("res://scripts/managers/reputation_manager.gd")
const StatsManagerScript := preload("res://scripts/managers/stats_manager.gd")
const TimeManagerScript := preload("res://scripts/managers/time_manager.gd")
const UIManagerScript := preload("res://scripts/managers/ui_manager.gd")
const CraftingPageScript := preload("res://scripts/pages/crafting_page.gd")
const EventEncounterPageScript := preload("res://scripts/pages/event_encounter_page.gd")
const InventoryPageScript := preload("res://scripts/pages/inventory_page.gd")
const LocationPageScript := preload("res://scripts/pages/location_page.gd")
const PassportStatsPageScript := preload("res://scripts/pages/passport_stats_page.gd")
const RestCampPageScript := preload("res://scripts/pages/rest_camp_page.gd")
const TravelPageScript := preload("res://scripts/pages/travel_page.gd")
const WorldMapPageScript := preload("res://scripts/pages/world_map_page.gd")

@export var enable_trace_logging := false

@onready var camp_viewport_host: Control = $CampViewportHost
@onready var action_root: VBoxContainer = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot
@onready var summary_title_label: Label = $Root/SummaryPanel/SummaryRoot/SummaryTitle
@onready var summary_stats_label: Label = $Root/SummaryPanel/SummaryRoot/SummaryStats
@onready var condition_stats_label: Label = $Root/SummaryPanel/SummaryRoot/ConditionStats
@onready var goal_label: Label = $Root/SummaryPanel/SummaryRoot/GoalLabel
@onready var status_label: Label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/StatusLabel
@onready var result_panel: PanelContainer = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel
@onready var result_title_label: Label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/ResultTitle
@onready var result_body_label: Label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/ResultBody
@onready var reset_run_button: Button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/ResetRunButton
@onready var go_debug_button: Button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/GoDebugButton
@onready var inventory_summary_panel: PanelContainer = $Root/MainRow/RightColumn/InventorySummaryPanel
@onready var inventory_summary_label: Label = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/InventorySummary
@onready var selected_item_label: Label = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/SelectedItem
@onready var open_inventory_button: Button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/OpenInventoryButton
@onready var open_passport_button: Button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/OpenPassportButton
@onready var open_getting_ready_button: Button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/OpenGettingReadyButton
@onready var return_to_menu_button: Button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/ReturnToMenuButton
@onready var quit_game_button: Button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/QuitGameButton
@onready var inventory_hint_label: Label = $Root/MainRow/RightColumn/InventoryHint
@onready var fade_debug_label: Label = $Root/MainRow/RightColumn/FadeDebugPanel/FadeDebugRoot/FadeDebugLabel
@onready var inventory_overlay: Control = $InventoryOverlay
@onready var inventory_window: PanelContainer = $InventoryOverlay/InventoryMargin/InventoryWindow
@onready var inventory_header: HBoxContainer = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader
@onready var inventory_badge_label: Label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryBadge/InventoryBadgeLabel
@onready var inventory_title_label: Label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryTitle
@onready var close_inventory_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/CloseInventoryButton
@onready var inventory_modal_status_label: Label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryStatus
@onready var inventory_action_summary_label: Label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionSummary
@onready var inventory_destination_label: Label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryDestinationLabel
@onready var inventory_move_cancel_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryMoveCancelButton
@onready var inventory_transfer_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryTransferButton
@onready var inventory_drop_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryDropButton
@onready var inventory_equip_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryEquipButton
@onready var inventory_unequip_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryUnequipButton
@onready var use_selected_in_inventory_button: Button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/UseSelectedInInventoryButton
@onready var inventory_panel = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryContentScroll/InventoryPanel
@onready var inventory_radial_menu = $InventoryOverlay/InventoryRadialMenu
@onready var passport_overlay: Control = $PassportOverlay
@onready var close_passport_button: Button = $PassportOverlay/PassportMargin/PassportWindow/PassportRoot/PassportHeader/ClosePassportButton
@onready var passport_panel = $PassportOverlay/PassportMargin/PassportWindow/PassportRoot/PassportPanel
@onready var getting_ready_overlay: Control = $GettingReadyOverlay
@onready var getting_ready_root: VBoxContainer = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot
@onready var close_getting_ready_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyHeader/CloseGettingReadyButton
@onready var getting_ready_status_label: Label = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyStatus
@onready var getting_ready_stats_label: Label = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyStats
@onready var ready_actions_grid: GridContainer = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions
@onready var ready_fetch_water_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/FetchWaterButton
@onready var ready_wash_body_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/WashBodyButton
@onready var ready_wash_face_hands_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/WashFaceHandsButton
@onready var ready_shave_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/ShaveButton
@onready var ready_comb_groom_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/CombGroomButton
@onready var ready_air_out_clothes_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/AirOutClothesButton
@onready var ready_brush_clothes_button: Button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/BrushClothesButton

var _player_state_service = null
var _camp_isometric_layer = null
var _page_host: VBoxContainer = null
var _last_primary_route: StringName = &""

var _action_controller = FirstPlayableLoopActionControllerScript.new()
var _overlay_builder = OverlayBuilderScript.new()
var _data_manager = DataManagerScript.new()
var _game_state_manager = GameStateManagerScript.new()
var _time_manager = TimeManagerScript.new()
var _stats_manager = StatsManagerScript.new()
var _inventory_manager = InventoryManagerScript.new()
var _location_manager = LocationManagerScript.new()
var _reputation_manager = ReputationManagerScript.new()
var _entity_manager = EntityManagerScript.new()
var _ui_manager = UIManagerScript.new()
var _world_map_page = WorldMapPageScript.new()
var _travel_page = TravelPageScript.new()
var _location_page = LocationPageScript.new()
var _inventory_page = InventoryPageScript.new()
var _crafting_page = CraftingPageScript.new()
var _passport_stats_page = PassportStatsPageScript.new()
var _event_encounter_page = EventEncounterPageScript.new()
var _rest_camp_page = RestCampPageScript.new()


func _ready() -> void:
	call_deferred("_finish_ready")


func _finish_ready() -> void:
	_bootstrap()


func _bootstrap() -> void:
	_player_state_service = PlayerStateRuntimeScript.get_or_create_service(self)
	_configure_managers()
	_action_controller.configure(_game_state_manager, enable_trace_logging)
	camp_viewport_host.visible = false
	inventory_overlay.visible = false
	passport_overlay.visible = false
	getting_ready_overlay.visible = false
	_hide_legacy_action_controls()
	_build_page_host()
	_bootstrap_pages()
	_register_pages_with_ui_manager()
	_connect_global_signals()
	_event_encounter_page.show_status("Take stock of the day, find work, and send something home before the road hollows you out.")
	_sync_route_with_state(_game_state_manager.get_player_state())


func _configure_managers() -> void:
	_data_manager.configure(_player_state_service)
	_game_state_manager.configure(_player_state_service)
	_stats_manager.configure(_player_state_service)
	_inventory_manager.configure(_player_state_service)
	_reputation_manager.configure(_player_state_service)


func _hide_legacy_action_controls() -> void:
	for child in action_root.get_children():
		if child == status_label or child == result_panel:
			continue
		if child is CanvasItem:
			child.visible = false


func _build_page_host() -> void:
	_page_host = VBoxContainer.new()
	_page_host.name = "PageHost"
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_host.add_theme_constant_override("separation", 10)
	action_root.add_child(_page_host)
	action_root.move_child(_page_host, status_label.get_index() + 1)


func _bootstrap_pages() -> void:
	_event_encounter_page.bootstrap(self, {
		"status_label": status_label,
		"result_panel": result_panel,
		"result_title_label": result_title_label,
		"result_body_label": result_body_label,
		"reset_run_button": reset_run_button,
		"go_debug_button": go_debug_button,
		"game_state_manager": _game_state_manager,
		"build_action_context": Callable(_action_controller, "build_action_context"),
		"execute_state_action": Callable(_action_controller, "execute_state_action"),
		"request_debug_page": Callable(self, "_emit_debug_page")
	})

	var common_deps := {
		"scene_root": self,
		"page_host": _page_host,
		"data_manager": _data_manager,
		"game_state_manager": _game_state_manager,
		"time_manager": _time_manager,
		"stats_manager": _stats_manager,
		"inventory_manager": _inventory_manager,
		"location_manager": _location_manager,
		"reputation_manager": _reputation_manager,
		"entity_manager": _entity_manager,
		"ui_manager": _ui_manager,
		"overlay_builder": _overlay_builder,
		"build_action_context": Callable(_action_controller, "build_action_context"),
		"execute_state_action": Callable(_action_controller, "execute_state_action"),
		"format_status_with_debug": Callable(_action_controller, "format_status_with_debug"),
		"show_status": Callable(_event_encounter_page, "show_status"),
		"show_action_result": Callable(_event_encounter_page, "show_action_result"),
		"resolve_return_route": Callable(self, "_get_return_route"),
		"request_return_to_menu": Callable(self, "_emit_return_to_menu"),
		"request_quit_game": Callable(self, "_emit_quit_game"),
		"request_debug_page": Callable(self, "_emit_debug_page")
	}

	_world_map_page.bootstrap(self, common_deps.merged({
		"summary_title_label": summary_title_label,
		"summary_stats_label": summary_stats_label,
		"condition_stats_label": condition_stats_label,
		"goal_label": goal_label,
		"fade_debug_label": fade_debug_label,
		"open_inventory_button": open_inventory_button,
		"open_passport_button": open_passport_button,
		"open_routes_button": open_getting_ready_button,
		"return_to_menu_button": return_to_menu_button,
		"quit_game_button": quit_game_button
	}, true))
	_travel_page.bootstrap(self, common_deps)
	_location_page.bootstrap(self, common_deps)
	_crafting_page.bootstrap(self, common_deps)
	_rest_camp_page.bootstrap(self, common_deps.merged({
		"overlay": getting_ready_overlay,
		"root": getting_ready_root,
		"status_label": getting_ready_status_label,
		"stats_label": getting_ready_stats_label,
		"close_button": close_getting_ready_button,
		"ready_actions_grid": ready_actions_grid,
		"fetch_water_button": ready_fetch_water_button,
		"wash_body_button": ready_wash_body_button,
		"wash_face_hands_button": ready_wash_face_hands_button,
		"shave_button": ready_shave_button,
		"comb_groom_button": ready_comb_groom_button,
		"air_out_clothes_button": ready_air_out_clothes_button,
		"brush_clothes_button": ready_brush_clothes_button
	}, true))
	_inventory_page.bootstrap(self, common_deps.merged({
		"overlay": inventory_overlay,
		"window": inventory_window,
		"header": inventory_header,
		"badge_label": inventory_badge_label,
		"title_label": inventory_title_label,
		"close_button": close_inventory_button,
		"summary_label": inventory_summary_label,
		"selected_item_label": selected_item_label,
		"hint_label": inventory_hint_label,
		"modal_status_label": inventory_modal_status_label,
		"action_summary_label": inventory_action_summary_label,
		"destination_label": inventory_destination_label,
		"move_cancel_button": inventory_move_cancel_button,
		"transfer_button": inventory_transfer_button,
		"drop_button": inventory_drop_button,
		"equip_button": inventory_equip_button,
		"unequip_button": inventory_unequip_button,
		"use_button": use_selected_in_inventory_button,
		"inventory_panel": inventory_panel,
		"inventory_radial_menu": inventory_radial_menu,
		"open_inventory_button": open_inventory_button
	}, true))
	_passport_stats_page.bootstrap(self, common_deps.merged({
		"overlay": passport_overlay,
		"close_button": close_passport_button,
		"passport_panel": passport_panel,
		"open_passport_button": open_passport_button
	}, true))


func _register_pages_with_ui_manager() -> void:
	_ui_manager.register_page(&"WorldMapPage", _world_map_page)
	_ui_manager.register_page(&"TravelPage", _travel_page)
	_ui_manager.register_page(&"LocationPage", _location_page)
	_ui_manager.register_page(&"InventoryPage", _inventory_page)
	_ui_manager.register_page(&"CraftingPage", _crafting_page)
	_ui_manager.register_page(&"PassportStatsPage", _passport_stats_page)
	_ui_manager.register_page(&"EventEncounterPage", _event_encounter_page)
	_ui_manager.register_page(&"RestCampPage", _rest_camp_page)

	_ui_manager.register_route(_location_manager.PAGE_TOWN, &"WorldMapPage")
	_ui_manager.register_route(_location_manager.PAGE_CAMP, &"WorldMapPage")
	_ui_manager.register_route(_location_manager.ROUTE_TRAVEL, &"TravelPage")
	_ui_manager.register_route(_location_manager.PAGE_JOBS_BOARD, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_SEND_MONEY, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_GROCERY, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_HARDWARE, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_HOBOCRAFT, &"CraftingPage")
	_ui_manager.register_route(_location_manager.PAGE_COOKING, &"CraftingPage")
	_ui_manager.register_route(_location_manager.PAGE_GETTING_READY, &"RestCampPage")
	_ui_manager.register_route(_location_manager.PAGE_REST_CAMP, &"RestCampPage")
	_ui_manager.register_route(_location_manager.ROUTE_INVENTORY, &"InventoryPage")
	_ui_manager.register_route(_location_manager.ROUTE_PASSPORT, &"PassportStatsPage")
	_ui_manager.register_route(_location_manager.ROUTE_EVENT, &"EventEncounterPage")


func _connect_global_signals() -> void:
	if not _game_state_manager.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
		_game_state_manager.player_state_changed.connect(Callable(self, "_on_player_state_changed"))
	if not _game_state_manager.load_finished.is_connected(Callable(self, "_on_state_message")):
		_game_state_manager.load_finished.connect(Callable(self, "_on_state_message"))
	if not _game_state_manager.reset_finished.is_connected(Callable(self, "_on_state_message")):
		_game_state_manager.reset_finished.connect(Callable(self, "_on_state_message"))
	if not _ui_manager.route_changed.is_connected(Callable(self, "_on_route_changed")):
		_ui_manager.route_changed.connect(Callable(self, "_on_route_changed"))


func _on_player_state_changed(player_state) -> void:
	_sync_route_with_state(player_state)


func _on_state_message(_success: bool, message: String) -> void:
	_event_encounter_page.show_status(message)


func _on_route_changed(route_name: StringName, _page_name: StringName) -> void:
	if not _location_manager.is_overlay_route(route_name):
		_last_primary_route = route_name


func _sync_route_with_state(player_state) -> void:
	var location_id = player_state.loop_location_id if player_state != null else &""
	var route = _ui_manager.get_active_route()
	if route == &"":
		route = _location_manager.get_default_route_for_location(location_id)
	route = _location_manager.normalize_route_for_location(route, location_id)
	if route == &"":
		route = _location_manager.PAGE_TOWN
	if not _ui_manager.switch_to(route):
		_ui_manager.switch_to(_location_manager.PAGE_TOWN)
	if not _location_manager.is_overlay_route(route):
		_last_primary_route = route


func _get_return_route() -> StringName:
	if _last_primary_route != &"":
		return _last_primary_route
	var player_state = _game_state_manager.get_player_state()
	var location_id = player_state.loop_location_id if player_state != null else &""
	return _location_manager.get_default_route_for_location(location_id)


func _unhandled_input(event: InputEvent) -> void:
	var active_page = _ui_manager.get_page(_ui_manager.get_active_page())
	if active_page != null and active_page.has_method("handle_input") and active_page.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	for page in [_inventory_page, _passport_stats_page, _rest_camp_page]:
		if page == active_page:
			continue
		if page != null and page.has_method("handle_input") and page.handle_input(event):
			get_viewport().set_input_as_handled()
			return


func _emit_debug_page() -> void:
	request_debug_page.emit()


func _emit_return_to_menu() -> void:
	request_return_to_menu.emit()


func _emit_quit_game() -> void:
	request_quit_game.emit()
