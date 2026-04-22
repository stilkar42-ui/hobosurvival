extends Control

signal request_debug_page
signal request_return_to_menu
signal request_quit_game

const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")
const FirstPlayableLoopActionControllerScript := preload("res://scripts/front_end/first_playable_loop_action_controller.gd")
const OverlayBuilderScript := preload("res://scripts/front_end/adapters/overlay_builder.gd")
const FirstPlayableLoopLayoutControllerScript := preload("res://scripts/front_end/first_playable_loop_layout_controller.gd")
const FirstPlayableLoopNavigationControllerScript := preload("res://scripts/front_end/first_playable_loop_navigation_controller.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")
const DataManagerScript := preload("res://scripts/managers/data_manager.gd")
const EntityManagerScript := preload("res://scripts/managers/entity_manager.gd")
const GameStateManagerScript := preload("res://scripts/managers/game_state_manager.gd")
const InventoryManagerScript := preload("res://scripts/managers/inventory_manager.gd")
const LocationManagerScript := preload("res://scripts/managers/location_manager.gd")
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")
const PlayerStateServiceScript := preload("res://scripts/player/player_state_service.gd")
const StatsManagerScript := preload("res://scripts/managers/stats_manager.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
const TimeManagerScript := preload("res://scripts/managers/time_manager.gd")
const UIManagerScript := preload("res://scripts/managers/ui_manager.gd")
const CampIsometricLayerScene := preload("res://scenes/front_end/camp_isometric_play_layer.tscn")

const INVENTORY_MENU_MOVE_TO := 2001
const INVENTORY_MENU_DROP := 2002
const INVENTORY_MENU_EQUIP := 2003
const INVENTORY_MENU_UNEQUIP := 2004
const INVENTORY_MENU_USE := 2005
const INVENTORY_MENU_INSPECT := 2006
const INVENTORY_MENU_CANCEL := 2007
const INVENTORY_MENU_OPEN := 2008
const INVENTORY_MENU_READ := 2009

const PAGE_TOWN := &"town"
const PAGE_JOBS_BOARD := &"jobs_board"
const PAGE_SEND_MONEY := &"send_money"
const PAGE_CAMP := &"camp"
const PAGE_GROCERY := &"grocery"
const PAGE_HARDWARE := &"hardware"
const PAGE_GETTING_READY := &"getting_ready"
const PAGE_HOBOCRAFT := &"hobocraft"
const PAGE_COOKING := &"cooking"

@export var enable_trace_logging := false

@onready var root_layout = $Root
@onready var camp_viewport_host = $CampViewportHost
@onready var summary_panel = $Root/SummaryPanel
@onready var main_row = $Root/MainRow
@onready var actions_panel = $Root/MainRow/ActionsPanel
@onready var action_scroll = $Root/MainRow/ActionsPanel/ActionScroll
@onready var right_column = $Root/MainRow/RightColumn

@onready var summary_title_label = $Root/SummaryPanel/SummaryRoot/SummaryTitle
@onready var summary_stats_label = $Root/SummaryPanel/SummaryRoot/SummaryStats
@onready var condition_stats_label = $Root/SummaryPanel/SummaryRoot/ConditionStats
@onready var goal_label = $Root/SummaryPanel/SummaryRoot/GoalLabel

@onready var status_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/StatusLabel
@onready var work_summary_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/WorkSummary
@onready var jobs_list = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/JobsList
@onready var supplies_summary_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/SuppliesSummary
@onready var buy_bread_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyBreadButton
@onready var buy_coffee_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyCoffeeButton
@onready var buy_stew_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyStewButton
@onready var buy_tobacco_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyTobaccoButton
@onready var buy_grocery_beans_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyGroceryBeansButton
@onready var buy_grocery_potted_meat_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyGroceryPottedMeatButton
@onready var buy_coffee_grounds_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyCoffeeGroundsButton
@onready var buy_hardware_matches_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyHardwareMatchesButton
@onready var buy_hardware_empty_can_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyHardwareEmptyCanButton
@onready var buy_hardware_cordage_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuyHardwareCordageButton
@onready var use_selected_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/UseSelectedButton
@onready var family_summary_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/FamilySummary
@onready var send_small_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/SendSmallButton
@onready var send_large_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/SendLargeButton
@onready var camp_summary_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/CampSummary
@onready var build_fire_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BuildFireButton
@onready var tend_fire_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/TendFireButton
@onready var gather_kindling_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/GatherKindlingButton
@onready var brew_camp_coffee_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/BrewCampCoffeeButton
@onready var time_summary_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/TimeSummary
@onready var wait_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/WaitButton
@onready var sell_scrap_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/SellScrapButton
@onready var sleep_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/SleepButton
@onready var result_panel = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel
@onready var result_title_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/ResultTitle
@onready var result_body_label = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/ResultBody
@onready var reset_run_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/ResetRunButton
@onready var go_debug_button = $Root/MainRow/ActionsPanel/ActionScroll/ActionRoot/ResultPanel/ResultRoot/GoDebugButton

@onready var inventory_summary_panel = $Root/MainRow/RightColumn/InventorySummaryPanel
@onready var inventory_summary_label = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/InventorySummary
@onready var selected_item_label = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/SelectedItem
@onready var open_inventory_button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/OpenInventoryButton
@onready var open_passport_button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/OpenPassportButton
@onready var open_getting_ready_button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/OpenGettingReadyButton
@onready var return_to_menu_button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/ReturnToMenuButton
@onready var quit_game_button = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot/QuitGameButton
@onready var inventory_hint_label = $Root/MainRow/RightColumn/InventoryHint
@onready var fade_debug_panel = $Root/MainRow/RightColumn/FadeDebugPanel
@onready var fade_debug_label = $Root/MainRow/RightColumn/FadeDebugPanel/FadeDebugRoot/FadeDebugLabel

@onready var inventory_overlay = $InventoryOverlay
@onready var inventory_overlay_backdrop = $InventoryOverlay/Backdrop
@onready var inventory_margin = $InventoryOverlay/InventoryMargin
@onready var inventory_window = $InventoryOverlay/InventoryMargin/InventoryWindow
@onready var inventory_header = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader
@onready var inventory_badge = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryBadge
@onready var inventory_badge_label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryBadge/InventoryBadgeLabel
@onready var inventory_title_label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/InventoryTitle
@onready var close_inventory_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryHeader/CloseInventoryButton
@onready var inventory_modal_status_label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryStatus
@onready var inventory_actions_panel = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel
@onready var inventory_action_summary_label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionSummary
@onready var inventory_destination_label = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryDestinationLabel
@onready var inventory_move_cancel_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryMoveCancelButton
@onready var inventory_action_buttons = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons
@onready var inventory_transfer_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryTransferButton
@onready var inventory_drop_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryDropButton
@onready var inventory_equip_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryEquipButton
@onready var inventory_unequip_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/InventoryUnequipButton
@onready var use_selected_in_inventory_button = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryActionsPanel/InventoryActionsRoot/InventoryActionButtons/UseSelectedInInventoryButton
@onready var inventory_panel = $InventoryOverlay/InventoryMargin/InventoryWindow/InventoryRoot/InventoryContentScroll/InventoryPanel
@onready var inventory_radial_menu = $InventoryOverlay/InventoryRadialMenu

@onready var passport_overlay = $PassportOverlay
@onready var close_passport_button = $PassportOverlay/PassportMargin/PassportWindow/PassportRoot/PassportHeader/ClosePassportButton
@onready var passport_panel = $PassportOverlay/PassportMargin/PassportWindow/PassportRoot/PassportPanel

@onready var getting_ready_overlay = $GettingReadyOverlay
@onready var close_getting_ready_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyHeader/CloseGettingReadyButton
@onready var getting_ready_status_label = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyStatus
@onready var getting_ready_stats_label = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyStats
@onready var ready_fetch_water_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/FetchWaterButton
@onready var ready_wash_body_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/WashBodyButton
@onready var ready_wash_face_hands_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/WashFaceHandsButton
@onready var ready_shave_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/ShaveButton
@onready var ready_comb_groom_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/CombGroomButton
@onready var ready_air_out_clothes_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/AirOutClothesButton
@onready var ready_brush_clothes_button = $GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow/GettingReadyRoot/GettingReadyActions/BrushClothesButton

var _player_state_service = null
var _last_status_message := "Take stock of the day, find work, and send something home before the road hollows you out."
var _last_inventory_message := "Drag anything visible to a visible place. Click to inspect."
var _last_getting_ready_message := "Clean up, straighten yourself, and get fit to be seen."
var _last_action_debug_message := ""
var _inventory_move_request := {}
var _inventory_context_stack_index := -1
var _inventory_context_provider_id := &""
var _active_loop_page: StringName = PAGE_TOWN
var _page_nav_row: HBoxContainer
var _town_page_panel: PanelContainer
var _jobs_board_page_panel: PanelContainer
var _send_money_page_panel: PanelContainer
var _camp_page_panel: PanelContainer
var _grocery_page_panel: PanelContainer
var _hardware_page_panel: PanelContainer
var _getting_ready_page_panel: PanelContainer
var _hobocraft_page_panel: PanelContainer
var _cooking_page_panel: PanelContainer
var _town_page_root: VBoxContainer
var _jobs_board_page_root: VBoxContainer
var _send_money_page_root: VBoxContainer
var _camp_page_root: VBoxContainer
var _grocery_page_root: VBoxContainer
var _hardware_page_root: VBoxContainer
var _getting_ready_page_root: VBoxContainer
var _hobocraft_page_root: VBoxContainer
var _cooking_page_root: VBoxContainer
var _go_to_camp_button: Button
var _return_to_town_button: Button
var _open_jobs_board_button: Button
var _open_send_money_page_button: Button
var _open_grocery_page_button: Button
var _open_hardware_page_button: Button
var _open_getting_ready_page_button: Button
var _open_hobocraft_page_button: Button
var _open_cooking_page_button: Button
var _back_to_town_from_grocery_button: Button
var _back_to_town_from_hardware_button: Button
var _back_to_town_from_jobs_button: Button
var _back_to_town_from_send_money_button: Button
var _back_to_camp_from_ready_button: Button
var _back_to_camp_from_hobocraft_button: Button
var _back_to_camp_from_cooking_button: Button
var _hardware_summary_label: Label
var _send_money_summary_label: Label
var _pending_support_label: Label
var _send_custom_amount_label: Label
var _send_amount_spinbox: SpinBox
var _send_mail_custom_button: Button
var _send_telegraph_custom_button: Button
var _grocery_stock_list: VBoxContainer
var _hardware_stock_list: VBoxContainer
var _hobocraft_recipe_list: VBoxContainer
var _hobocraft_detail_root: VBoxContainer
var _cooking_recipe_list: VBoxContainer
var _cooking_detail_root: VBoxContainer
var _cooking_filter_button: Button
var _condition_bars_root: GridContainer
var _camp_nav_panel: PanelContainer
var _camp_nav_root: VBoxContainer
var _camp_nav_status_label: Label
var _camp_isometric_layer: Control
var _camp_world_host_trace_pending := false
var _inventory_open_context: StringName = &"carried"
var _inventory_window_dragging := false
var _inventory_window_drag_offset := Vector2.ZERO
var _inventory_window_resizing := false
var _inventory_window_rect := Rect2(700.0, 40.0, 560.0, 560.0)
var _inventory_resize_handle: PanelContainer
var _inventory_container_popups: Dictionary = {}
var _inventory_container_popup_drag_id: StringName = &""
var _inventory_container_popup_drag_offset := Vector2.ZERO
var _selected_hobocraft_recipe_id: StringName = &""
var _selected_cooking_recipe_id: StringName = &""
var _expanded_hobocraft_overlay_categories: Dictionary = {}
var _expanded_cooking_overlay_categories: Dictionary = {}
var _show_only_makeable_cooking := false
var _selected_rest_hours := 8
var _selected_sleep_item_id: StringName = &""
var _selected_send_amount_cents := 125
var _did_finish_ready := false
var _did_apply_default_camp_start := false
var _layout_controller = FirstPlayableLoopLayoutControllerScript.new()
var _navigation_controller = FirstPlayableLoopNavigationControllerScript.new()
var _action_controller = FirstPlayableLoopActionControllerScript.new()
var _overlay_builder = OverlayBuilderScript.new()
var _data_manager = DataManagerScript.new()
var _game_state_manager = GameStateManagerScript.new()
var _time_manager = TimeManagerScript.new()
var _stats_manager = StatsManagerScript.new()
var _inventory_manager = InventoryManagerScript.new()
var _location_manager = LocationManagerScript.new()
var _entity_manager = EntityManagerScript.new()
var _ui_manager = UIManagerScript.new()


func _ready() -> void:
	call_deferred("_finish_ready")


func _finish_ready() -> void:
	if _did_finish_ready:
		return
	_did_finish_ready = true
	_build_location_pages()
	_apply_styles()
	_connect_buttons()
	inventory_overlay.visible = false
	passport_overlay.visible = false
	getting_ready_overlay.visible = false
	if inventory_header != null and not inventory_header.gui_input.is_connected(Callable(self, "_on_inventory_header_gui_input")):
		inventory_header.gui_input.connect(Callable(self, "_on_inventory_header_gui_input"))
	_ensure_inventory_resize_handle()
	inventory_panel.use_focused_container_popups = false
	inventory_action_buttons.visible = false
	inventory_radial_menu.hide_menu()
	inventory_panel.stack_selected.connect(Callable(self, "_on_inventory_selection_changed"))
	inventory_panel.container_selected.connect(Callable(self, "_on_inventory_selection_changed"))
	inventory_panel.destination_focus_changed.connect(Callable(self, "_on_inventory_destination_focus_changed"))
	inventory_panel.stack_context_requested.connect(Callable(self, "_on_inventory_stack_context_requested"))
	inventory_panel.container_context_requested.connect(Callable(self, "_on_inventory_container_context_requested"))
	inventory_panel.move_requested.connect(Callable(self, "_on_inventory_move_requested"))
	inventory_panel.container_popup_requested.connect(Callable(self, "_on_inventory_container_popup_requested"))
	inventory_radial_menu.action_selected.connect(Callable(self, "_on_inventory_context_menu_id_pressed"))
	inventory_radial_menu.canceled.connect(Callable(self, "_on_inventory_context_menu_canceled"))

	_player_state_service = PlayerStateRuntimeScript.get_or_create_service(self)
	_configure_managers()
	_register_pages_with_ui_manager()
	_action_controller.configure(_game_state_manager, enable_trace_logging)
	if _game_state_manager != null:
		if not _game_state_manager.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
			_game_state_manager.player_state_changed.connect(Callable(self, "_on_player_state_changed"))
		if not _game_state_manager.load_finished.is_connected(Callable(self, "_on_state_message")):
			_game_state_manager.load_finished.connect(Callable(self, "_on_state_message"))
		if not _game_state_manager.reset_finished.is_connected(Callable(self, "_on_state_message")):
			_game_state_manager.reset_finished.connect(Callable(self, "_on_state_message"))
		_bind_player_state(_game_state_manager.get_player_state())
		_apply_default_camp_start_if_needed()
	_refresh_view()


func _configure_managers() -> void:
	_data_manager.configure(_player_state_service)
	_game_state_manager.configure(_player_state_service)
	_stats_manager.configure(_player_state_service)
	_inventory_manager.configure(_player_state_service)


func _register_pages_with_ui_manager() -> void:
	var page_panels := {
		PAGE_TOWN: _town_page_panel,
		PAGE_JOBS_BOARD: _jobs_board_page_panel,
		PAGE_SEND_MONEY: _send_money_page_panel,
		PAGE_CAMP: _camp_page_panel,
		PAGE_GROCERY: _grocery_page_panel,
		PAGE_HARDWARE: _hardware_page_panel,
		PAGE_GETTING_READY: _getting_ready_page_panel,
		PAGE_HOBOCRAFT: _hobocraft_page_panel,
		PAGE_COOKING: _cooking_page_panel
	}
	for page_id in page_panels.keys():
		_ui_manager.register_page(StringName(page_id), page_panels.get(page_id))
	if _active_loop_page != &"":
		_ui_manager.switch_to(_active_loop_page)


func _exit_tree() -> void:
	# The front-end caches this page instance and reattaches it later, so we keep the
	# service bindings alive instead of disconnecting on every tree exit.
	pass


func _build_location_pages() -> void:
	_layout_controller.build_location_pages(self)


func _make_nav_button(label_text: String) -> Button:
	var button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0.0, 42.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _make_page_panel(page_name: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = page_name
	panel.clip_contents = true
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var root = VBoxContainer.new()
	root.name = "PageRoot"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)
	return panel


func _make_panel_scroll(scroll_name: String) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.name = scroll_name
	scroll.clip_contents = true
	scroll.custom_minimum_size = Vector2(0.0, 220.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	return scroll


func _mount_camp_world_host() -> void:
	if camp_viewport_host == null:
		return
	camp_viewport_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	camp_viewport_host.offset_left = 0.0
	camp_viewport_host.offset_top = 0.0
	camp_viewport_host.offset_right = 0.0
	camp_viewport_host.offset_bottom = 0.0
	camp_viewport_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camp_viewport_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _camp_isometric_layer == null:
		_camp_isometric_layer = CampIsometricLayerScene.instantiate()
		_camp_isometric_layer.name = "CampIsometricPlayLayer"
		if _camp_isometric_layer.has_signal("interaction_activated"):
			_camp_isometric_layer.connect("interaction_activated", Callable(self, "_on_camp_interaction_activated"))
		if _camp_isometric_layer.has_signal("overlay_action_requested"):
			_camp_isometric_layer.connect("overlay_action_requested", Callable(self, "_on_camp_overlay_action_requested"))
	if _camp_isometric_layer.get_parent() != camp_viewport_host:
		if _camp_isometric_layer.get_parent() != null:
			_camp_isometric_layer.reparent(camp_viewport_host)
		else:
			camp_viewport_host.add_child(_camp_isometric_layer)
	if _camp_isometric_layer is Control:
		_camp_isometric_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_camp_isometric_layer.offset_left = 0.0
		_camp_isometric_layer.offset_top = 0.0
		_camp_isometric_layer.offset_right = 0.0
		_camp_isometric_layer.offset_bottom = 0.0
		_camp_isometric_layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_camp_isometric_layer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_camp_isometric_layer.custom_minimum_size = Vector2.ZERO
	if enable_trace_logging:
		print("[CampHost.trace] phase=mount parent=%s host=%s" % [
			String(_camp_isometric_layer.get_parent().get_path()),
			String(camp_viewport_host.get_path())
		])
	_queue_camp_world_host_trace("mount")


func _configure_scroll_content(content: Control, min_width: float = 0.0) -> void:
	if content == null:
		return
	content.custom_minimum_size = Vector2(min_width, 1.0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _add_page_title(parent: VBoxContainer, title: String, body: String) -> void:
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	parent.add_child(title_label)
	var body_label = Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(body_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if inventory_overlay.visible:
			_on_close_inventory_pressed()
		else:
			_on_open_inventory_pressed(&"carried")
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if inventory_overlay.visible:
		if inventory_radial_menu.visible:
			inventory_radial_menu.hide_menu()
			get_viewport().set_input_as_handled()
			return
		if not _inventory_move_request.is_empty():
			_cancel_inventory_move("Move canceled.")
			get_viewport().set_input_as_handled()
			return
		_on_close_inventory_pressed()
		get_viewport().set_input_as_handled()
		return
	if passport_overlay.visible:
		_on_close_passport_pressed()
		get_viewport().set_input_as_handled()
		return
	if getting_ready_overlay.visible:
		_on_close_getting_ready_pressed()
		get_viewport().set_input_as_handled()


func _connect_buttons() -> void:
	_layout_controller.connect_buttons(self)


func _apply_styles() -> void:
	_layout_controller.apply_styles(self)


func _bind_player_state(player_state) -> void:
	if player_state == null:
		inventory_panel.set_inventory(null)
		passport_panel.set_passport_data(null)
		return
	# The loop screen, inventory modal, and passport modal all bind to the same shared
	# player-state instance so UI stays synchronized as actions resolve.
	inventory_panel.set_inventory(player_state.inventory_state)
	passport_panel.set_passport_data(player_state.passport_profile)


func _apply_default_camp_start_if_needed() -> void:
	if _did_apply_default_camp_start or _player_state_service == null:
		return
	_did_apply_default_camp_start = true
	var current_state = _get_player_state()
	if current_state == null:
		return
	var state_origin = _data_manager.get_state_origin()
	if state_origin != PlayerStateServiceScript.STATE_ORIGIN_STARTER:
		if enable_trace_logging:
			print("[CampStart.trace] phase=skip_non_starter origin=%s location=%s active_page=%s" % [
				String(state_origin),
				String(current_state.loop_location_id),
				String(_active_loop_page)
			])
		return
	if StringName(current_state.loop_location_id) == SurvivalLoopRulesScript.LOCATION_CAMP:
		_set_active_loop_page(PAGE_CAMP, false)
		if enable_trace_logging:
			print("[CampStart.trace] phase=skip_already_at_camp location=%s active_page=%s" % [
				String(current_state.loop_location_id),
				String(_active_loop_page)
			])
		return
	if enable_trace_logging:
		print("[CampStart.trace] phase=preserve_starter_location location=%s active_page=%s" % [
			String(current_state.loop_location_id),
			String(_active_loop_page)
		])


func _on_player_state_changed(player_state) -> void:
	_bind_player_state(player_state)
	_refresh_view()


func _on_state_message(_success: bool, message: String) -> void:
	_last_status_message = message
	_refresh_view()


func _set_active_loop_page(page_id: StringName, refresh_after: bool = true) -> void:
	_ui_manager.switch_to(page_id)
	_navigation_controller.set_active_page(page_id)
	_active_loop_page = _ui_manager.get_active_page() if _ui_manager.get_active_page() != &"" else _navigation_controller.get_active_page()
	_refresh_camp_world_host_state(_get_player_state())
	if refresh_after:
		_refresh_view()


func _is_world_camp_page(player_state = null) -> bool:
	var location_id: StringName = &""
	if player_state != null:
		location_id = StringName(player_state.loop_location_id)
	return _navigation_controller.is_world_camp_page(location_id, SurvivalLoopRulesScript.LOCATION_CAMP, PAGE_CAMP)


func _is_world_town_page(player_state = null) -> bool:
	var location_id: StringName = &""
	if player_state != null:
		location_id = StringName(player_state.loop_location_id)
	return location_id == SurvivalLoopRulesScript.LOCATION_TOWN and _active_loop_page == PAGE_TOWN


func _refresh_camp_world_host_state(player_state) -> void:
	if camp_viewport_host == null:
		return
	var show_world_camp = _is_world_camp_page(player_state)
	var show_world_town = _is_world_town_page(player_state)
	var show_world = show_world_camp or show_world_town
	root_layout.visible = not show_world
	camp_viewport_host.visible = show_world
	if _camp_isometric_layer != null and _camp_isometric_layer.has_method("set_map_mode"):
		_camp_isometric_layer.set_map_mode(&"town" if show_world_town else &"camp")
	if _camp_isometric_layer != null and _camp_isometric_layer.has_method("set_input_enabled"):
		_camp_isometric_layer.set_input_enabled(
			show_world \
				and not inventory_overlay.visible \
				and not passport_overlay.visible \
				and not getting_ready_overlay.visible
		)
	if enable_trace_logging:
		print("[CampHost.trace] phase=refresh show_world=%s town=%s camp=%s root_visible=%s host_visible=%s location=%s active_page=%s" % [
			str(show_world),
			str(show_world_town),
			str(show_world_camp),
			str(root_layout.visible),
			str(camp_viewport_host.visible),
			String(player_state.loop_location_id if player_state != null else &""),
			String(_active_loop_page)
		])
	_queue_camp_world_host_trace("refresh")


func _refresh_inventory_overlay_presentation(player_state) -> void:
	var world_camp_inventory = inventory_overlay.visible and _is_world_camp_page(player_state)
	_ensure_inventory_overlay_content_ready()
	if inventory_window != null:
		var window_style = StyleBoxFlat.new()
		window_style.bg_color = Color("141210") if not world_camp_inventory else Color("181512")
		window_style.border_color = Color("6a5847") if not world_camp_inventory else Color("9b7a54")
		window_style.border_width_left = 1
		window_style.border_width_top = 1
		window_style.border_width_right = 1
		window_style.border_width_bottom = 1
		window_style.corner_radius_top_left = 10
		window_style.corner_radius_top_right = 10
		window_style.corner_radius_bottom_right = 10
		window_style.corner_radius_bottom_left = 10
		window_style.content_margin_left = 10
		window_style.content_margin_top = 10
		window_style.content_margin_right = 10
		window_style.content_margin_bottom = 10
		inventory_window.add_theme_stylebox_override("panel", window_style)
	if inventory_header != null:
		var header_style = StyleBoxFlat.new()
		header_style.bg_color = Color("211a15") if not world_camp_inventory else Color("3b2f22")
		header_style.corner_radius_top_left = 8
		header_style.corner_radius_top_right = 8
		header_style.corner_radius_bottom_right = 4
		header_style.corner_radius_bottom_left = 4
		header_style.content_margin_left = 8
		header_style.content_margin_top = 8
		header_style.content_margin_right = 8
		header_style.content_margin_bottom = 8
		inventory_header.add_theme_stylebox_override("panel", header_style)
	if inventory_badge != null:
		var badge_style = StyleBoxFlat.new()
		badge_style.bg_color = Color("3e3023") if not world_camp_inventory else Color("5e4630")
		badge_style.corner_radius_top_left = 6
		badge_style.corner_radius_top_right = 6
		badge_style.corner_radius_bottom_right = 6
		badge_style.corner_radius_bottom_left = 6
		badge_style.content_margin_left = 6
		badge_style.content_margin_top = 6
		badge_style.content_margin_right = 6
		badge_style.content_margin_bottom = 6
		inventory_badge.add_theme_stylebox_override("panel", badge_style)
	if inventory_badge_label != null:
		inventory_badge_label.text = "STASH" if _inventory_open_context == &"stash" else "PACK"
		inventory_badge_label.modulate = Color("f0d8b1") if not world_camp_inventory else Color("ffd59a")
	if close_inventory_button != null:
		close_inventory_button.custom_minimum_size = Vector2(124.0, 42.0)
		close_inventory_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	if inventory_title_label != null:
		inventory_title_label.clip_text = true
		inventory_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if inventory_overlay_backdrop != null:
		inventory_overlay_backdrop.color = Color(0, 0, 0, 0.12)
	if inventory_margin != null:
		var viewport_size := size
		if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
			viewport_size = get_viewport_rect().size
		var popup_size := Vector2(
			clampf(viewport_size.x * 0.52, 560.0, 920.0),
			clampf(viewport_size.y * 0.64, 440.0, 660.0)
		)
		popup_size.x = minf(popup_size.x, maxf(320.0, viewport_size.x - 40.0))
		popup_size.y = minf(popup_size.y, maxf(360.0, viewport_size.y - 48.0))
		_inventory_window_rect = Rect2((viewport_size - popup_size) * 0.5, popup_size)
		inventory_margin.anchor_left = 0.5
		inventory_margin.anchor_top = 0.5
		inventory_margin.anchor_right = 0.5
		inventory_margin.anchor_bottom = 0.5
		inventory_margin.offset_left = -popup_size.x * 0.5
		inventory_margin.offset_top = -popup_size.y * 0.5
		inventory_margin.offset_right = popup_size.x * 0.5
		inventory_margin.offset_bottom = popup_size.y * 0.5
	if inventory_window != null:
		inventory_window.custom_minimum_size = _inventory_window_rect.size
	if _inventory_resize_handle != null:
		_inventory_resize_handle.visible = false
	if inventory_title_label != null:
		inventory_title_label.text = "Ground Stash" if world_camp_inventory and _inventory_open_context == &"stash" else ("Belongings" if world_camp_inventory else "Inventory Management")
	close_inventory_button.text = "Close" if world_camp_inventory else "Back"


func _ensure_inventory_overlay_content_ready() -> void:
	if inventory_window == null or inventory_panel == null:
		return
	var inventory_root = inventory_window.get_node_or_null("InventoryRoot")
	var inventory_content_scroll = inventory_window.get_node_or_null("InventoryRoot/InventoryContentScroll")
	if inventory_root != null:
		inventory_root.visible = true
		inventory_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if inventory_header != null:
		inventory_header.visible = true
	if inventory_modal_status_label != null:
		inventory_modal_status_label.visible = true
	if inventory_actions_panel != null:
		inventory_actions_panel.visible = false
	if inventory_content_scroll != null:
		inventory_content_scroll.visible = true
		inventory_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inventory_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		inventory_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		inventory_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	inventory_panel.visible = true
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_panel.custom_minimum_size = Vector2(0.0, 0.0)
	if inventory_panel.get_child_count() == 0 and inventory_panel.has_method("_build_static_layout"):
		inventory_panel.call("_build_static_layout")
	if inventory_panel.has_method("_render"):
		inventory_panel.call("_render")
	inventory_panel.update_minimum_size()
	_refresh_inventory_container_popups()
	if inventory_window != null:
		inventory_window.queue_sort()


func _on_inventory_header_gui_input(event: InputEvent) -> void:
	var world_camp_inventory = inventory_overlay.visible and _is_world_camp_page(_get_player_state())
	if not world_camp_inventory:
		return
	return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_inventory_window_dragging = true
			_inventory_window_drag_offset = event.position
			get_viewport().set_input_as_handled()
		else:
			_inventory_window_dragging = false
	elif event is InputEventMouseMotion and _inventory_window_dragging:
		_inventory_window_rect.position += event.relative
		_refresh_inventory_overlay_presentation(_get_player_state())
		get_viewport().set_input_as_handled()


func _ensure_inventory_resize_handle() -> void:
	if inventory_overlay == null or _inventory_resize_handle != null:
		return
	_inventory_resize_handle = PanelContainer.new()
	_inventory_resize_handle.name = "InventoryResizeHandle"
	_inventory_resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	_inventory_resize_handle.custom_minimum_size = Vector2(24.0, 24.0)
	_inventory_resize_handle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_inventory_resize_handle.offset_left = 0.0
	_inventory_resize_handle.offset_top = 0.0
	_inventory_resize_handle.offset_right = 24.0
	_inventory_resize_handle.offset_bottom = 24.0
	var handle_style = StyleBoxFlat.new()
	handle_style.bg_color = Color("5e4630")
	handle_style.border_color = Color("a67e52")
	handle_style.border_width_left = 1
	handle_style.border_width_top = 1
	handle_style.border_width_right = 1
	handle_style.border_width_bottom = 1
	handle_style.corner_radius_top_left = 4
	handle_style.corner_radius_top_right = 4
	handle_style.corner_radius_bottom_left = 4
	handle_style.corner_radius_bottom_right = 4
	_inventory_resize_handle.add_theme_stylebox_override("panel", handle_style)
	_inventory_resize_handle.gui_input.connect(Callable(self, "_on_inventory_resize_handle_gui_input"))
	inventory_overlay.add_child(_inventory_resize_handle)
	_inventory_resize_handle.visible = false


func _on_inventory_resize_handle_gui_input(event: InputEvent) -> void:
	var world_camp_inventory = inventory_overlay.visible and _is_world_camp_page(_get_player_state())
	if not world_camp_inventory:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_inventory_window_resizing = event.pressed
		if event.pressed:
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _inventory_window_resizing:
		_inventory_window_rect.size += event.relative
		_refresh_inventory_overlay_presentation(_get_player_state())
		get_viewport().set_input_as_handled()


func _queue_camp_world_host_trace(phase: String) -> void:
	if not enable_trace_logging:
		return
	if _camp_world_host_trace_pending:
		return
	_camp_world_host_trace_pending = true
	call_deferred("_trace_camp_world_host_rects", phase)


func _trace_camp_world_host_rects(phase: String) -> void:
	_camp_world_host_trace_pending = false
	if not enable_trace_logging:
		return
	if camp_viewport_host == null:
		return
	var host_rect = Rect2(camp_viewport_host.position, camp_viewport_host.size)
	var host_global_rect = camp_viewport_host.get_global_rect()
	var camp_rect = Rect2()
	var camp_global_rect = Rect2()
	var camp_parent_path = "null"
	if _camp_isometric_layer != null and _camp_isometric_layer is Control:
		camp_rect = Rect2(_camp_isometric_layer.position, _camp_isometric_layer.size)
		camp_global_rect = _camp_isometric_layer.get_global_rect()
		if _camp_isometric_layer.get_parent() != null:
			camp_parent_path = String(_camp_isometric_layer.get_parent().get_path())
	print("[CampHost.trace] phase=%s parent=%s host_rect=%s host_global=%s camp_rect=%s camp_global=%s root_visible=%s host_visible=%s" % [
		phase,
		camp_parent_path,
		str(host_rect),
		str(host_global_rect),
		str(camp_rect),
		str(camp_global_rect),
		str(root_layout.visible),
		str(camp_viewport_host.visible)
	])


func _sync_active_page_with_location(player_state) -> void:
	if player_state == null:
		return
	_navigation_controller.sync_active_page_for_location(
		StringName(player_state.loop_location_id),
		SurvivalLoopRulesScript.LOCATION_TOWN,
		SurvivalLoopRulesScript.LOCATION_CAMP,
		_location_manager.get_town_world_page(),
		_location_manager.get_camp_world_page(),
		_location_manager.get_town_only_pages(),
		_location_manager.get_camp_only_pages()
	)
	_active_loop_page = _navigation_controller.get_active_page()


func _on_inventory_selection_changed(_value = null) -> void:
	if not _inventory_move_request.is_empty():
		if inventory_panel.selected_stack_index != int(_inventory_move_request.get("stack_index", -1)):
			_cancel_inventory_move("Move canceled.")
			return
	_refresh_view()


func _on_inventory_destination_focus_changed(_provider_id = &"") -> void:
	if _inventory_move_request.is_empty():
		if _try_click_move_selected_stack():
			return
		_refresh_view()
		return
	_attempt_inventory_move_destination()


func _on_inventory_move_requested(request: Dictionary) -> void:
	_inventory_move_request = {}
	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE,
		_build_action_context("inventory.drag_move", request)
	)
	_apply_inventory_operation_result(result)


func _on_inventory_container_popup_requested(provider_id: StringName) -> void:
	_show_inventory_container_popup(provider_id)


func _show_inventory_container_popup(provider_id: StringName) -> void:
	var player_state = _get_player_state()
	if player_state == null or _inventory_manager.get_inventory(player_state) == null:
		return
	var provider = _inventory_manager.get_storage_provider(player_state, provider_id)
	if provider == null:
		return
	var popup = _inventory_container_popups.get(provider_id, null)
	if popup == null or not is_instance_valid(popup):
		popup = _build_inventory_container_popup(provider_id, provider.display_name)
		_inventory_container_popups[provider_id] = popup
		inventory_overlay.add_child(popup)
		popup.position = _get_default_inventory_container_popup_position(popup.custom_minimum_size)
	else:
		popup.move_to_front()
	_rebuild_inventory_container_popup(provider_id, popup)


func _build_inventory_container_popup(provider_id: StringName, display_name: String) -> PanelContainer:
	var popup = PanelContainer.new()
	popup.name = _get_inventory_container_popup_name(provider_id)
	popup.custom_minimum_size = Vector2(420.0, 430.0)
	popup.size = popup.custom_minimum_size
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_theme_stylebox_override("panel", _make_inventory_popup_panel_style())

	var root = VBoxContainer.new()
	root.name = "InventoryContainerPopupRoot"
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup.add_child(root)

	var header = HBoxContainer.new()
	header.name = "InventoryContainerPopupHeader"
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.add_theme_constant_override("separation", 8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.gui_input.connect(Callable(self, "_on_inventory_container_popup_header_gui_input").bind(provider_id))
	root.add_child(header)

	var title = Label.new()
	title.name = "InventoryContainerPopupTitle"
	title.text = display_name
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color("eadcc8")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button = Button.new()
	close_button.name = "CloseFocusedContainerButton"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(92.0, 34.0)
	close_button.pressed.connect(Callable(self, "_close_inventory_container_popup").bind(provider_id))
	header.add_child(close_button)

	var body_scroll = ScrollContainer.new()
	body_scroll.name = "InventoryContainerPopupScroll"
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(body_scroll)

	return popup


func _rebuild_inventory_container_popup(provider_id: StringName, popup: PanelContainer) -> void:
	var player_state = _get_player_state()
	var provider = _inventory_manager.get_storage_provider(player_state, provider_id) if player_state != null else null
	if provider == null:
		_close_inventory_container_popup(provider_id)
		return
	var title = popup.find_child("InventoryContainerPopupTitle", true, false) as Label
	if title != null:
		title.text = provider.display_name
	var body_scroll = popup.find_child("InventoryContainerPopupScroll", true, false) as ScrollContainer
	if body_scroll == null:
		return
	for child in body_scroll.get_children():
		body_scroll.remove_child(child)
		child.queue_free()
	if inventory_panel != null and inventory_panel.has_method("build_container_popup_body"):
		body_scroll.add_child(inventory_panel.call("build_container_popup_body", provider_id))
	popup.size = popup.custom_minimum_size
	popup.position = _clamp_inventory_container_popup_position(popup.position, popup.size)
	popup.move_to_front()


func _refresh_inventory_container_popups() -> void:
	if inventory_overlay == null or not inventory_overlay.visible:
		return
	var provider_ids = _inventory_container_popups.keys()
	for provider_id in provider_ids:
		var popup = _inventory_container_popups.get(provider_id, null)
		if popup == null or not is_instance_valid(popup):
			_inventory_container_popups.erase(provider_id)
			continue
		_rebuild_inventory_container_popup(StringName(provider_id), popup)


func _close_inventory_container_popup(provider_id: StringName) -> void:
	var popup = _inventory_container_popups.get(provider_id, null)
	_inventory_container_popups.erase(provider_id)
	if popup != null and is_instance_valid(popup):
		popup.queue_free()
	if _inventory_container_popup_drag_id == provider_id:
		_inventory_container_popup_drag_id = &""


func _close_all_inventory_container_popups() -> void:
	for provider_id in _inventory_container_popups.keys():
		var popup = _inventory_container_popups.get(provider_id, null)
		if popup != null and is_instance_valid(popup):
			popup.queue_free()
	_inventory_container_popups.clear()
	_inventory_container_popup_drag_id = &""


func _on_inventory_container_popup_header_gui_input(event: InputEvent, provider_id: StringName) -> void:
	var popup = _inventory_container_popups.get(provider_id, null)
	if popup == null or not is_instance_valid(popup):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_inventory_container_popup_drag_id = provider_id if event.pressed else &""
		_inventory_container_popup_drag_offset = event.position
		popup.move_to_front()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _inventory_container_popup_drag_id == provider_id:
		popup.position = _clamp_inventory_container_popup_position(popup.position + event.relative, popup.size)
		get_viewport().set_input_as_handled()


func _get_default_inventory_container_popup_position(popup_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var window_rect = inventory_window.get_global_rect() if inventory_window != null else Rect2(Vector2.ZERO, Vector2(560.0, 560.0))
	var candidate = window_rect.position + Vector2(window_rect.size.x + 14.0, 46.0)
	if candidate.x + popup_size.x > viewport_size.x - 12.0:
		candidate.x = window_rect.position.x - popup_size.x - 14.0
	if candidate.x < 12.0:
		candidate.x = minf(window_rect.position.x + 28.0, maxf(12.0, viewport_size.x - popup_size.x - 12.0))
	return _clamp_inventory_container_popup_position(candidate, popup_size)


func _clamp_inventory_container_popup_position(position: Vector2, popup_size: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		clampf(position.x, 8.0, maxf(8.0, viewport_size.x - popup_size.x - 8.0)),
		clampf(position.y, 8.0, maxf(8.0, viewport_size.y - popup_size.y - 8.0))
	)


func _get_inventory_container_popup_name(provider_id: StringName) -> String:
	return "InventoryContainerPopup_%s" % String(provider_id).replace("/", "_").replace(" ", "_")


func _make_inventory_popup_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("171410")
	style.border_color = Color("a0774b")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _try_click_move_selected_stack() -> bool:
	var player_state = _get_player_state()
	if player_state == null or inventory_panel == null:
		return false
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return false
	var target_provider = _get_focused_destination_provider(player_state)
	if target_provider == null or StringName(target_provider.provider_id) == StringName(selected_stack.carry_zone):
		return false
	var action = _get_stack_transfer_action_for_target(player_state, StringName(target_provider.provider_id))
	if action.is_empty() or not bool(action.get("enabled", false)):
		_refresh_view()
		return true
	_apply_inventory_operation_result(_inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE_STACK,
		_build_action_context("inventory.click_move", {
			"stack_index": inventory_panel.selected_stack_index,
			"target_provider_id": StringName(target_provider.provider_id),
			"selected_stack_index": inventory_panel.selected_stack_index
		})
	))
	return true


func _on_inventory_stack_context_requested(stack_index: int, screen_position: Vector2) -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var stack = _inventory_manager.get_stack_at(player_state, stack_index)
	if stack == null or stack.item == null:
		return
	inventory_panel.set_selected_stack_index(stack_index)
	_show_inventory_stack_context_menu(player_state, stack_index, stack, screen_position)


func _on_inventory_container_context_requested(provider_id: StringName, screen_position: Vector2) -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var provider = _inventory_manager.get_storage_provider(player_state, provider_id)
	if provider == null:
		return
	inventory_panel.set_selected_container_provider_id(provider_id)
	_show_inventory_container_context_menu(player_state, provider, screen_position)


func _on_inventory_context_menu_id_pressed(id: int) -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return

	inventory_radial_menu.hide_menu()
	var context_stack_index = _get_inventory_context_stack_index()
	var context_provider_id = _get_inventory_context_provider_id()
	var selected_container = _inventory_manager.get_storage_provider(player_state, context_provider_id) if context_provider_id != &"" else null
	var selected_stack = _inventory_manager.get_stack_at(player_state, context_stack_index) if context_stack_index >= 0 else null
	match id:
		INVENTORY_MENU_MOVE_TO:
			if context_stack_index >= 0:
				inventory_panel.set_selected_stack_index(context_stack_index)
			_start_inventory_move_mode("")
		INVENTORY_MENU_OPEN:
			if context_provider_id != &"":
				inventory_panel.set_selected_container_provider_id(context_provider_id)
			_open_selected_container_from_modal(player_state)
		INVENTORY_MENU_DROP:
			_on_inventory_drop_pressed(context_stack_index, context_provider_id)
		INVENTORY_MENU_EQUIP:
			_on_inventory_equip_pressed(context_stack_index, context_provider_id)
		INVENTORY_MENU_UNEQUIP:
			if selected_container != null and selected_stack == null:
				_on_inventory_unequip_pressed(context_stack_index, context_provider_id)
			else:
				if context_stack_index >= 0:
					inventory_panel.set_selected_stack_index(context_stack_index)
				_start_inventory_move_mode("Unequip")
		INVENTORY_MENU_USE:
			_execute_inventory_use_action(context_stack_index)
		INVENTORY_MENU_READ:
			if selected_stack != null and selected_stack.item != null:
				var read_result = _inventory_manager.execute_action(
					InventoryManagerScript.ACTION_READ_STACK,
					_build_action_context("inventory.radial.read", {
						"stack_index": context_stack_index,
						"selected_stack_index": context_stack_index
					})
				)
				_last_inventory_message = String(read_result.get("message", "No result."))
				_trace_action_result("inventory.radial.read", InventoryManagerScript.ACTION_READ_STACK, {"stack_index": context_stack_index}, read_result)
				_refresh_view()
		INVENTORY_MENU_INSPECT:
			var inspect_result = {}
			if selected_container != null:
				inspect_result = _inventory_manager.execute_action(
					InventoryManagerScript.ACTION_INSPECT_CONTAINER,
					_build_action_context("inventory.radial.inspect_container", {
						"provider_id": context_provider_id
					})
				)
			else:
				inspect_result = _inventory_manager.execute_action(
					InventoryManagerScript.ACTION_INSPECT_STACK,
					_build_action_context("inventory.radial.inspect_stack", {
						"stack_index": context_stack_index,
						"selected_stack_index": context_stack_index
					})
				)
			_last_inventory_message = String(inspect_result.get("message", "No result."))
			_trace_action_result("inventory.radial.inspect", InventoryManagerScript.ACTION_INSPECT_STACK, {
				"stack_index": context_stack_index,
				"provider_id": context_provider_id
			}, inspect_result)
			_refresh_view()
		INVENTORY_MENU_CANCEL:
			_refresh_view()


func _on_inventory_move_cancel_pressed() -> void:
	_cancel_inventory_move("Move canceled.")


func _on_inventory_transfer_pressed() -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var action = _get_stack_transfer_action(player_state)
	if action.is_empty():
		_last_inventory_message = "Select a stack and a valid destination first."
		_refresh_view()
		return
	_apply_inventory_operation_result(_inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE_STACK,
		_build_action_context("inventory.transfer_button", {
			"stack_index": inventory_panel.selected_stack_index,
			"selected_stack_index": inventory_panel.selected_stack_index,
			"target_provider_id": StringName(action.get("target_provider_id", &""))
		})
	))


func _on_inventory_drop_pressed(stack_index: int = -1, provider_id: StringName = &"") -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var resolved_provider_id = provider_id if provider_id != &"" else inventory_panel.selected_container_provider_id
	var resolved_stack_index = stack_index if stack_index >= 0 else inventory_panel.selected_stack_index
	if resolved_provider_id != &"":
		_apply_inventory_container_result(_inventory_manager.execute_action(
			InventoryManagerScript.ACTION_DROP_CONTAINER,
			_build_action_context("inventory.drop_container", {
				"provider_id": resolved_provider_id
			})
		))
		return
	_apply_inventory_operation_result(_inventory_manager.execute_action(
		InventoryManagerScript.ACTION_DROP_STACK,
		_build_action_context("inventory.drop_stack", {
			"stack_index": resolved_stack_index,
			"selected_stack_index": resolved_stack_index
		})
	))


func _on_inventory_equip_pressed(stack_index: int = -1, provider_id: StringName = &"") -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var resolved_provider_id = provider_id if provider_id != &"" else inventory_panel.selected_container_provider_id
	var resolved_stack_index = stack_index if stack_index >= 0 else inventory_panel.selected_stack_index
	if resolved_provider_id != &"":
		var equip_result = _resolve_container_equip_target(player_state, resolved_provider_id)
		if not equip_result.get("success", false):
			_apply_inventory_container_result({
				"success": false,
				"message": String(equip_result.get("message", "Could not equip the selected container."))
			})
			return
		_apply_inventory_container_result(_inventory_manager.execute_action(
			InventoryManagerScript.ACTION_EQUIP_CONTAINER,
			_build_action_context("inventory.equip_container", {
				"provider_id": resolved_provider_id,
				"target_slot_id": StringName(equip_result.get("slot_id", &""))
			})
		))
		return
	_apply_inventory_operation_result(_inventory_manager.execute_action(
		InventoryManagerScript.ACTION_EQUIP_STACK,
		_build_action_context("inventory.equip_stack", {
			"stack_index": resolved_stack_index,
			"selected_stack_index": resolved_stack_index
		})
	))


func _on_inventory_unequip_pressed(stack_index: int = -1, provider_id: StringName = &"") -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var resolved_provider_id = provider_id if provider_id != &"" else inventory_panel.selected_container_provider_id
	if resolved_provider_id != &"":
		_apply_inventory_container_result(_inventory_manager.execute_action(
			InventoryManagerScript.ACTION_DROP_CONTAINER,
			_build_action_context("inventory.unequip_container", {
				"provider_id": resolved_provider_id
			})
		))
		return

	if stack_index >= 0:
		inventory_panel.set_selected_stack_index(stack_index)
	var action = _get_stack_transfer_action(player_state)
	if action.is_empty() or String(action.get("verb", "")) != "Unequip":
		_last_inventory_message = "Select a hand-held item and focus a valid storage destination first."
		_refresh_view()
		return
	_apply_inventory_operation_result(_inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE_STACK,
		_build_action_context("inventory.unequip_stack", {
			"stack_index": inventory_panel.selected_stack_index,
			"target_provider_id": StringName(action.get("target_provider_id", &""))
		})
	))


func _open_selected_container_from_modal(player_state) -> void:
	if player_state == null:
		return
	var provider_id = inventory_panel.selected_container_provider_id
	if provider_id == &"":
		return
	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_OPEN_CONTAINER,
		_build_action_context("inventory.open_container", {
			"provider_id": provider_id
		})
	)
	_apply_inventory_container_result(result)
	if result.get("success", false):
		inventory_panel.open_container(provider_id)
		_last_inventory_message = _build_inventory_inspect_message(player_state)
		_refresh_view()


func _on_action_pressed(action_id: StringName) -> void:
	var selected_stack_index = inventory_panel.selected_stack_index if action_id == SurvivalLoopRulesScript.ACTION_USE_SELECTED else -1
	var context = _build_action_context("loop.button", {
		"selected_stack_index": selected_stack_index
	})
	var result = _execute_state_action(action_id, context)
	_last_status_message = _get_result_message_with_trace("loop.button", action_id, result)
	if action_id == SurvivalLoopRulesScript.ACTION_USE_SELECTED and inventory_overlay.visible:
		_last_inventory_message = _last_status_message
	if _is_getting_ready_action(action_id):
		_last_getting_ready_message = _last_status_message
	_trace_action_result("loop.button", action_id, context, result)
	_refresh_view()
	_trace_ui_refresh("loop.button", action_id, result)


func _on_send_amount_changed(value: float) -> void:
	_selected_send_amount_cents = max(int(round(value * 100.0)), 1)
	if _send_amount_spinbox != null:
		_send_amount_spinbox.value = float(_selected_send_amount_cents) / 100.0
	_refresh_view()


func _on_send_support_pressed(method_id: StringName) -> void:
	var context = _build_action_context("send_money.custom", {
		"amount_cents": _selected_send_amount_cents,
		"method_id": method_id
	})
	var result = _execute_state_action(SurvivalLoopRulesScript.ACTION_SEND_SUPPORT, context)
	_last_status_message = _get_result_message_with_trace("send_money.custom", SurvivalLoopRulesScript.ACTION_SEND_SUPPORT, result)
	_trace_action_result("send_money.custom", SurvivalLoopRulesScript.ACTION_SEND_SUPPORT, context, result)
	_refresh_view()


func _on_location_travel_pressed(action_id: StringName, target_page: StringName) -> void:
	var context = _build_action_context("location.travel")
	var result = _execute_state_action(action_id, context)
	_last_status_message = _get_result_message_with_trace("location.travel", action_id, result)
	_trace_action_result("location.travel", action_id, context, result)
	if bool(result.get("success", false)):
		_set_active_loop_page(target_page, false)
	_refresh_view()
	_trace_ui_refresh("location.travel", action_id, result)


func _on_camp_interaction_activated(route_id: StringName, action_id: StringName, page_id: StringName) -> void:
	if _active_loop_page == PAGE_TOWN:
		_on_town_interaction_activated(route_id, action_id, page_id)
		return
	if page_id == &"inventory_ui":
		_on_open_inventory_pressed(&"stash")
		return
	if action_id != &"":
		var target_page = PAGE_CAMP
		if action_id == SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN:
			target_page = PAGE_TOWN
		if action_id == SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN:
			_on_location_travel_pressed(action_id, target_page)
		else:
			_on_action_pressed(action_id)
		return
	if page_id != &"":
		_set_active_loop_page(page_id)


func _on_town_interaction_activated(_route_id: StringName, action_id: StringName, page_id: StringName) -> void:
	if action_id == SurvivalLoopRulesScript.ACTION_GO_TO_CAMP:
		_on_location_travel_pressed(action_id, PAGE_CAMP)
		return
	if page_id != &"":
		_set_active_loop_page(page_id)


func _on_camp_overlay_action_requested(command: Dictionary) -> void:
	if command.is_empty():
		return
	var command_type = String(command.get("command_type", ""))
	if command_type == "select_overlay_recipe":
		var route_id = StringName(command.get("route_id", &""))
		var selection_id = StringName(command.get("selection_id", &""))
		if route_id == &"craft":
			_selected_hobocraft_recipe_id = selection_id
			_set_overlay_category_expanded(route_id, _format_recipe_category(_find_recipe(SurvivalLoopRulesScript.get_hobocraft_recipes(), selection_id)), true)
		elif route_id == &"cooking":
			_selected_cooking_recipe_id = selection_id
			_set_overlay_category_expanded(route_id, _format_recipe_category(_find_recipe(SurvivalLoopRulesScript.get_cooking_recipes(), selection_id)), true)
		_refresh_view()
		return
	if command_type == "toggle_overlay_category":
		_toggle_overlay_category(
			StringName(command.get("route_id", &"")),
			String(command.get("category_id", ""))
		)
		_refresh_view()
		return
	if command_type == "set_rest_hours":
		_selected_rest_hours = clampi(int(command.get("hours", _selected_rest_hours)), 1, 12)
		_refresh_view()
		return
	if command_type == "adjust_rest_hours":
		_selected_rest_hours = clampi(_selected_rest_hours + int(command.get("delta", 0)), 1, 12)
		_refresh_view()
		return
	if command_type == "set_sleep_item":
		_selected_sleep_item_id = StringName(command.get("sleep_item_id", &""))
		_refresh_view()
		return
	var page_id = StringName(command.get("page_id", &""))
	if page_id == &"inventory_ui":
		_on_open_inventory_pressed(&"stash")
		return
	var action_id = StringName(command.get("action_id", &""))
	if action_id == &"":
		if page_id != &"":
			_set_active_loop_page(page_id)
		return
	var context_source = String(command.get("context_source", "camp.overlay"))
	var context_data = command.get("context", {})
	var context = _build_action_context(context_source, context_data if context_data is Dictionary else {})
	var result = _execute_state_action(action_id, context)
	_last_status_message = _get_result_message_with_trace(context_source, action_id, result)
	if _is_getting_ready_action(action_id):
		_last_getting_ready_message = _last_status_message
	_trace_action_result(context_source, action_id, context, result)
	_refresh_view()


func _refresh_camp_isometric_layer(player_state, config) -> void:
	if _camp_isometric_layer == null or player_state == null or config == null or not _camp_isometric_layer.has_method("set_interactions"):
		return
	if _active_loop_page == PAGE_TOWN:
		_refresh_town_isometric_layer(player_state, config)
		return
	if _camp_isometric_layer.has_method("set_input_enabled"):
		_camp_isometric_layer.set_input_enabled(
			_active_loop_page == PAGE_CAMP \
				and not inventory_overlay.visible \
				and not passport_overlay.visible \
				and not getting_ready_overlay.visible
		)
	if _camp_isometric_layer.has_method("set_hud_snapshot"):
		_camp_isometric_layer.set_hud_snapshot(_build_camp_hud_snapshot(player_state, config))
	_camp_isometric_layer.set_interactions(_entity_manager.build_camp_interactions(
		_game_state_manager,
		player_state,
		config,
		_location_manager.get_camp_interaction_page_ids(),
		Callable(self, "_format_duration")
	))
	if _camp_isometric_layer.has_method("set_contextual_overlay_models"):
		_camp_isometric_layer.set_contextual_overlay_models(_build_camp_contextual_overlay_models(player_state, config))


func _refresh_town_isometric_layer(player_state, config) -> void:
	if _camp_isometric_layer == null or player_state == null or config == null or not _camp_isometric_layer.has_method("set_interactions"):
		return
	if _camp_isometric_layer.has_method("set_map_mode"):
		_camp_isometric_layer.set_map_mode(&"town")
	if _camp_isometric_layer.has_method("set_input_enabled"):
		_camp_isometric_layer.set_input_enabled(
			_active_loop_page == PAGE_TOWN \
				and not inventory_overlay.visible \
				and not passport_overlay.visible \
				and not getting_ready_overlay.visible
		)
	if _camp_isometric_layer.has_method("set_hud_snapshot"):
		_camp_isometric_layer.set_hud_snapshot(_build_town_hud_snapshot(player_state, config))
	_camp_isometric_layer.set_interactions(_entity_manager.build_town_interactions(
		_game_state_manager,
		config,
		_location_manager.get_town_interaction_page_ids(),
		Callable(self, "_format_duration")
	))
	if _camp_isometric_layer.has_method("set_contextual_overlay_models"):
		_camp_isometric_layer.set_contextual_overlay_models({})


func _build_camp_contextual_overlay_models(player_state, config) -> Dictionary:
	if player_state == null or config == null or _game_state_manager == null:
		return {}
	_ensure_overlay_recipe_state()
	return _overlay_builder.build_camp_contextual_overlay_models(
		player_state,
		config,
		_get_overlay_builder_ui_state(),
		_get_overlay_builder_deps()
	)


func _build_cooking_overlay_model(player_state, config) -> Dictionary:
	_ensure_overlay_recipe_state()
	return _overlay_builder.call("build_camp_contextual_overlay_models", player_state, config, _get_overlay_builder_ui_state(), _get_overlay_builder_deps()).get(&"cooking", {})


func _get_first_ready_cooking_recipe_id(recipes: Array) -> StringName:
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			_build_action_context("camp.overlay.cooking", {"recipe_id": recipe_id})
		)
		if bool(availability.get("enabled", false)):
			return recipe_id
	return &""


func _has_ready_cooking_recipe_in_category(recipes: Array, category: String) -> bool:
	for recipe in recipes:
		if not (recipe is Dictionary) or _format_recipe_category(recipe) != category:
			continue
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			_build_action_context("camp.overlay.cooking", {"recipe_id": recipe_id})
		)
		if bool(availability.get("enabled", false)):
			return true
	return false


func _build_hobocraft_overlay_model(_player_state, config) -> Dictionary:
	_ensure_overlay_recipe_state()
	return _overlay_builder.call("build_camp_contextual_overlay_models", _player_state, config, _get_overlay_builder_ui_state(), _get_overlay_builder_deps()).get(&"craft", {})


func _build_overlay_recipe_workspace_data(recipe: Dictionary, player_state, action_id: StringName, context_source: String, action_label_format: String, is_cooking: bool, utility_sections: Array = []) -> Dictionary:
	return _overlay_builder.build_overlay_recipe_workspace_data(
		recipe,
		player_state,
		_get_loop_config(),
		action_id,
		context_source,
		action_label_format,
		is_cooking,
		_get_overlay_builder_deps(),
		utility_sections
	)


func _build_overlay_recipe_material_summary(recipe: Dictionary, player_state, is_cooking: bool) -> String:
	return _overlay_builder.build_overlay_recipe_material_summary(
		recipe,
		player_state,
		_get_loop_config(),
		is_cooking,
		_get_overlay_builder_deps()
	)


func _build_getting_ready_overlay_model(player_state, config) -> Dictionary:
	return _overlay_builder.build_camp_contextual_overlay_models(
		player_state,
		config,
		_get_overlay_builder_ui_state(),
		_get_overlay_builder_deps()
	).get(&"ready", {})


func _build_rest_overlay_model(player_state, config) -> Dictionary:
	return _overlay_builder.build_camp_contextual_overlay_models(
		player_state,
		config,
		_get_overlay_builder_ui_state(),
		_get_overlay_builder_deps()
	).get(&"rest", {})


func _build_camp_overlay_action_entry(label: String, action_id: StringName, context: Dictionary = {}, tooltip_text: String = "", context_source: String = "camp.overlay") -> Dictionary:
	return _overlay_builder.call("_build_camp_overlay_action_entry", label, action_id, context, tooltip_text, context_source)


func _build_overlay_recipe_select_entry(route_id: StringName, selection_id: StringName, label: String, tooltip_text: String, selected: bool) -> Dictionary:
	return _overlay_builder.call("_build_overlay_recipe_select_entry", route_id, selection_id, label, tooltip_text, selected)


func _build_overlay_recipe_category_entry(route_id: StringName, category_id: String, expanded: bool) -> Dictionary:
	return _overlay_builder.call("_build_overlay_recipe_category_entry", route_id, category_id, expanded)


func _get_overlay_category_state_map(route_id: StringName) -> Dictionary:
	return _expanded_hobocraft_overlay_categories if route_id == &"craft" else _expanded_cooking_overlay_categories


func _seed_overlay_category_state(route_id: StringName, recipes: Array, selected_category: String) -> void:
	var state_map = _get_overlay_category_state_map(route_id)
	if not state_map.is_empty():
		return
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var category = _format_recipe_category(recipe)
		state_map[category] = category == selected_category
	if state_map.is_empty() and selected_category != "":
		state_map[selected_category] = true


func _is_overlay_category_expanded(route_id: StringName, category_id: String) -> bool:
	var state_map = _get_overlay_category_state_map(route_id)
	if state_map.is_empty():
		return true
	return bool(state_map.get(category_id, false))


func _set_overlay_category_expanded(route_id: StringName, category_id: String, expanded: bool) -> void:
	if category_id.strip_edges() == "":
		return
	var state_map = _get_overlay_category_state_map(route_id)
	state_map[category_id] = expanded


func _toggle_overlay_category(route_id: StringName, category_id: String) -> void:
	_set_overlay_category_expanded(route_id, category_id, not _is_overlay_category_expanded(route_id, category_id))


func _build_overlay_tooltip(base_text: String, availability: Dictionary) -> String:
	return _overlay_builder.call("_build_overlay_tooltip", base_text, availability)


func _ensure_overlay_recipe_state() -> void:
	var cooking_recipes = SurvivalLoopRulesScript.get_cooking_recipes()
	if _selected_cooking_recipe_id == &"" or _find_recipe(cooking_recipes, _selected_cooking_recipe_id).is_empty():
		_selected_cooking_recipe_id = _get_first_ready_cooking_recipe_id(cooking_recipes)
		if _selected_cooking_recipe_id == &"":
			_selected_cooking_recipe_id = StringName(cooking_recipes[0].get("recipe_id", &"")) if not cooking_recipes.is_empty() else &""
	_seed_overlay_category_state(&"cooking", cooking_recipes, _format_recipe_category(_find_recipe(cooking_recipes, _selected_cooking_recipe_id)))
	for recipe in cooking_recipes:
		if not (recipe is Dictionary):
			continue
		var category = _format_recipe_category(recipe)
		if _has_ready_cooking_recipe_in_category(cooking_recipes, category):
			_set_overlay_category_expanded(&"cooking", category, true)

	var craft_recipes = SurvivalLoopRulesScript.get_hobocraft_recipes()
	if _selected_hobocraft_recipe_id == &"" or _find_recipe(craft_recipes, _selected_hobocraft_recipe_id).is_empty():
		_selected_hobocraft_recipe_id = StringName(craft_recipes[0].get("recipe_id", &"")) if not craft_recipes.is_empty() else &""
	_seed_overlay_category_state(&"craft", craft_recipes, _format_recipe_category(_find_recipe(craft_recipes, _selected_hobocraft_recipe_id)))


func _get_overlay_builder_ui_state() -> Dictionary:
	return {
		"selected_cooking_recipe_id": _selected_cooking_recipe_id,
		"selected_hobocraft_recipe_id": _selected_hobocraft_recipe_id,
		"selected_rest_hours": _selected_rest_hours,
		"selected_sleep_item_id": _selected_sleep_item_id,
		"expanded_cooking_overlay_categories": _expanded_cooking_overlay_categories.duplicate(true),
		"expanded_hobocraft_overlay_categories": _expanded_hobocraft_overlay_categories.duplicate(true)
	}


func _get_overlay_builder_deps() -> Dictionary:
	return {
		"build_action_context": Callable(self, "_build_action_context"),
		"format_duration": Callable(self, "_format_duration"),
		"format_warmth_breakdown": Callable(self, "_format_warmth_breakdown"),
		"get_action_availability": Callable(self, "_get_overlay_action_availability"),
		"get_item_catalog": Callable(self, "_get_overlay_item_catalog"),
		"get_item_definition": Callable(self, "_get_item_definition"),
		"get_stamina_value": Callable(self, "_get_stamina_value")
	}


func _get_overlay_action_availability(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	if _game_state_manager == null:
		return {"enabled": false, "reason": "Action is unavailable."}
	if context.is_empty():
		return _game_state_manager.get_loop_action_availability(action_id)
	return _game_state_manager.get_loop_action_availability_with_context(action_id, context)


func _get_overlay_item_catalog():
	return _data_manager.get_item_catalog()


func _on_job_pressed(instance_id: StringName) -> void:
	var context = _build_action_context("job.button", {
		"instance_id": instance_id
	})
	var result = _execute_state_action(PlayerStateServiceScript.ACTION_PERFORM_JOB, context)
	_last_status_message = String(result.get("message", "No result."))
	_trace_action_result("job.button", PlayerStateServiceScript.ACTION_PERFORM_JOB, context, result)
	_refresh_view()


func _on_store_stock_pressed(store_id: StringName, stock_index: int) -> void:
	var context = _build_action_context("store.stock", {
		"store_id": store_id,
		"selected_stack_index": stock_index
	})
	var result = _execute_state_action(SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK, context)
	_last_status_message = String(result.get("message", "No result."))
	_trace_action_result("store.stock", SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK, context, result)
	_refresh_view()


func _on_craft_recipe_pressed(recipe_id: StringName) -> void:
	var context = _build_action_context("hobocraft.recipe", {
		"recipe_id": recipe_id
	})
	var result = _execute_state_action(SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE, context)
	_last_status_message = String(result.get("message", "No result."))
	_trace_action_result("hobocraft.recipe", SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE, context, result)
	_refresh_view()


func _on_reset_run_pressed() -> void:
	var context = _build_action_context("loop.reset")
	var result = _execute_state_action(PlayerStateServiceScript.ACTION_RESET_TO_STARTER, context)
	_last_status_message = String(result.get("message", "Run reset."))
	_trace_action_result("loop.reset", PlayerStateServiceScript.ACTION_RESET_TO_STARTER, context, result)
	_refresh_view()


func _on_go_debug_pressed() -> void:
	request_debug_page.emit()


func _on_open_inventory_pressed(open_context: StringName = &"carried") -> void:
	_inventory_open_context = open_context
	passport_overlay.visible = false
	getting_ready_overlay.visible = false
	inventory_overlay.visible = true
	inventory_overlay.move_to_front()
	inventory_radial_menu.hide_menu()
	_last_inventory_message = "Drag anything visible to a visible place. Click to inspect."
	_ensure_inventory_overlay_content_ready()
	_refresh_view()


func _on_close_inventory_pressed() -> void:
	_cancel_inventory_move("", false)
	_close_all_inventory_container_popups()
	inventory_radial_menu.hide_menu()
	inventory_overlay.visible = false
	_inventory_open_context = &"carried"
	_refresh_view()


func _on_open_passport_pressed() -> void:
	_cancel_inventory_move("", false)
	inventory_radial_menu.hide_menu()
	inventory_overlay.visible = false
	getting_ready_overlay.visible = false
	passport_overlay.visible = true
	_refresh_view()


func _on_close_passport_pressed() -> void:
	passport_overlay.visible = false


func _on_open_getting_ready_pressed() -> void:
	_cancel_inventory_move("", false)
	inventory_radial_menu.hide_menu()
	inventory_overlay.visible = false
	passport_overlay.visible = false
	getting_ready_overlay.visible = false
	_set_active_loop_page(PAGE_GETTING_READY, false)
	_refresh_view()


func _on_close_getting_ready_pressed() -> void:
	getting_ready_overlay.visible = false
	_refresh_view()


func _on_close_getting_ready_page_pressed() -> void:
	getting_ready_overlay.visible = false
	_set_active_loop_page(PAGE_CAMP, false)
	_refresh_view()


func _on_return_to_menu_pressed() -> void:
	inventory_radial_menu.hide_menu()
	inventory_overlay.visible = false
	passport_overlay.visible = false
	getting_ready_overlay.visible = false
	_cancel_inventory_move("", false)
	request_return_to_menu.emit()


func _on_quit_game_pressed() -> void:
	request_quit_game.emit()


func _refresh_view() -> void:
	var player_state = _get_player_state()
	var config = _get_loop_config()
	if player_state == null or config == null:
		_refresh_camp_world_host_state(null)
		_refresh_inventory_overlay_presentation(null)
		if _camp_isometric_layer != null and _camp_isometric_layer.has_method("set_hud_snapshot"):
			_camp_isometric_layer.set_hud_snapshot({
				"title": "Camp Condition",
				"summary": "Shared state is unavailable.",
				"stats": [
					{"id": &"nutrition", "label": "Nutrition", "value": 0, "max": 100},
					{"id": &"stamina", "label": "Stamina", "value": 0, "max": 100},
					{"id": &"warmth", "label": "Warmth", "value": 0, "max": 100},
					{"id": &"morale", "label": "Morale", "value": 0, "max": 100},
					{"id": &"hygiene", "label": "Hygiene", "value": 0, "max": 100},
					{"id": &"presentability", "label": "Presentability", "value": 0, "max": 100}
				]
			})
		summary_title_label.text = "First Playable Loop"
		summary_stats_label.text = "Shared state is unavailable."
		condition_stats_label.text = ""
		_refresh_condition_bars(null)
		goal_label.text = ""
		status_label.text = _last_status_message
		inventory_summary_label.text = "Inventory summary will appear once the shared player state is ready."
		selected_item_label.text = "No selected item."
		inventory_hint_label.text = "Open Inventory to manage carried gear and use consumables. Open Passport to inspect current condition."
		fade_debug_label.text = "Fade debug will appear once the shared player state is ready."
		if _send_money_summary_label != null:
			_send_money_summary_label.text = "Send money is unavailable until shared state is ready."
		if _pending_support_label != null:
			_pending_support_label.text = "Pending support unavailable."
		inventory_modal_status_label.text = "Waiting for shared state."
		inventory_action_summary_label.text = "Inventory actions will appear once the shared player state is ready."
		inventory_destination_label.text = "Destination focus unavailable."
		getting_ready_status_label.text = "Getting ready is unavailable until shared state is ready."
		getting_ready_stats_label.text = ""
		inventory_move_cancel_button.visible = false
		inventory_action_buttons.visible = false
		_clear_job_buttons()
		_set_all_action_buttons_disabled(true)
		_reset_inventory_management_buttons()
		_set_inventory_management_buttons_disabled(true)
		if _camp_nav_panel != null:
			_camp_nav_panel.visible = false
		result_panel.visible = false
		return

	_sync_active_page_with_location(player_state)
	_refresh_camp_world_host_state(player_state)
	_refresh_inventory_overlay_presentation(player_state)
	summary_title_label.text = "First Playable Survival Loop"
	var current_obligation = player_state.get_current_support_obligation()
	var obligation_label = "No open support due"
	if not current_obligation.is_empty():
		obligation_label = "%s %s/%s by Day %d" % [
			String(current_obligation.get("label", "Support")),
			_format_cents(int(current_obligation.get("delivered_cents", 0))),
			_format_cents(int(current_obligation.get("target_cents", 0))),
			int(current_obligation.get("checkpoint_day", player_state.day_limit))
		]
	summary_stats_label.text = "%s    %s    Week %d    %d days left    %s    Cash %s    %s    Carry %.2f kg    Fire %s" % [
		player_state.get_time_of_day_label(),
		"Camp" if player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_CAMP else "Town",
		player_state.get_current_week_index(),
		player_state.get_days_remaining_in_month(),
		obligation_label,
		player_state.get_money_label(),
		player_state.get_support_progress_label(),
		player_state.inventory_state.get_total_weight_kg(),
		player_state.get_camp_fire_status_label()
	]
	var appearance_tier = SurvivalLoopRulesScript.get_appearance_tier(player_state, config)
	condition_stats_label.text = "Status %s    Appearance: %s" % [
		player_state.get_loop_status_label(),
		String(appearance_tier.get("label", "Unkept"))
	]
	_refresh_condition_bars(player_state)
	goal_label.text = player_state.passport_profile.current_goal
	status_label.text = _format_status_with_debug(_last_status_message)

	work_summary_label.text = "Each morning the day throws up a small board of openings. Some die by nightfall, some linger, and none of them wait forever."
	supplies_summary_label.text = "Town provisioning is practical: prepared food is quick and costly, while groceries and hardware feed slower camp work."
	family_summary_label.text = "Success means delivering %s home before Day %d ends while keeping enough back to survive." % [
		_format_cents(player_state.monthly_support_target_cents),
		player_state.day_limit
	]
	_send_money_summary_label.text = _build_send_money_summary(player_state, config)
	_pending_support_label.text = "Pending support:\n%s" % player_state.get_pending_support_label()
	camp_summary_label.text = "Camp is usable daylight or dark. Time spent here costs opportunity, but fire, kindling, rest, cooking, and repair keep the body serviceable."
	_camp_nav_status_label.text = "%s\n%s" % [
		player_state.get_camp_preparation_label(),
		_format_warmth_breakdown(SurvivalLoopRulesScript.get_sleep_warmth_breakdown(player_state, config))
	]
	time_summary_label.text = "Waiting is sometimes necessary. Rest is available from 7:00 PM to 4:00 AM, or any time Stamina drops under %d." % config.rest_anytime_stamina_threshold
	inventory_hint_label.text = "Open Inventory to sort gear and use consumables. Open Passport to inspect condition. Getting Ready is a camp routine for now."
	fade_debug_label.text = "Current Fade Value: %d / 100\nCurrent Fade State: %s\nLast Daily Delta: %s%d" % [
		player_state.fade_value,
		FadingMeterSystemScript.get_state_display_name(player_state.fade_state),
		"+" if player_state.fade_last_daily_delta >= 0 else "",
		player_state.fade_last_daily_delta
	]
	inventory_modal_status_label.text = _build_inventory_modal_status(player_state)

	_configure_purchase_button(buy_bread_button, "Buy Bread", config.bread_price_cents, _get_item_definition(config.bread_item_id))
	_configure_purchase_button(buy_coffee_button, "Buy Coffee", config.coffee_price_cents, _get_item_definition(config.coffee_item_id))
	_configure_purchase_button(buy_stew_button, "Buy Hot Stew", config.stew_price_cents, _get_item_definition(config.stew_item_id))
	_configure_purchase_button(buy_tobacco_button, "Buy Tobacco", config.tobacco_price_cents, _get_item_definition(config.tobacco_item_id))
	_configure_purchase_button(buy_grocery_beans_button, "Grocery: Beans", config.grocery_beans_price_cents, _get_item_definition(config.grocery_beans_item_id))
	_configure_purchase_button(buy_grocery_potted_meat_button, "Grocery: Potted Meat", config.grocery_potted_meat_price_cents, _get_item_definition(config.grocery_potted_meat_item_id))
	_configure_purchase_button(buy_coffee_grounds_button, "Grocery: Coffee Grounds", config.grocery_coffee_grounds_price_cents, _get_item_definition(config.grocery_coffee_grounds_item_id))
	_configure_purchase_button(buy_hardware_matches_button, "Hardware: Match Safe", config.hardware_matches_price_cents, _get_item_definition(config.hardware_matches_item_id))
	_configure_purchase_button(buy_hardware_empty_can_button, "Hardware: Tin Can", config.hardware_empty_can_price_cents, _get_item_definition(config.hardware_empty_can_item_id))
	_configure_purchase_button(buy_hardware_cordage_button, "Hardware: Cordage", config.hardware_cordage_price_cents, _get_item_definition(config.hardware_cordage_item_id))
	_hardware_summary_label.text = "Hardware here is not treasure. It is small camp utility: matches, a tin for boiling, and cordage for repair."
	send_small_button.text = _build_send_method_button_text(config, &"mail", config.send_small_amount_cents)
	send_large_button.text = _build_send_method_button_text(config, &"telegraph", config.send_large_amount_cents)
	if _send_custom_amount_label != null:
		_send_custom_amount_label.text = "Exact support amount: %s. Choose any amount you can spare and send it by mail or telegraph." % _format_cents(_selected_send_amount_cents)
	if _send_amount_spinbox != null:
		_send_amount_spinbox.min_value = 0.01
		_send_amount_spinbox.max_value = maxf(float(player_state.money_cents) / 100.0, 0.01)
		if absf(_send_amount_spinbox.value - (float(_selected_send_amount_cents) / 100.0)) > 0.001:
			_send_amount_spinbox.value = float(_selected_send_amount_cents) / 100.0
	if _send_mail_custom_button != null:
		_send_mail_custom_button.text = _build_send_method_button_text(config, &"mail", _selected_send_amount_cents)
		var send_mail_availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_SEND_SUPPORT,
			_build_action_context("send_money.custom.refresh", {"amount_cents": _selected_send_amount_cents, "method_id": &"mail"})
		)
		_send_mail_custom_button.tooltip_text = _build_availability_tooltip("Send the exact selected amount by mail.", send_mail_availability)
		_send_mail_custom_button.disabled = false
	if _send_telegraph_custom_button != null:
		_send_telegraph_custom_button.text = _build_send_method_button_text(config, &"telegraph", _selected_send_amount_cents)
		var send_telegraph_availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_SEND_SUPPORT,
			_build_action_context("send_money.custom.refresh", {"amount_cents": _selected_send_amount_cents, "method_id": &"telegraph"})
		)
		_send_telegraph_custom_button.tooltip_text = _build_availability_tooltip("Send the exact selected amount by telegraph.", send_telegraph_availability)
		_send_telegraph_custom_button.disabled = false
	build_fire_button.text = "Build Fire\n%s | warmth, morale" % _format_duration(config.build_fire_minutes)
	tend_fire_button.text = "Tend Fire\n%s | steadier through the night" % _format_duration(config.tend_fire_minutes)
	gather_kindling_button.text = "Gather Kindling\n%s | camp fire prep" % _format_duration(config.gather_kindling_minutes)
	brew_camp_coffee_button.text = "Brew Camp Coffee\n%s | coffee grounds + water + tin" % _format_duration(config.brew_camp_coffee_minutes)
	_go_to_camp_button.text = "Go to Camp\n%s travel" % _format_duration(config.town_to_camp_travel_minutes)
	_return_to_town_button.text = "Return to Town\n%s travel" % _format_duration(config.camp_to_town_travel_minutes)
	_open_getting_ready_page_button.text = "Getting Ready\ncamp-only personal routine"
	_open_hobocraft_page_button.text = "Hobocraft\ncamp repair and makeshift gear"
	_open_cooking_page_button.text = "Cooking\ncamp coffee and food prep"
	wait_button.text = "Wait %s" % _format_duration(config.wait_action_minutes)
	sell_scrap_button.text = "Sell Scrap\n%s | %s for %d scrap" % [
		_format_duration(config.sell_scrap_minutes),
		_format_cents(config.sell_scrap_pay_cents),
		config.sell_scrap_quantity
	]
	sleep_button.text = "Sleep Rough\n7 PM-4 AM or Stamina <%d | %dhr" % [config.rest_anytime_stamina_threshold, config.sleep_rough_hours]
	open_inventory_button.text = "Open Inventory"
	open_passport_button.text = "Open Passport"
	open_getting_ready_button.text = "Getting Ready"
	open_inventory_button.disabled = false
	open_passport_button.disabled = false
	open_getting_ready_button.visible = player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_CAMP
	open_getting_ready_button.disabled = player_state.loop_location_id != SurvivalLoopRulesScript.LOCATION_CAMP
	return_to_menu_button.disabled = false
	return_to_menu_button.text = "Exit to Menu"
	quit_game_button.disabled = false

	_refresh_page_navigation_buttons(player_state)
	_refresh_camp_isometric_layer(player_state, config)
	_refresh_inventory_summary(player_state)
	_refresh_getting_ready_panel(player_state)
	_refresh_store_stock_sections(player_state)
	_refresh_hobocraft_recipes(player_state)
	_refresh_cooking_panel(player_state)
	_rebuild_job_board(player_state)
	_refresh_action_button(buy_bread_button, SurvivalLoopRulesScript.ACTION_BUY_BREAD)
	_refresh_action_button(buy_coffee_button, SurvivalLoopRulesScript.ACTION_BUY_COFFEE)
	_refresh_action_button(buy_stew_button, SurvivalLoopRulesScript.ACTION_BUY_STEW)
	_refresh_action_button(buy_tobacco_button, SurvivalLoopRulesScript.ACTION_BUY_TOBACCO)
	_refresh_action_button(buy_grocery_beans_button, SurvivalLoopRulesScript.ACTION_BUY_GROCERY_BEANS)
	_refresh_action_button(buy_grocery_potted_meat_button, SurvivalLoopRulesScript.ACTION_BUY_GROCERY_POTTED_MEAT)
	_refresh_action_button(buy_coffee_grounds_button, SurvivalLoopRulesScript.ACTION_BUY_COFFEE_GROUNDS)
	_refresh_action_button(buy_hardware_matches_button, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_MATCHES)
	_refresh_action_button(buy_hardware_empty_can_button, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_EMPTY_CAN)
	_refresh_action_button(buy_hardware_cordage_button, SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_CORDAGE)
	_refresh_action_button(use_selected_button, SurvivalLoopRulesScript.ACTION_USE_SELECTED)
	_refresh_action_button(send_small_button, SurvivalLoopRulesScript.ACTION_SEND_SMALL)
	_refresh_action_button(send_large_button, SurvivalLoopRulesScript.ACTION_SEND_LARGE)
	_refresh_action_button(build_fire_button, SurvivalLoopRulesScript.ACTION_BUILD_FIRE)
	_refresh_action_button(tend_fire_button, SurvivalLoopRulesScript.ACTION_TEND_FIRE)
	_refresh_action_button(gather_kindling_button, SurvivalLoopRulesScript.ACTION_GATHER_KINDLING)
	_refresh_action_button(brew_camp_coffee_button, SurvivalLoopRulesScript.ACTION_BREW_CAMP_COFFEE)
	_refresh_action_button(_go_to_camp_button, SurvivalLoopRulesScript.ACTION_GO_TO_CAMP)
	_refresh_action_button(_return_to_town_button, SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN)
	_refresh_action_button(wait_button, SurvivalLoopRulesScript.ACTION_WAIT)
	_refresh_action_button(sell_scrap_button, SurvivalLoopRulesScript.ACTION_SELL_SCRAP)
	_refresh_action_button(sleep_button, SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH)
	_refresh_getting_ready_action_buttons()
	_refresh_inventory_management_actions(player_state)
	_refresh_result_panel(player_state)
	passport_panel.set_passport_data(player_state.passport_profile)


func _refresh_page_navigation_buttons(player_state) -> void:
	var in_town = player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_TOWN
	var at_camp = player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_CAMP
	_open_grocery_page_button.disabled = not in_town
	_open_hardware_page_button.disabled = not in_town
	_open_jobs_board_button.disabled = not in_town
	_open_send_money_page_button.disabled = not in_town
	_back_to_town_from_grocery_button.disabled = not in_town
	_back_to_town_from_hardware_button.disabled = not in_town
	_back_to_town_from_jobs_button.disabled = not in_town
	_back_to_town_from_send_money_button.disabled = not in_town
	_open_getting_ready_page_button.disabled = not at_camp
	_open_hobocraft_page_button.disabled = not at_camp
	_open_cooking_page_button.disabled = not at_camp
	_back_to_camp_from_ready_button.disabled = not at_camp
	_back_to_camp_from_hobocraft_button.disabled = not at_camp
	_back_to_camp_from_cooking_button.disabled = not at_camp
	_back_to_camp_from_ready_button.text = "Close"
	_navigation_controller.refresh_navigation_visibility(
		StringName(player_state.loop_location_id),
		SurvivalLoopRulesScript.LOCATION_CAMP,
		PAGE_CAMP,
		_location_manager.get_camp_sub_pages()
	)


func _refresh_condition_bars(player_state) -> void:
	if _condition_bars_root == null:
		_condition_bars_root = GridContainer.new()
		_condition_bars_root.name = "ConditionBars"
		_condition_bars_root.columns = 3
		_condition_bars_root.add_theme_constant_override("h_separation", 10)
		_condition_bars_root.add_theme_constant_override("v_separation", 6)
		_condition_bars_root.custom_minimum_size = Vector2(780.0, 0.0)
		_condition_bars_root.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		condition_stats_label.get_parent().add_child(_condition_bars_root)
		condition_stats_label.get_parent().move_child(_condition_bars_root, condition_stats_label.get_index() + 1)
	_clear_children(_condition_bars_root)
	if player_state == null or player_state.passport_profile == null:
		return
	var stats := [
		{"label": "Nutrition", "value": player_state.passport_profile.nutrition, "max": 100},
		{"label": "Stamina", "value": _get_stamina_value(player_state), "max": 100},
		{"label": "Warmth", "value": player_state.passport_profile.warmth, "max": 100},
		{"label": "Morale", "value": player_state.passport_profile.morale, "max": 100},
		{"label": "Hygiene", "value": player_state.passport_profile.hygiene, "max": 100},
		{"label": "Presentability", "value": player_state.passport_profile.presentability, "max": 100}
	]
	for stat in stats:
		_condition_bars_root.add_child(_build_condition_bar(String(stat.get("label", "")), int(stat.get("value", 0)), int(stat.get("max", 100))))


func _build_camp_hud_snapshot(player_state, config) -> Dictionary:
	var warmth_breakdown = SurvivalLoopRulesScript.get_sleep_warmth_breakdown(player_state, config)
	return {
		"title": "Camp Condition",
		"summary": "%s\n%s\nFire %s" % [
			player_state.get_time_of_day_label(),
			_format_warmth_breakdown(warmth_breakdown),
			player_state.get_camp_fire_status_label()
		],
		"stats": [
			{"id": &"nutrition", "label": "Nutrition", "value": player_state.passport_profile.nutrition, "max": 100},
			{"id": &"stamina", "label": "Stamina", "value": _get_stamina_value(player_state), "max": 100},
			{"id": &"warmth", "label": "Warmth", "value": player_state.passport_profile.warmth, "max": 100},
			{"id": &"morale", "label": "Morale", "value": player_state.passport_profile.morale, "max": 100},
			{"id": &"hygiene", "label": "Hygiene", "value": player_state.passport_profile.hygiene, "max": 100},
			{"id": &"presentability", "label": "Presentability", "value": player_state.passport_profile.presentability, "max": 100}
		]
	}


func _build_town_hud_snapshot(player_state, _config) -> Dictionary:
	var current_obligation = player_state.get_current_support_obligation()
	var obligation_label = "No open support due"
	if not current_obligation.is_empty():
		obligation_label = "%s %s/%s by Day %d" % [
			String(current_obligation.get("label", "Support")),
			_format_cents(int(current_obligation.get("delivered_cents", 0))),
			_format_cents(int(current_obligation.get("target_cents", 0))),
			int(current_obligation.get("checkpoint_day", player_state.day_limit))
		]
	return {
		"title": "Town",
		"summary": "%s\nCash %s | %s\nWork, supplies, remittance, then the road back out." % [
			player_state.get_time_of_day_label(),
			player_state.get_money_label(),
			obligation_label
		],
		"stats": [
			{"id": &"nutrition", "label": "Nutrition", "value": player_state.passport_profile.nutrition, "max": 100},
			{"id": &"stamina", "label": "Stamina", "value": _get_stamina_value(player_state), "max": 100},
			{"id": &"warmth", "label": "Warmth", "value": player_state.passport_profile.warmth, "max": 100},
			{"id": &"morale", "label": "Morale", "value": player_state.passport_profile.morale, "max": 100},
			{"id": &"hygiene", "label": "Hygiene", "value": player_state.passport_profile.hygiene, "max": 100},
			{"id": &"presentability", "label": "Presentability", "value": player_state.passport_profile.presentability, "max": 100}
		]
	}


func _build_condition_bar(label_text: String, current_value: int, max_value: int) -> Control:
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.custom_minimum_size = Vector2(250.0, 34.0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label = Label.new()
	label.text = "%s %d / %d" % [label_text, clampi(current_value, 0, max_value), max_value]
	label.modulate = Color("e2d5bc")
	row.add_child(label)
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	bar.min_value = 0
	bar.max_value = max(max_value, 1)
	bar.value = clampi(current_value, 0, int(bar.max_value))
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _make_bar_style(Color("14120f"), Color("4b4033"), 1, 4))
	bar.add_theme_stylebox_override("fill", _make_bar_style(_get_condition_bar_color(float(bar.value) / float(bar.max_value)), Color(0.0, 0.0, 0.0, 0.0), 0, 4))
	row.add_child(bar)
	return row


func _get_condition_bar_color(ratio: float) -> Color:
	if ratio <= 0.25:
		return Color("9a4e3f")
	if ratio <= 0.50:
		return Color("a17b43")
	return Color("6f8857")


func _refresh_store_stock_sections(player_state) -> void:
	if _data_manager == null:
		_clear_children(_grocery_stock_list)
		_clear_children(_hardware_stock_list)
		return
	var config = _get_loop_config()
	var item_catalog = _data_manager.get_item_catalog()
	var week_index = player_state.store_stock_week_index
	supplies_summary_label.text = "Week %d town stock. It changes each week; quality and price both matter." % week_index
	_hardware_summary_label.text = "Week %d hardware stock. Camp utility, repair bits, and small road materials." % week_index
	_rebuild_store_stock_list(_grocery_stock_list, SurvivalLoopRulesScript.STORE_GROCERY, SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_GROCERY))
	_rebuild_store_stock_list(_hardware_stock_list, SurvivalLoopRulesScript.STORE_HARDWARE, SurvivalLoopRulesScript.get_store_stock(player_state, config, item_catalog, SurvivalLoopRulesScript.STORE_HARDWARE))


func _rebuild_store_stock_list(list: VBoxContainer, store_id: StringName, stock: Array) -> void:
	_clear_children(list)
	if stock.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No usable stock came in this week."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty_label)
		return
	for index in range(stock.size()):
		var entry = stock[index]
		if not (entry is Dictionary):
			continue
		var item = _get_item_definition(StringName(entry.get("item_id", &"")))
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 64.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_store_stock_button_text(entry, item)
		_apply_tier_text_color(button, item, int(entry.get("quality_tier", 1)))
		var context = _build_action_context("store.stock.refresh", {
			"store_id": store_id,
			"selected_stack_index": index
		})
		var availability = _game_state_manager.get_loop_action_availability_with_context(SurvivalLoopRulesScript.ACTION_BUY_STORE_STOCK, context)
		button.disabled = false
		button.tooltip_text = _build_availability_tooltip(item.get_inventory_tooltip_text() if item != null else "", availability)
		button.pressed.connect(Callable(self, "_on_store_stock_pressed").bind(store_id, index))
		list.add_child(button)


func _format_store_stock_button_text(entry: Dictionary, item) -> String:
	var quality_tier = int(entry.get("quality_tier", 1))
	var item_name = item.display_name if item != null else String(entry.get("item_id", "Unknown")).replace("_", " ")
	var quality_name = item.get_quality_name(quality_tier) if item != null else "common"
	return "%s %s\n%s | Week %d" % [
		quality_name.capitalize(),
		item_name,
		_format_cents(int(entry.get("price_cents", 0))),
		int(entry.get("week_index", 0))
	]


func _refresh_hobocraft_recipes(player_state) -> void:
	_clear_children(_hobocraft_recipe_list)
	_clear_children(_hobocraft_detail_root)
	if _game_state_manager == null:
		return
	var recipes = SurvivalLoopRulesScript.get_hobocraft_recipes()
	if recipes.is_empty():
		_add_wrapped_label(_hobocraft_recipe_list, "No known camp makes are available.")
		_add_wrapped_label(_hobocraft_detail_root, "Hobocraft needs a known make before the detail pane can show materials.")
		return
	if _selected_hobocraft_recipe_id == &"" or _find_recipe(recipes, _selected_hobocraft_recipe_id).is_empty():
		_selected_hobocraft_recipe_id = StringName(recipes[0].get("recipe_id", &""))

	var current_category := ""
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var category = _format_recipe_category(recipe)
		if category != current_category:
			current_category = category
			_add_recipe_category_label(_hobocraft_recipe_list, current_category)
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 62.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var context = _build_action_context("hobocraft.refresh", {
			"recipe_id": recipe_id
		})
		var availability = _game_state_manager.get_loop_action_availability_with_context(SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE, context)
		button.text = _format_recipe_button_text(recipe, availability)
		button.disabled = false
		button.tooltip_text = _build_availability_tooltip(String(recipe.get("summary", "")), availability)
		_apply_recipe_button_color(button, recipe)
		button.pressed.connect(Callable(self, "_on_hobocraft_recipe_selected").bind(recipe_id))
		_hobocraft_recipe_list.add_child(button)
	_refresh_hobocraft_detail(_find_recipe(recipes, _selected_hobocraft_recipe_id), player_state)


func _refresh_hobocraft_detail(recipe: Dictionary, player_state) -> void:
	_clear_children(_hobocraft_detail_root)
	if recipe.is_empty():
		_add_wrapped_label(_hobocraft_detail_root, "Select a recipe to see its requirements.")
		return
	var recipe_id = StringName(recipe.get("recipe_id", &""))
	var context = _build_action_context("hobocraft.detail", {
		"recipe_id": recipe_id
	})
	var availability = _game_state_manager.get_loop_action_availability_with_context(SurvivalLoopRulesScript.ACTION_CRAFT_RECIPE, context)
	_hobocraft_detail_root.add_child(_build_recipe_workspace(
		recipe,
		player_state,
		availability,
		false,
		Callable(self, "_on_craft_recipe_pressed").bind(recipe_id)
	))


func _refresh_cooking_panel(player_state) -> void:
	var cooking_prep_summary = _cooking_page_root.get_node_or_null("CookingPrepSummary")
	if cooking_prep_summary is Label:
		cooking_prep_summary.text = "Fire first: %s. Kindling prepared: %s. Cooking follows once heat, water, and tools are in hand." % [
			player_state.get_camp_fire_status_label(),
			"yes" if bool(player_state.camp_kindling_prepared) else "no"
		]
	_clear_children(_cooking_recipe_list)
	_clear_children(_cooking_detail_root)
	if _game_state_manager == null:
		return
	_cooking_filter_button.button_pressed = _show_only_makeable_cooking
	_cooking_filter_button.text = "Showing Makeable Now" if _show_only_makeable_cooking else "Showing All Known"
	var recipes = SurvivalLoopRulesScript.get_cooking_recipes()
	if recipes.is_empty():
		_add_wrapped_label(_cooking_recipe_list, "No known cooking actions are available.")
		_selected_cooking_recipe_id = &""
		_add_wrapped_label(_cooking_detail_root, "Cooking needs known actions before the detail pane can show materials.")
		return
	var visible_recipes: Array = []
	for recipe in recipes:
		if not (recipe is Dictionary):
			continue
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			_build_action_context("cooking.refresh", {"recipe_id": recipe_id})
		)
		if _show_only_makeable_cooking and not bool(availability.get("enabled", false)):
			continue
		visible_recipes.append(recipe)
	if visible_recipes.is_empty():
		var empty_text = "No cooking actions are makeable yet. Build a fire, boil water, or gather the right tinwork." if _show_only_makeable_cooking else "No known cooking actions are available."
		_add_wrapped_label(_cooking_recipe_list, empty_text)
		_selected_cooking_recipe_id = &""
		_add_wrapped_label(_cooking_detail_root, "Cooking needs camp, time, and materials. The filter may be hiding known recipes that are not makeable right now.")
		return
	if _selected_cooking_recipe_id == &"" or _find_recipe(visible_recipes, _selected_cooking_recipe_id).is_empty():
		_selected_cooking_recipe_id = StringName(visible_recipes[0].get("recipe_id", &""))

	var current_category := ""
	for recipe in visible_recipes:
		var category = _format_recipe_category(recipe)
		if category != current_category:
			current_category = category
			_add_recipe_category_label(_cooking_recipe_list, current_category)
		var recipe_id = StringName(recipe.get("recipe_id", &""))
		var availability = _game_state_manager.get_loop_action_availability_with_context(
			SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
			_build_action_context("cooking.refresh", {"recipe_id": recipe_id})
		)
		var button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 66.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _format_recipe_button_text(recipe, availability)
		button.disabled = false
		button.tooltip_text = _build_availability_tooltip(String(recipe.get("summary", "")), availability)
		button.pressed.connect(Callable(self, "_on_cooking_recipe_selected").bind(recipe_id))
		_cooking_recipe_list.add_child(button)
	_refresh_cooking_detail(_find_recipe(visible_recipes, _selected_cooking_recipe_id), player_state)


func _refresh_cooking_detail(recipe: Dictionary, player_state) -> void:
	_clear_children(_cooking_detail_root)
	if recipe.is_empty():
		_add_wrapped_label(_cooking_detail_root, "Select a cooking action to see its needs and result.")
		return
	var recipe_id = StringName(recipe.get("recipe_id", &""))
	var title = Label.new()
	title.text = String(recipe.get("display_name", "Cooking"))
	title.add_theme_font_size_override("font_size", 22)
	_cooking_detail_root.add_child(title)
	var availability = _game_state_manager.get_loop_action_availability_with_context(
		SurvivalLoopRulesScript.ACTION_COOK_RECIPE,
		_build_action_context("cooking.detail", {"recipe_id": recipe_id})
	)
	_cooking_detail_root.add_child(_build_recipe_workspace(
		recipe,
		player_state,
		availability,
		true,
		Callable(self, "_on_cooking_recipe_pressed").bind(recipe_id)
	))


func _build_recipe_workspace(recipe: Dictionary, player_state, availability: Dictionary, is_cooking: bool, action_pressed: Callable) -> Control:
	var workspace = HBoxContainer.new()
	workspace.name = "RecipeWorkspace"
	workspace.add_theme_constant_override("separation", 14)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var workspace_model = _overlay_builder.build_recipe_workspace_model(
		recipe,
		player_state,
		_get_loop_config(),
		availability,
		is_cooking,
		_get_overlay_builder_deps()
	)
	workspace.add_child(_build_recipe_note_panel(workspace_model.get("note", {})))
	workspace.add_child(_build_recipe_card_panel(workspace_model.get("card", {}), action_pressed))
	return workspace


func _build_recipe_note_panel(note_model: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.name = "RecipeInventoryNote"
	panel.custom_minimum_size = Vector2(270.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", _make_recipe_section_style(Color("0f0f10"), Color("f0ebe0"), 2, 12, 14.0))

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	var title = Label.new()
	title.text = String(note_model.get("title", "Camp Note"))
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color("fbf7f0")
	root.add_child(title)

	var status = Label.new()
	status.text = String(note_model.get("status", "Missing materials"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.modulate = Color("ddd6ca")
	root.add_child(status)

	for line in note_model.get("lines", PackedStringArray()):
		var label = Label.new()
		label.text = String(line)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.modulate = Color("fbf7f0") if String(line).strip_edges() != "" else Color("a8a29a")
		root.add_child(label)

	return panel


func _build_recipe_card_panel(card_model: Dictionary, action_pressed: Callable) -> Control:
	var panel = PanelContainer.new()
	panel.name = "RecipeIndexCard"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_recipe_section_style(Color("efe2c8"), Color("8e7452"), 2, 10, 16.0))

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(56.0, 56.0)
	badge.add_theme_stylebox_override("panel", _make_recipe_section_style(Color("d8c19a"), Color("755b3e"), 2, 8, 8.0))
	header.add_child(badge)

	var badge_label = Label.new()
	badge_label.text = String(card_model.get("badge_text", "CARD"))
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 16)
	badge_label.modulate = Color("1a1612")
	badge.add_child(badge_label)

	var title_column = VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", 4)
	header.add_child(title_column)

	var title = Label.new()
	title.text = String(card_model.get("title", "Recipe"))
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color("16120e")
	title_column.add_child(title)

	var subtitle = Label.new()
	subtitle.text = String(card_model.get("subtitle", "written down for camp use"))
	subtitle.modulate = Color("4f4336")
	title_column.add_child(subtitle)

	var summary = Label.new()
	summary.text = String(card_model.get("summary", ""))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.modulate = Color("231d17")
	root.add_child(summary)

	for section_model in card_model.get("sections", []):
		if not (section_model is Dictionary):
			continue
		root.add_child(_build_recipe_card_section(
			String(section_model.get("title", "")),
			String(section_model.get("body", "")),
			section_model.get("font_color", Color("221c16"))
		))

	var action_button = Button.new()
	action_button.custom_minimum_size = Vector2(0.0, 54.0)
	action_button.text = String(card_model.get("action_label", "Act"))
	action_button.disabled = bool(card_model.get("action_disabled", false))
	action_button.tooltip_text = String(card_model.get("action_tooltip", ""))
	action_button.pressed.connect(action_pressed)
	_apply_inventory_modal_button_style(action_button, Color("3d3022"), Color("8e6c42"))
	var output_item = _get_item_definition(StringName(card_model.get("output_item_id", &"")))
	_apply_tier_text_color(action_button, output_item, 1)
	root.add_child(action_button)

	return panel


func _build_recipe_card_section(title_text: String, body_text: String, font_color: Color) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color("5d4c39")
	section.add_child(title)

	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = font_color
	section.add_child(body)

	return section


func _build_recipe_inventory_note_lines(recipe: Dictionary, player_state, is_cooking: bool) -> PackedStringArray:
	return _overlay_builder.build_recipe_inventory_note_lines(
		recipe,
		player_state,
		_get_loop_config(),
		is_cooking,
		_get_overlay_builder_deps()
	)


func _get_player_inventory(player_state):
	if player_state == null:
		return null
	var inventory = player_state.get("inventory_state")
	if inventory != null:
		return inventory
	return player_state.get("inventory")


func _make_recipe_section_style(bg: Color, border: Color, border_width: int, corner_radius: int, margin: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	style.shadow_size = 4
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


func _on_hobocraft_recipe_selected(recipe_id: StringName) -> void:
	_selected_hobocraft_recipe_id = recipe_id
	_refresh_view()


func _on_cooking_filter_pressed() -> void:
	_show_only_makeable_cooking = _cooking_filter_button.button_pressed
	_refresh_view()


func _on_cooking_recipe_selected(recipe_id: StringName) -> void:
	_selected_cooking_recipe_id = recipe_id
	_refresh_view()


func _on_cooking_recipe_pressed(recipe_id: StringName) -> void:
	var context = _build_action_context("cooking.recipe", {
		"recipe_id": recipe_id
	})
	var result = _execute_state_action(SurvivalLoopRulesScript.ACTION_COOK_RECIPE, context)
	_last_status_message = String(result.get("message", "No result."))
	_trace_action_result("cooking.recipe", SurvivalLoopRulesScript.ACTION_COOK_RECIPE, context, result)
	_refresh_view()


func _format_recipe_button_text(recipe: Dictionary, availability: Dictionary) -> String:
	var status = "ready" if bool(availability.get("enabled", false)) else String(availability.get("reason", "missing materials"))
	return "%s\n%s\n%s" % [
		String(recipe.get("display_name", "Recipe")),
		_format_recipe_inputs(recipe),
		status
	]


func _format_recipe_category(recipe: Dictionary) -> String:
	var category = String(recipe.get("category", "")).strip_edges()
	if category == "":
		return "Camp Utility"
	return category


func _add_recipe_category_label(parent: Control, category: String) -> void:
	var section_label = Label.new()
	section_label.text = category
	section_label.add_theme_font_size_override("font_size", 18)
	section_label.modulate = Color("f0dfbf")
	parent.add_child(section_label)


func _format_recipe_inputs(recipe: Dictionary) -> String:
	return _overlay_builder.format_recipe_inputs(recipe, _get_overlay_builder_deps())


func _format_warmth_breakdown(breakdown: Dictionary) -> String:
	if breakdown.is_empty():
		return "not available"
	var parts: Array[String] = []
	for entry in breakdown.get("contributors", []):
		if not (entry is Dictionary):
			continue
		parts.append("%s %+d" % [String(entry.get("label", "warmth")), int(entry.get("value", 0))])
	parts.append("net %+d" % int(breakdown.get("net_warmth_change", 0)))
	return ", ".join(parts)


func _build_send_money_summary(player_state, config) -> String:
	var current_obligation = player_state.get_current_support_obligation()
	var obligation_text = "No open support due."
	if not current_obligation.is_empty():
		obligation_text = "%s: %s delivered toward %s, due end of Day %d." % [
			String(current_obligation.get("label", "Support")),
			_format_cents(int(current_obligation.get("delivered_cents", 0))),
			_format_cents(int(current_obligation.get("target_cents", 0))),
			int(current_obligation.get("checkpoint_day", player_state.day_limit))
		]
	return "%s\nMonth: %s delivered toward %s. Mail is cheap but only counts when it arrives; telegraph costs more and counts today." % [
		obligation_text,
		_format_cents(player_state.support_delivered_total_cents),
		_format_cents(player_state.monthly_support_target_cents)
	]


func _build_send_method_button_text(config, method_id: StringName, amount_cents: int) -> String:
	var method = _find_send_method(config, method_id)
	if method.is_empty():
		return "Send %s Home\nmethod unavailable" % _format_cents(amount_cents)
	var fee_cents = int(method.get("fee_cents", 0))
	var delay_days = int(method.get("delivery_delay_days", 0))
	var timing = "counts today" if delay_days <= 0 else "arrives after %d day%s" % [delay_days, "" if delay_days == 1 else "s"]
	return "%s: Send %s\nfee %s | %s" % [
		String(method.get("display_name", String(method_id).capitalize())),
		_format_cents(amount_cents),
		_format_cents(fee_cents),
		timing
	]


func _find_send_method(config, method_id: StringName) -> Dictionary:
	if config == null:
		return {}
	for method in SurvivalLoopRulesScript.get_support_send_methods(config):
		if method is Dictionary and StringName(method.get("method_id", &"")) == method_id:
			return method
	return {}


func _find_recipe(recipes: Array, recipe_id: StringName) -> Dictionary:
	for recipe in recipes:
		if recipe is Dictionary and StringName(recipe.get("recipe_id", &"")) == recipe_id:
			return recipe
	return {}


func _add_wrapped_label(parent: Control, text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _contained_text_font_size(text))
	label.modulate = Color("d9ccb5")
	parent.add_child(label)
	return label


func _contained_text_font_size(text: String) -> int:
	var length = text.length()
	if length > 220:
		return 12
	if length > 120:
		return 13
	return 14


func _apply_tier_text_color(button: Button, item, quality_tier: int) -> void:
	if button == null or item == null or not item.has_method("get_quality_color"):
		return
	var color = item.get_quality_color(quality_tier)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", color.lightened(0.18))


func _apply_recipe_button_color(button: Button, recipe: Dictionary) -> void:
	var output_item = _get_item_definition(StringName(recipe.get("output_item_id", &"")))
	_apply_tier_text_color(button, output_item, 1)


func _refresh_inventory_summary(player_state) -> void:
	var inventory = player_state.inventory_state
	var food_count = _count_item_group(inventory, [&"beans_can", &"bread_loaf", &"stew_tin", &"potted_meat"])
	var comfort_count = _count_item_group(inventory, [&"hot_coffee", &"coffee_thermos", &"smoke_tobacco"])
	var camp_supply_count = _count_item_group(inventory, [&"coffee_grounds", &"empty_can", &"cordage", &"dry_kindling"])
	var scrap_count = inventory.count_item(&"scrap_tin")
	inventory_summary_label.text = "Carry %.2f / %.2f kg\nFood %d    Comfort %d    Camp %d    Scrap %d\nFire %s" % [
		inventory.get_total_weight_kg(),
		inventory.max_total_weight_kg,
		food_count,
		comfort_count,
		camp_supply_count,
		scrap_count,
		player_state.get_camp_fire_status_label()
	]

	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null:
		selected_item_label.text = "No item selected.\nOpen inventory to choose food, coffee, tobacco, soap, papers, or other carried items for direct use."
		selected_item_label.modulate = Color("d9e2e6")
		selected_item_label.tooltip_text = ""
		use_selected_button.text = "Use Selected"
		use_selected_button.set_meta("base_tooltip", "")
		use_selected_in_inventory_button.text = "Use Selected"
		use_selected_in_inventory_button.set_meta("base_tooltip", "")
		return

	var detail_text = _build_selected_item_text(selected_stack)
	if player_state.has_method("is_stack_equipped") and player_state.is_stack_equipped(inventory_panel.selected_stack_index):
		detail_text += "\nReadied in %s." % _get_slot_label(StringName(selected_stack.carry_zone))
	selected_item_label.text = detail_text
	selected_item_label.modulate = selected_stack.get_quality_color() if selected_stack.has_method("get_quality_color") else Color("d9e2e6")
	selected_item_label.tooltip_text = selected_stack.item.get_inventory_tooltip_text() if selected_stack.item != null else ""
	use_selected_button.text = "Use Selected\n%s" % _build_selected_action_label(selected_stack)
	use_selected_button.set_meta("base_tooltip", selected_item_label.tooltip_text)
	use_selected_in_inventory_button.text = "Use Selected\n%s" % _build_selected_action_label(selected_stack)
	use_selected_in_inventory_button.set_meta("base_tooltip", selected_item_label.tooltip_text)


func _refresh_getting_ready_panel(player_state) -> void:
	if player_state == null or player_state.passport_profile == null:
		getting_ready_status_label.text = "Getting ready is unavailable until shared state is ready."
		getting_ready_stats_label.text = ""
		return
	getting_ready_status_label.text = _format_status_with_debug(_last_getting_ready_message)
	getting_ready_stats_label.text = "Water potable %d / non-potable %d    Hygiene %d / 100    Presentability %d / 100    Stamina %d / 100    Morale %d / 100    Time %s" % [
		player_state.camp_potable_water_units,
		player_state.camp_non_potable_water_units,
		player_state.passport_profile.hygiene,
		player_state.passport_profile.presentability,
		_get_stamina_value(player_state),
		player_state.passport_profile.morale,
		player_state.get_time_of_day_label()
	]
	var config = _get_loop_config()
	if config == null:
		return
	var water_action_duration = config.ready_boil_water_minutes if player_state.camp_non_potable_water_units > 0 else config.ready_fetch_water_minutes
	ready_fetch_water_button.text = "Fetch Water / Boil Water\nrequired first | %s" % _format_duration(water_action_duration)
	ready_wash_body_button.text = "Wash Body\n+Hygiene, +Presentability, -Stamina | %s" % _format_duration(config.ready_wash_body_minutes)
	ready_wash_face_hands_button.text = "Wash Face / Hands\n+Hygiene, +Presentability | %s" % _format_duration(config.ready_wash_face_hands_minutes)
	ready_shave_button.text = "Shave\n+Presentability | %s" % _format_duration(config.ready_shave_minutes)
	ready_comb_groom_button.text = "Comb / Groom\n+Presentability | %s" % _format_duration(config.ready_comb_groom_minutes)
	ready_air_out_clothes_button.text = "Air Out Clothes\n+Hygiene, +Presentability | %s" % _format_duration(config.ready_air_out_clothes_minutes)
	ready_brush_clothes_button.text = "Brush Clothes\n+Presentability | %s" % _format_duration(config.ready_brush_clothes_minutes)


func _refresh_getting_ready_action_buttons() -> void:
	_refresh_action_button(ready_fetch_water_button, SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER)
	_refresh_action_button(ready_wash_body_button, SurvivalLoopRulesScript.ACTION_READY_WASH_BODY)
	_refresh_action_button(ready_wash_face_hands_button, SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS)
	_refresh_action_button(ready_shave_button, SurvivalLoopRulesScript.ACTION_READY_SHAVE)
	_refresh_action_button(ready_comb_groom_button, SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM)
	_refresh_action_button(ready_air_out_clothes_button, SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES)
	_refresh_action_button(ready_brush_clothes_button, SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES)


func _build_inventory_modal_status(player_state) -> String:
	if player_state == null:
		return "Waiting for shared state."
	var modal_message = _format_status_with_debug(_last_inventory_message)
	if not _inventory_move_request.is_empty():
		return "%s\n%s" % [
			modal_message,
			_build_inventory_move_destination_text(player_state)
		]
	var selected_container = _get_selected_container_provider(player_state)
	if selected_container != null:
		return "%s\nSelected container: %s in %s." % [
			modal_message,
			selected_container.display_name,
		_get_provider_location_label(player_state.inventory_state, selected_container.provider_id)
		]
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null:
		return "%s\nDetailed inventory management. Left-click to inspect. Right-click an item or container for actions." % modal_message
	return "%s\nSelected %s in %s." % [
		modal_message,
		selected_stack.item.display_name,
		_get_provider_location_label(player_state.inventory_state, selected_stack.carry_zone)
	]


func _rebuild_job_board(player_state) -> void:
	_clear_job_buttons()
	if player_state == null or player_state.daily_job_board.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No work is posted right now."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		jobs_list.add_child(empty_label)
		return

	var added_count := 0
	for job in player_state.daily_job_board:
		if not (job is Dictionary):
			continue
		var instance_id = StringName(job.get("instance_id", &""))
		var availability = _game_state_manager.get_job_action_availability(instance_id) if _game_state_manager != null else {"enabled": false, "reason": "Unavailable"}
		var entry = _build_job_board_entry(job, availability)
		_trace_action_availability("job.button", PlayerStateServiceScript.ACTION_PERFORM_JOB, availability, {
			"instance_id": instance_id
		})
		jobs_list.add_child(entry)
		added_count += 1
	if added_count == 0:
		_add_wrapped_label(jobs_list, "No work is posted right now.")


func _build_job_board_entry(job: Dictionary, availability: Dictionary) -> Control:
	var title_text = String(job.get("title", "Job"))
	var duration_text = _format_duration(int(job.get("duration_minutes", 0)))
	var pay_text = _format_cents(int(job.get("pay_cents", 0)))
	var reward_item_id = StringName(job.get("reward_item_id", &""))
	var reward_quantity = int(job.get("reward_item_quantity", 0))
	var category_text = _format_job_category(StringName(job.get("job_category", &"day_labor")))
	var expiry_text = _format_job_expiry_text(job)
	var requirement_text = _format_job_appearance_requirement(job)
	var status_text = "eligible" if bool(availability.get("enabled", false)) else String(availability.get("reason", "not eligible"))
	var footer = "%s | %s | %s | %s" % [category_text, duration_text, pay_text, expiry_text]
	if reward_item_id != &"" and reward_quantity > 0:
		footer += " | +%d %s" % [reward_quantity, String(reward_item_id).replace("_", " ")]
	if bool(job.get("persistent", false)):
		footer += " | lingers"
	if StringName(job.get("required_item_id", &"")) != &"":
		footer += " | bring tool"

	var panel = PanelContainer.new()
	panel.name = "JobEntry"
	panel.clip_contents = true
	panel.custom_minimum_size = Vector2(360.0, 190.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(panel, Color("201c17"), Color("6c5131"))
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(root)
	var title_label = _add_wrapped_label(root, title_text)
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.modulate = Color("f0dfbf")
	_add_wrapped_label(root, String(job.get("summary", "")))
	_add_wrapped_label(root, footer)
	_add_wrapped_label(root, "Tradeoff: %s" % _format_job_consequence_text(job))
	_add_wrapped_label(root, "Requires: %s" % requirement_text)
	_add_wrapped_label(root, "Now: %s" % status_text)
	var action_button = Button.new()
	action_button.custom_minimum_size = Vector2(0.0, 38.0)
	action_button.text = "Take Work"
	action_button.disabled = not bool(availability.get("enabled", false))
	action_button.tooltip_text = _build_availability_tooltip(String(job.get("appearance_requirement_text", "")), availability)
	action_button.pressed.connect(Callable(self, "_on_job_pressed").bind(StringName(job.get("instance_id", &""))))
	root.add_child(action_button)
	return panel


func _format_job_category(category_id: StringName) -> String:
	return String(category_id).replace("_", " ").capitalize()


func _format_job_expiry_text(job: Dictionary) -> String:
	var player_state = _get_player_state()
	if player_state == null:
		return "expiry unknown"
	var expires_on_day = int(job.get("expires_on_day", player_state.current_day))
	if expires_on_day <= player_state.current_day:
		return "expires tonight"
	return "expires Day %d" % expires_on_day


func _format_job_appearance_requirement(job: Dictionary) -> String:
	var explicit_text = String(job.get("appearance_requirement_text", "")).strip_edges()
	if explicit_text != "":
		return explicit_text
	var config = _get_loop_config()
	var min_tier = StringName(job.get("min_appearance_tier", &""))
	var max_tier = StringName(job.get("max_appearance_tier", &""))
	if min_tier != &"":
		return "at least %s" % SurvivalLoopRulesScript.get_appearance_label(min_tier, config)
	if max_tier != &"":
		return "%s or rougher" % SurvivalLoopRulesScript.get_appearance_label(max_tier, config)
	return "no posted appearance requirement"


func _format_job_consequence_text(job: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append("%s for %s" % [_format_duration(int(job.get("duration_minutes", 0))), _format_cents(int(job.get("pay_cents", 0)))])
	var nutrition_drain = int(job.get("nutrition_drain", 0))
	var fatigue_delta = int(job.get("fatigue_delta", 0))
	var hygiene_delta = int(job.get("hygiene_delta", 0))
	var morale_delta = int(job.get("morale_delta", 0))
	if nutrition_drain > 0:
		parts.append("Nutrition -%d" % nutrition_drain)
	if fatigue_delta != 0:
		parts.append("Stamina %+d" % fatigue_delta)
	if hygiene_delta != 0:
		parts.append("Hygiene %+d" % hygiene_delta)
	if morale_delta != 0:
		parts.append("Morale %+d" % morale_delta)
	if StringName(job.get("required_item_id", &"")) != &"":
		parts.append("requires %s" % String(job.get("required_item_id", "")).replace("_", " "))
	if parts.is_empty():
		return "time and condition cost unknown"
	return ", ".join(parts)


func _clear_job_buttons() -> void:
	for child in jobs_list.get_children():
		jobs_list.remove_child(child)
		child.queue_free()


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _clear_children_except(parent: Node, kept_children: Array) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		if child in kept_children:
			continue
		parent.remove_child(child)
		child.queue_free()


func _refresh_action_button(button: Button, action_id: StringName) -> void:
	if _game_state_manager == null:
		button.disabled = true
		return
	var selected_stack_index = inventory_panel.selected_stack_index if action_id == SurvivalLoopRulesScript.ACTION_USE_SELECTED else -1
	var availability = _game_state_manager.get_loop_action_availability(action_id, selected_stack_index)
	var base_tooltip = String(button.get_meta("base_tooltip", ""))
	# Let the authoritative action service report failures on click instead of
	# allowing stale UI gating to swallow a real action silently.
	button.disabled = false
	button.tooltip_text = _build_availability_tooltip(base_tooltip, availability)
	_trace_action_availability("loop.refresh_button", action_id, availability, {
		"selected_stack_index": selected_stack_index
	})


func _refresh_result_panel(player_state) -> void:
	result_panel.visible = player_state.prototype_loop_status != &"ongoing"
	if not result_panel.visible:
		return
	if player_state.prototype_loop_status == &"success":
		result_title_label.text = "Support Sent"
		result_body_label.text = "You got enough delivered home before the month closed."
	else:
		result_title_label.text = "Run Broken"
		result_body_label.text = "You ran out of time, Nutrition, or strength before enough support reached home."


func _refresh_inventory_management_actions(player_state) -> void:
	_reset_inventory_management_buttons()
	inventory_action_buttons.visible = false
	inventory_move_cancel_button.visible = not _inventory_move_request.is_empty()
	if player_state == null:
		return

	var inventory = player_state.inventory_state
	var selected_container = _get_selected_container_provider(player_state)
	var selected_stack = _get_selected_stack(player_state)

	if not _inventory_move_request.is_empty():
		inventory_action_summary_label.text = _build_inventory_move_summary(player_state)
		inventory_destination_label.text = _build_inventory_move_destination_text(player_state)
		return

	if selected_container != null:
		inventory_action_summary_label.text = "Selected container: %s in %s." % [
			selected_container.display_name,
			_get_provider_location_label(inventory, selected_container.provider_id)
		]
		inventory_destination_label.text = "Right-click this container for equip, unequip, inspect, or cancel."
		return

	if selected_stack == null or selected_stack.item == null:
		inventory_action_summary_label.text = "Left-click an item to inspect it. Right-click an item or container for actions."
		inventory_destination_label.text = "Move destinations only matter after you choose Move To... or Unequip from the contextual menu."
		return

	var readied_suffix = " (readied)" if player_state.has_method("is_stack_equipped") and player_state.is_stack_equipped(inventory_panel.selected_stack_index) else ""
	inventory_action_summary_label.text = "Selected item: %s x%d%s in %s." % [
		selected_stack.item.display_name,
		selected_stack.quantity,
		readied_suffix,
		_get_provider_location_label(inventory, selected_stack.carry_zone)
	]
	inventory_destination_label.text = "Right-click the selected item for Move To..., Drop, Equip, Unequip, Use, or Inspect."


func _refresh_container_management_buttons(player_state, selected_container) -> void:
	var equip_action = _get_container_equip_action(player_state, selected_container)
	if not equip_action.is_empty():
		_configure_inventory_action_button(
			inventory_equip_button,
			true,
			not bool(equip_action.get("enabled", false)),
			String(equip_action.get("label", "Equip")),
			String(equip_action.get("reason", ""))
		)

	var can_unequip = StringName(selected_container.equipment_slot_id) != InventoryScript.CARRY_GROUND
	var unequip_reason = "" if can_unequip else "That container is already on the ground."
	_configure_inventory_action_button(
		inventory_unequip_button,
		true,
		not can_unequip,
		"Unequip to Ground",
		unequip_reason
	)


func _show_inventory_stack_context_menu(player_state, stack_index: int, selected_stack, screen_position: Vector2) -> void:
	_cancel_inventory_move("", false)
	_inventory_context_stack_index = stack_index
	_inventory_context_provider_id = &""
	var actions = _build_inventory_stack_context_actions(player_state, stack_index, selected_stack)
	_show_inventory_radial_menu(actions, screen_position)


func _show_inventory_container_context_menu(player_state, provider, screen_position: Vector2) -> void:
	_cancel_inventory_move("", false)
	_inventory_context_stack_index = -1
	_inventory_context_provider_id = provider.provider_id
	var actions = _build_inventory_container_context_actions(player_state, provider)
	_show_inventory_radial_menu(actions, screen_position)


func _build_inventory_stack_context_actions(player_state, stack_index: int, selected_stack) -> Array:
	var actions: Array = []
	# Temporary bridge: movement is still exposed here until drag-and-drop calls
	# the same backend transfer functions directly. Keep new long-term verbs out
	# of this logistics path where possible.
	actions.append(_make_inventory_radial_action(
		INVENTORY_MENU_MOVE_TO,
		"Move To...",
		"Pick a slot or container after choosing this action. Inventory rules still decide whether the target can receive it."
	))
	actions.append(_make_inventory_radial_action(
		INVENTORY_MENU_DROP,
		"Drop",
		"Put %s onto the ground nearby." % selected_stack.item.display_name
	))

	var equip_action = _get_stack_equip_action(player_state)
	if selected_stack.item.can_equip() and not equip_action.is_empty():
		var equip_tooltip = String(equip_action.get("reason", "Ready the item as an active tool or improvised weapon."))
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_EQUIP,
			"Equip",
			equip_tooltip
		))

	if _is_hand_provider(StringName(selected_stack.carry_zone)) and _has_valid_stack_move_destination(player_state, "Unequip"):
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_UNEQUIP,
			"Unequip",
			"Choose where to put %s down from your hand." % selected_stack.item.display_name
		))

	var use_availability = _get_inventory_use_availability(stack_index)
	if selected_stack.item.can_use():
		var use_tooltip = String(use_availability.get("reason", ""))
		if use_tooltip.strip_edges() == "":
			use_tooltip = selected_stack.item.get_inventory_tooltip_text()
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_USE,
			"Use",
			use_tooltip
		))
	if selected_stack.item.can_read():
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_READ,
			"Read",
			selected_stack.item.get_read_text()
		))

	actions.append(_make_inventory_radial_action(
		INVENTORY_MENU_INSPECT,
		"Inspect",
		selected_stack.item.get_inventory_tooltip_text()
	))
	actions.append(_make_inventory_radial_action(
		INVENTORY_MENU_CANCEL,
		"Cancel",
		"Close this action menu.",
		true
	))
	return actions


func _build_inventory_container_context_actions(player_state, provider) -> Array:
	var actions: Array = []
	var item_definition = _get_item_definition(provider.source_item_id)
	var can_open_container = provider.source_item_id != &""
	if item_definition != null:
		can_open_container = item_definition.can_open()
	if can_open_container:
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_OPEN,
			"Open",
			"Open %s and inspect what it is carrying." % provider.display_name
		))
	var equip_action = _get_container_equip_action(player_state, provider)
	if not equip_action.is_empty() and bool(equip_action.get("enabled", false)):
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_EQUIP,
			"Equip",
			String(equip_action.get("label", "Equip"))
		))
	if StringName(provider.equipment_slot_id) != InventoryScript.CARRY_GROUND:
		actions.append(_make_inventory_radial_action(
			INVENTORY_MENU_UNEQUIP,
			"Unequip",
			"Drop %s to the ground nearby." % provider.display_name
		))

	actions.append(_make_inventory_radial_action(
		INVENTORY_MENU_INSPECT,
		"Inspect",
		_build_inventory_inspect_message(player_state)
	))
	actions.append(_make_inventory_radial_action(
		INVENTORY_MENU_CANCEL,
		"Cancel",
		"Close this action menu.",
		true
	))
	return actions


func _show_inventory_radial_menu(actions: Array, screen_position: Vector2) -> void:
	if actions.is_empty():
		return
	inventory_radial_menu.popup_actions(actions, screen_position)


func _make_inventory_radial_action(action_id: int, label: String, tooltip: String, is_cancel: bool = false) -> Dictionary:
	return {
		"id": action_id,
		"label": label,
		"tooltip": tooltip,
		"is_cancel": is_cancel
	}


func _on_inventory_context_menu_canceled() -> void:
	_clear_inventory_context_menu_context()
	_refresh_view()


func _start_inventory_move_mode(required_verb: String) -> void:
	var player_state = _get_player_state()
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return

	_inventory_move_request = {
		"stack_index": inventory_panel.selected_stack_index,
		"item_name": selected_stack.item.display_name,
		"quantity": selected_stack.quantity,
		"required_verb": required_verb
	}
	_clear_inventory_context_menu_context()
	_last_inventory_message = "Unequip %s by left-clicking a storage destination." % selected_stack.item.display_name if required_verb == "Unequip" else "Move %s by left-clicking a destination slot or container." % selected_stack.item.display_name
	_refresh_view()


func _cancel_inventory_move(message: String = "", should_refresh: bool = true) -> void:
	_inventory_move_request = {}
	if message != "":
		_last_inventory_message = message
	if should_refresh:
		_refresh_view()


func _attempt_inventory_move_destination() -> void:
	var player_state = _get_player_state()
	if player_state == null or _inventory_move_request.is_empty():
		return

	if inventory_panel.selected_stack_index != int(_inventory_move_request.get("stack_index", -1)):
		_cancel_inventory_move("Source item changed. Move canceled.")
		return

	var focused_provider = _get_focused_destination_provider(player_state)
	if focused_provider == null:
		_refresh_view()
		return

	var required_verb = String(_inventory_move_request.get("required_verb", ""))
	var selected_stack = _get_selected_stack(player_state)
	var action = _get_stack_transfer_action_for_target(player_state, focused_provider.provider_id)
	if action.is_empty():
		_last_inventory_message = "That destination cannot receive %s." % String(_inventory_move_request.get("item_name", "that item"))
		_refresh_view()
		return

	var resolved_verb = String(action.get("verb", ""))
	if required_verb != "" and resolved_verb != required_verb:
		_last_inventory_message = "Select a storage destination to unequip %s into." % String(_inventory_move_request.get("item_name", "that item"))
		_refresh_view()
		return

	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE_STACK,
		_build_action_context("inventory.move_destination", {
			"stack_index": inventory_panel.selected_stack_index,
			"selected_stack_index": inventory_panel.selected_stack_index,
			"target_provider_id": StringName(action.get("target_provider_id", &""))
		})
	)
	_apply_inventory_operation_result(result)
	if result.get("success", false):
		_inventory_move_request = {}
	elif selected_stack != null and selected_stack.item != null:
		_last_inventory_message = "Could not move %s there." % selected_stack.item.display_name
	_refresh_view()


func _build_inventory_move_summary(player_state) -> String:
	var selected_stack = _get_selected_stack(player_state)
	var item_name = String(_inventory_move_request.get("item_name", "item"))
	var quantity = int(_inventory_move_request.get("quantity", 1))
	var location = "nowhere"
	if selected_stack != null and selected_stack.item != null:
		item_name = selected_stack.item.display_name
		quantity = selected_stack.quantity
		location = _get_provider_location_label(player_state.inventory_state, selected_stack.carry_zone)
	var verb = "Unequipping" if String(_inventory_move_request.get("required_verb", "")) == "Unequip" else "Moving"
	return "%s %s x%d from %s." % [verb, item_name, quantity, location]


func _build_inventory_move_destination_text(player_state) -> String:
	var item_name = String(_inventory_move_request.get("item_name", "that item"))
	var focused_provider = _get_focused_destination_provider(player_state)
	var prompt = "Left-click a storage destination for %s. Press Cancel Move or Esc to stop." % item_name if String(_inventory_move_request.get("required_verb", "")) == "Unequip" else "Left-click a destination container or slot for %s. Use Drop if you want it on the ground." % item_name
	if focused_provider == null:
		return prompt
	return "%s\nCurrent highlighted destination: %s in %s." % [
		prompt,
		focused_provider.display_name,
		_get_provider_location_label(player_state.inventory_state, focused_provider.provider_id)
	]


func _build_inventory_inspect_message(player_state) -> String:
	var selected_container = _get_selected_container_provider(player_state)
	if selected_container != null:
		var container_profile = _inventory_manager.get_container_profile(player_state, selected_container.provider_id)
		var capacity_text = "No container profile." if container_profile == null else container_profile.get_capacity_label()
		return "Inspecting %s in %s. %s" % [
			selected_container.display_name,
			_get_provider_location_label(player_state.inventory_state, selected_container.provider_id),
			capacity_text
		]

	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return "Nothing selected to inspect."

	var tooltip = selected_stack.item.get_inventory_tooltip_text().replace("\n", " | ")
	if tooltip.strip_edges() == "":
		return "Inspecting %s." % selected_stack.item.display_name
	return "Inspecting %s. %s" % [selected_stack.item.display_name, tooltip]


func _get_inventory_use_availability(stack_index: int) -> Dictionary:
	if _inventory_manager == null:
		return {"enabled": false, "reason": "Shared player state is unavailable."}
	return _inventory_manager.get_action_availability(
		SurvivalLoopRulesScript.ACTION_USE_SELECTED,
		stack_index
	)


func _execute_inventory_use_action(stack_index: int) -> void:
	var resolved_stack_index = stack_index if stack_index >= 0 else inventory_panel.selected_stack_index
	var context = _build_action_context("inventory.radial.use", {
		"selected_stack_index": resolved_stack_index
	})
	var result = _execute_state_action(SurvivalLoopRulesScript.ACTION_USE_SELECTED, context)
	_last_status_message = _get_result_message_with_trace("inventory.radial.use", SurvivalLoopRulesScript.ACTION_USE_SELECTED, result)
	_last_inventory_message = _last_status_message
	_trace_action_result("inventory.radial.use", SurvivalLoopRulesScript.ACTION_USE_SELECTED, context, result)
	if bool(result.get("success", false)):
		var player_state = _get_player_state()
		if player_state != null and _inventory_manager.get_stack_at(player_state, resolved_stack_index) == null:
			inventory_panel.set_selected_stack_index(-1)
	_refresh_view()
	_trace_ui_refresh("inventory.radial.use", SurvivalLoopRulesScript.ACTION_USE_SELECTED, result)


func _has_valid_stack_move_destination(player_state, required_verb: String = "") -> bool:
	for provider_id in _find_valid_stack_destination_provider_ids(player_state, required_verb):
		if provider_id != &"":
			return true
	return false


func _has_potential_stack_move_destination(player_state) -> bool:
	for provider_id in _find_potential_stack_destination_provider_ids(player_state):
		if provider_id != &"":
			return true
	return false


func _find_potential_stack_destination_provider_ids(player_state) -> Array:
	var provider_ids: Array = []
	if player_state == null:
		return provider_ids
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return provider_ids

	for provider_id in _inventory_manager.get_storage_provider_ids(player_state):
		var target_provider_id = StringName(provider_id)
		if target_provider_id == InventoryScript.CARRY_GROUND:
			continue
		if target_provider_id == StringName(selected_stack.carry_zone):
			continue
		if _provider_can_potentially_receive_stack(_inventory_manager.get_inventory(player_state), target_provider_id, selected_stack):
			provider_ids.append(target_provider_id)
	return provider_ids


func _provider_can_potentially_receive_stack(inventory, provider_id: StringName, selected_stack) -> bool:
	if inventory == null or selected_stack == null or selected_stack.item == null:
		return false
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return false
	if provider.allowed_item_zones.is_empty():
		return selected_stack.item.can_be_carried_in(provider.provider_id)
	for zone_name in provider.allowed_item_zones:
		if selected_stack.item.can_be_carried_in(StringName(zone_name)):
			return true
	return false


func _find_valid_stack_destination_provider_ids(player_state, required_verb: String = "") -> Array:
	var valid_provider_ids: Array = []
	if player_state == null:
		return valid_provider_ids
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return valid_provider_ids

	for provider_id in _inventory_manager.get_storage_provider_ids(player_state):
		var target_provider_id = StringName(provider_id)
		if target_provider_id == InventoryScript.CARRY_GROUND:
			continue
		var action = _get_stack_transfer_action_for_target(player_state, target_provider_id)
		if action.is_empty():
			continue
		if required_verb != "" and String(action.get("verb", "")) != required_verb:
			continue
		if bool(action.get("enabled", false)):
			valid_provider_ids.append(target_provider_id)
	return valid_provider_ids


func _configure_inventory_action_button(button: Button, visible: bool, disabled: bool, text: String, tooltip: String) -> void:
	button.visible = visible
	button.disabled = disabled
	button.text = text
	button.tooltip_text = tooltip
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND


func _reset_inventory_management_buttons() -> void:
	for button in [
		inventory_transfer_button,
		inventory_drop_button,
		inventory_equip_button,
		inventory_unequip_button,
		use_selected_in_inventory_button
	]:
		button.visible = false
		button.disabled = true


func _get_stack_transfer_action(player_state) -> Dictionary:
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return {}

	var target_provider = _get_focused_destination_provider(player_state)
	if target_provider == null:
		return _inventory_action_result(false, "Move", "Move / Store / Take", "Select a destination slot, container, or ground area first.")
	return _get_stack_transfer_action_for_target(player_state, StringName(target_provider.provider_id))


func _get_stack_transfer_action_for_target(player_state, target_provider_id: StringName) -> Dictionary:
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return {}
	var inventory = player_state.inventory_state
	var target_provider = inventory.get_storage_provider(target_provider_id)
	if target_provider == null:
		return _inventory_action_result(false, "Move", "Move / Store / Take", "That destination is unavailable.")

	var source_provider_id = StringName(selected_stack.carry_zone)
	if target_provider_id == source_provider_id:
		return _inventory_action_result(false, "Move", "Move / Store / Take", "The selected item is already there.")

	# Hands are immediate physical possession, so legal ground/container items can
	# move directly into an open hand slot without first entering pack storage.
	var verb := "Move"
	var label := "Move to %s" % target_provider.display_name
	if _is_ground_provider(target_provider_id):
		verb = "Drop"
		label = "Drop to Ground / Nearby"
	elif _is_hand_provider(target_provider_id):
		verb = "Hold"
		label = "Hold in %s" % _get_slot_label(target_provider_id)
	elif _is_ground_provider(source_provider_id):
		verb = "Take"
		label = "Take to %s" % target_provider.display_name
	elif _is_hand_provider(source_provider_id) and not _is_hand_provider(target_provider_id):
		verb = "Unequip"
		label = "Unequip to %s" % target_provider.display_name
	elif not _is_hand_provider(target_provider_id):
		verb = "Store"
		label = "Store in %s" % target_provider.display_name

	var simulated_result = _simulate_stack_move(player_state, target_provider_id)
	return _inventory_action_result(
		bool(simulated_result.get("success", false)),
		verb,
		label,
		String(simulated_result.get("message", "")),
		target_provider_id
	)


func _get_stack_equip_action(player_state) -> Dictionary:
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return {}
	if player_state == null or not player_state.has_method("can_equip_stack"):
		return {}
	if player_state.has_method("is_stack_equipped") and player_state.is_stack_equipped(inventory_panel.selected_stack_index):
		return _inventory_action_result(false, "Equip", "Equipped", "%s is already readied." % selected_stack.item.display_name)
	var equip_result = player_state.can_equip_stack(inventory_panel.selected_stack_index)
	return _inventory_action_result(
		bool(equip_result.get("success", false)),
		"Equip",
		"Ready %s" % selected_stack.item.display_name,
		String(equip_result.get("message", "")),
		StringName(selected_stack.carry_zone)
	)


func _get_stack_unequip_action(player_state) -> Dictionary:
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return {}
	if not _is_hand_provider(StringName(selected_stack.carry_zone)):
		return {}

	var transfer_action = _get_stack_transfer_action(player_state)
	if transfer_action.is_empty():
		return {}
	if String(transfer_action.get("verb", "")) != "Unequip":
		return _inventory_action_result(false, "Unequip", "Unequip", "Focus a storage destination to unequip into.")

	return transfer_action


func _get_container_equip_action(player_state, selected_container) -> Dictionary:
	if selected_container == null:
		return {}
	var equip_result = _resolve_container_equip_target(player_state, StringName(selected_container.provider_id))
	return _inventory_action_result(
		bool(equip_result.get("success", false)),
		"Equip",
		String(equip_result.get("label", "Equip")),
		String(equip_result.get("message", "")),
		StringName(equip_result.get("slot_id", &""))
	)


func _resolve_stack_equip_target(player_state) -> Dictionary:
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return {}
	if player_state == null or not player_state.has_method("can_equip_stack"):
		return {}
	var equip_result = player_state.can_equip_stack(inventory_panel.selected_stack_index)
	return {
		"success": bool(equip_result.get("success", false)),
		"slot_id": StringName(selected_stack.carry_zone),
		"label": "Ready %s" % selected_stack.item.display_name,
		"message": String(equip_result.get("message", "No valid hand is open for this item."))
	}


func _resolve_container_equip_target(player_state, provider_id: StringName) -> Dictionary:
	var inventory = player_state.inventory_state
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return {
			"success": false,
			"slot_id": &"",
			"label": "Equip",
			"message": "No container selected."
		}

	var valid_slots = _get_valid_slots_for_container(provider)
	if valid_slots.is_empty():
		return {
			"success": false,
			"slot_id": &"",
			"label": "Equip",
			"message": "%s cannot be equipped in this prototype." % provider.display_name
		}

	var preferred_slots: Array = []
	if valid_slots.has(inventory_panel.selected_slot_id):
		preferred_slots.append(inventory_panel.selected_slot_id)
	for slot_id in valid_slots:
		if not preferred_slots.has(slot_id):
			preferred_slots.append(slot_id)

	for slot_id in preferred_slots:
		var simulated = _simulate_container_equip(player_state, provider_id, slot_id)
		if simulated.get("success", false):
			return {
				"success": true,
				"slot_id": slot_id,
				"label": "Equip to %s" % _get_slot_label(slot_id),
				"message": ""
			}

	var failed_message = "No valid equipment slot is open for that container."
	if not preferred_slots.is_empty():
		var failed_result = _simulate_container_equip(player_state, provider_id, StringName(preferred_slots[0]))
		failed_message = String(failed_result.get("message", failed_message))
	return {
		"success": false,
		"slot_id": &"",
		"label": "Equip",
		"message": failed_message
	}


func _simulate_stack_move(player_state, target_provider_id: StringName) -> Dictionary:
	return _inventory_manager.simulate_stack_move(player_state, inventory_panel.selected_stack_index, target_provider_id)


func _simulate_container_equip(player_state, provider_id: StringName, target_slot_id: StringName) -> Dictionary:
	return _inventory_manager.simulate_container_equip(player_state, provider_id, target_slot_id)


func _apply_inventory_operation_result(result: Dictionary) -> void:
	_last_inventory_message = String(result.get("message", "No result message."))
	_trace_action_result("inventory.operation", StringName(result.get("action_id", &"inventory.action")), {
		"selected_stack_index": inventory_panel.selected_stack_index
	}, result)
	if result.get("success", false):
		inventory_panel.set_selected_stack_index(int(result.get("stack_index", inventory_panel.selected_stack_index)))
	_refresh_view()


func _apply_inventory_container_result(result: Dictionary) -> void:
	var selected_provider_id = inventory_panel.selected_container_provider_id
	_last_inventory_message = String(result.get("message", "No result message."))
	_trace_action_result("inventory.container", StringName(result.get("action_id", &"inventory.container_action")), {
		"provider_id": selected_provider_id
	}, result)
	if result.get("success", false) and selected_provider_id != &"":
		inventory_panel.set_selected_container_provider_id(selected_provider_id)
	_refresh_view()


func _build_inventory_destination_text(player_state) -> String:
	var focused_provider = _get_focused_destination_provider(player_state)
	if focused_provider == null:
		return "Destination Focus: none selected."
	return "Destination Focus: %s in %s." % [
		focused_provider.display_name,
		_get_provider_location_label(player_state.inventory_state, focused_provider.provider_id)
	]


func _get_selected_container_provider(player_state):
	if player_state == null:
		return null
	if inventory_panel.selected_container_provider_id == &"":
		return null
	return _inventory_manager.get_storage_provider(player_state, inventory_panel.selected_container_provider_id)


func _get_focused_destination_provider(player_state):
	if player_state == null:
		return null
	if inventory_panel.focused_destination_provider_id == &"":
		return null
	return _inventory_manager.get_storage_provider(player_state, inventory_panel.focused_destination_provider_id)


func _get_provider_location_label(inventory, provider_id: StringName) -> String:
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return "nowhere"
	if provider.provider_id == InventoryScript.CARRY_GROUND:
		return "Ground / Nearby"
	return _get_slot_label(StringName(provider.equipment_slot_id))


func _inventory_action_result(enabled: bool, verb: String, label: String, reason: String, target_provider_id: StringName = &"") -> Dictionary:
	return {
		"enabled": enabled,
		"verb": verb,
		"label": label,
		"reason": reason,
		"target_provider_id": target_provider_id
	}


func _is_hand_provider(provider_id: StringName) -> bool:
	return provider_id == InventoryScript.SLOT_HAND_L or provider_id == InventoryScript.SLOT_HAND_R


func _is_ground_provider(provider_id: StringName) -> bool:
	return provider_id == InventoryScript.CARRY_GROUND


func _get_valid_slots_for_stack(selected_stack) -> Array:
	if selected_stack == null or selected_stack.item == null:
		return []
	return selected_stack.item.get_valid_equip_slots()


func _get_valid_slots_for_container(provider) -> Array:
	if provider == null:
		return []
	var item_definition = _get_item_definition(provider.source_item_id)
	if item_definition != null:
		return item_definition.get_valid_equip_slots()
	match provider.source_item_id:
		&"backpack":
			return [InventoryScript.SLOT_BACK]
		&"satchel":
			return [InventoryScript.SLOT_SHOULDER_L, InventoryScript.SLOT_SHOULDER_R]
		&"haversack":
			return [InventoryScript.SLOT_SHOULDER_L, InventoryScript.SLOT_SHOULDER_R]
		&"bindle":
			return [InventoryScript.SLOT_HAND_L, InventoryScript.SLOT_HAND_R]
		&"pants":
			return [InventoryScript.SLOT_PANTS]
		&"wool_coat":
			return [InventoryScript.SLOT_COAT]
		&"belt":
			return [InventoryScript.SLOT_BELT_WAIST]
		_:
			return []


func _get_slot_label(slot_id: StringName) -> String:
	match slot_id:
		InventoryScript.SLOT_BACK:
			return "Back Slot"
		InventoryScript.SLOT_SHOULDER_L:
			return "Shoulder Slot L"
		InventoryScript.SLOT_SHOULDER_R:
			return "Shoulder Slot R"
		InventoryScript.SLOT_BELT_WAIST:
			return "Belt/Waist Slot"
		InventoryScript.SLOT_HAND_L:
			return "Hand Slot L"
		InventoryScript.SLOT_HAND_R:
			return "Hand Slot R"
		InventoryScript.SLOT_PANTS:
			return "Pants Slot"
		InventoryScript.SLOT_COAT:
			return "Coat Slot"
		InventoryScript.CARRY_GROUND:
			return "Ground / Nearby"
		_:
			return String(slot_id)


func _set_all_action_buttons_disabled(disabled: bool) -> void:
	for button in [
		buy_bread_button,
		buy_coffee_button,
		buy_stew_button,
		buy_tobacco_button,
		buy_grocery_beans_button,
		buy_grocery_potted_meat_button,
		buy_coffee_grounds_button,
		buy_hardware_matches_button,
		buy_hardware_empty_can_button,
		buy_hardware_cordage_button,
		use_selected_button,
		send_small_button,
		send_large_button,
		build_fire_button,
		tend_fire_button,
		gather_kindling_button,
		brew_camp_coffee_button,
		_go_to_camp_button,
		_return_to_town_button,
		_open_grocery_page_button,
		_open_hardware_page_button,
		_open_jobs_board_button,
		_open_send_money_page_button,
		_open_getting_ready_page_button,
		_open_hobocraft_page_button,
		_open_cooking_page_button,
		_back_to_town_from_grocery_button,
		_back_to_town_from_hardware_button,
		_back_to_town_from_jobs_button,
		_back_to_town_from_send_money_button,
		_back_to_camp_from_ready_button,
		_back_to_camp_from_hobocraft_button,
		_back_to_camp_from_cooking_button,
		wait_button,
		sell_scrap_button,
		sleep_button,
		open_inventory_button,
		open_passport_button,
		open_getting_ready_button,
		use_selected_in_inventory_button
	]:
		button.disabled = disabled
	for button in _get_getting_ready_buttons():
		button.disabled = disabled


func _set_inventory_management_buttons_disabled(disabled: bool) -> void:
	for button in [
		inventory_transfer_button,
		inventory_drop_button,
		inventory_equip_button,
		inventory_unequip_button,
		use_selected_in_inventory_button
	]:
		button.disabled = disabled


func _execute_state_action(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	return _action_controller.execute_state_action(action_id, context)


func _build_action_context(source: String, values: Dictionary = {}) -> Dictionary:
	return _action_controller.build_action_context(source, values)


func _trace_action_result(source: String, action_id: StringName, context: Dictionary, result: Dictionary) -> void:
	_action_controller.trace_action_result(source, action_id, context, result)
	_last_action_debug_message = _action_controller.last_action_debug_message


func _get_result_message_with_trace(source: String, action_id: StringName, result: Dictionary) -> String:
	return _action_controller.get_result_message(source, action_id, result)


func _trace_ui_refresh(source: String, action_id: StringName, result: Dictionary) -> void:
	_action_controller.trace_ui_refresh(source, action_id, result)


func _trace_action_availability(source: String, action_id: StringName, availability: Dictionary, context: Dictionary = {}) -> void:
	_action_controller.trace_action_availability(source, action_id, availability, context)


func _format_status_with_debug(message: String) -> String:
	return _action_controller.format_status_with_debug(message)


func _build_availability_tooltip(base_tooltip: String, availability: Dictionary) -> String:
	var reason = String(availability.get("reason", "")).strip_edges()
	if bool(availability.get("enabled", false)) or reason == "":
		return base_tooltip
	if base_tooltip.strip_edges() == "":
		return "Current check: %s" % reason
	return "%s\nCurrent check: %s" % [base_tooltip, reason]


func _describe_stack_debug(player_state, stack_index: int) -> String:
	if player_state == null or stack_index < 0:
		return "none"
	var stack = _inventory_manager.get_stack_at(player_state, stack_index)
	if stack == null or stack.item == null:
		return "none"
	return "%s x%d in %s" % [
		String(stack.item.item_id),
		stack.quantity,
		String(stack.carry_zone)
	]


func _get_inventory_context_stack_index() -> int:
	return _inventory_context_stack_index if _inventory_context_stack_index >= 0 else inventory_panel.selected_stack_index


func _get_inventory_context_provider_id() -> StringName:
	return _inventory_context_provider_id if _inventory_context_provider_id != &"" else inventory_panel.selected_container_provider_id


func _clear_inventory_context_menu_context() -> void:
	_inventory_context_stack_index = -1
	_inventory_context_provider_id = &""


func _get_player_state():
	if _game_state_manager == null:
		return null
	return _game_state_manager.get_player_state()


func _get_getting_ready_buttons() -> Array:
	return [
		ready_fetch_water_button,
		ready_wash_body_button,
		ready_wash_face_hands_button,
		ready_shave_button,
		ready_comb_groom_button,
		ready_air_out_clothes_button,
		ready_brush_clothes_button
	]


func _is_getting_ready_action(action_id: StringName) -> bool:
	return action_id == SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER \
		or action_id == SurvivalLoopRulesScript.ACTION_READY_WASH_BODY \
		or action_id == SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS \
		or action_id == SurvivalLoopRulesScript.ACTION_READY_SHAVE \
		or action_id == SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM \
		or action_id == SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES \
		or action_id == SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES


func _get_stamina_value(player_state) -> int:
	return _stats_manager.get_stamina(player_state)


func _get_loop_config():
	return _data_manager.get_loop_config()


func _get_item_definition(item_id: StringName):
	return _data_manager.get_item_definition(item_id)


func _get_selected_stack(player_state):
	return _inventory_manager.get_stack_at(player_state, inventory_panel.selected_stack_index)


func _configure_purchase_button(button: Button, title_text: String, price_cents: int, item) -> void:
	var effect_text = _build_item_effect_summary(item)
	var effect_suffix = "" if effect_text == "" else " | %s" % effect_text
	button.text = "%s\n%s%s" % [
		title_text,
		_format_cents(price_cents),
		effect_suffix
	]
	button.tooltip_text = item.get_inventory_tooltip_text() if item != null else ""
	button.set_meta("base_tooltip", button.tooltip_text)
	_apply_tier_text_color(button, item, 1)


func _build_selected_item_text(selected_stack) -> String:
	if selected_stack == null or selected_stack.item == null:
		return "No item selected."
	var summary = _build_item_effect_summary(selected_stack.item)
	var location = String(selected_stack.carry_zone).replace("_", " ")
	var text = "Selected: %s x%d" % [selected_stack.item.display_name, selected_stack.quantity]
	if summary != "":
		text += "\n%s" % summary
	text += "\nStored in %s." % location
	return text


func _build_selected_action_label(selected_stack) -> String:
	if selected_stack == null or selected_stack.item == null:
		return ""
	var summary = _build_item_effect_summary(selected_stack.item)
	if summary == "":
		return selected_stack.item.display_name
	return "%s | %s" % [selected_stack.item.display_name, summary]


func _build_item_effect_summary(item) -> String:
	if item == null:
		return ""
	return _join_strings(item.get_consumable_effect_lines(), ", ")


func _count_item_group(inventory, item_ids: Array) -> int:
	var total := 0
	for item_id in item_ids:
		total += inventory.count_item(StringName(item_id))
	return total


func _join_strings(parts: Array, separator: String) -> String:
	var result := ""
	for part in parts:
		var part_text = String(part)
		if part_text.strip_edges() == "":
			continue
		if result != "":
			result += separator
		result += part_text
	return result


func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


func _apply_inventory_modal_button_style(button: Button, bg: Color, border: Color) -> void:
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", Color("efe2cc"))
	button.add_theme_color_override("font_hover_color", Color("fff2db"))
	button.add_theme_color_override("font_pressed_color", Color("fff2db"))
	button.add_theme_color_override("font_disabled_color", Color("8c7d69"))
	button.add_theme_stylebox_override("normal", _make_button_style(bg, border))
	button.add_theme_stylebox_override("hover", _make_button_style(bg.lightened(0.08), border.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _make_button_style(bg.darkened(0.08), border.lightened(0.02)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color("25211d"), Color("564a40")))


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


func _make_bar_style(bg: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(max(amount_cents, 0)) / 100.0)


func _format_duration(minutes: int) -> String:
	return _time_manager.format_duration(minutes)
