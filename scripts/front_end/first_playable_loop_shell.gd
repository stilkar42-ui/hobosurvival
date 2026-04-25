extends Control

signal request_debug_page
signal request_return_to_menu
signal request_quit_game

const FirstPlayableLoopActionControllerScript := preload("res://scripts/front_end/first_playable_loop_action_controller.gd")
const OverlayBuilderScript := preload("res://scripts/front_end/adapters/overlay_builder.gd")
const CharacterRulesScript := preload("res://scripts/gameplay/character_rules.gd")
const FadingMeterSystemScript := preload("res://scripts/gameplay/fading_meter_system.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")
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
const CookingPageScript := preload("res://scripts/pages/cooking_page.gd")
const CraftingPageScript := preload("res://scripts/pages/crafting_page.gd")
const EventEncounterPageScript := preload("res://scripts/pages/event_encounter_page.gd")
const InventoryPageScript := preload("res://scripts/pages/inventory_page.gd")
const LocationPageScript := preload("res://scripts/pages/location_page.gd")
const PassportStatsPageScript := preload("res://scripts/pages/passport_stats_page.gd")
const RestCampPageScript := preload("res://scripts/pages/rest_camp_page.gd")
const TravelPageScript := preload("res://scripts/pages/travel_page.gd")
const WorldMapPageScript := preload("res://scripts/pages/world_map_page.gd")
const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")
const ConditionStripWidgetScript := preload("res://scripts/ui/widgets/condition_strip_widget.gd")

@export var enable_trace_logging := false

@onready var camp_viewport_host: Control = $CampViewportHost
@onready var root_layout: VBoxContainer = $Root
@onready var summary_panel: PanelContainer = $Root/SummaryPanel
@onready var summary_root: VBoxContainer = $Root/SummaryPanel/SummaryRoot
@onready var main_row: HBoxContainer = $Root/MainRow
@onready var actions_panel: PanelContainer = $Root/MainRow/ActionsPanel
@onready var action_scroll: ScrollContainer = $Root/MainRow/ActionsPanel/ActionScroll
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
@onready var right_column: VBoxContainer = $Root/MainRow/RightColumn
@onready var inventory_summary_root: VBoxContainer = $Root/MainRow/RightColumn/InventorySummaryPanel/InventorySummaryRoot
@onready var fade_debug_panel: PanelContainer = $Root/MainRow/RightColumn/FadeDebugPanel
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
var _page_window_frame: PanelContainer = null
var _page_window_root: VBoxContainer = null
var _page_host_scroll: ScrollContainer = null
var _page_host: VBoxContainer = null
var _right_rail_scroll: ScrollContainer = null
var _right_rail_content: VBoxContainer = null
var _persistent_condition_dock: MarginContainer = null
var _persistent_condition_strip = null
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
var _character_rules = CharacterRulesScript.new()
var _world_map_page = WorldMapPageScript.new()
var _travel_page = TravelPageScript.new()
var _location_page = LocationPageScript.new()
var _inventory_page = InventoryPageScript.new()
var _crafting_page = CraftingPageScript.new()
var _cooking_page = CookingPageScript.new()
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
	_apply_ui_framework()
	_register_pages_with_ui_manager()
	_connect_global_signals()
	_event_encounter_page.show_status("Take stock of the day, find work, and send something home before the road hollows you out.")
	var player_state = _game_state_manager.get_player_state()
	_refresh_shell_status(player_state)
	_sync_route_with_state(player_state)


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
	_page_window_frame = PanelContainer.new()
	_page_window_frame.name = "PageWindowFrame"
	_page_window_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_window_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_window_frame.custom_minimum_size = Vector2.ZERO
	actions_panel.add_child(_page_window_frame)

	_page_window_root = VBoxContainer.new()
	_page_window_root.name = "PageWindowRoot"
	_page_window_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_window_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_window_root.custom_minimum_size = Vector2.ZERO
	_page_window_root.add_theme_constant_override("separation", 10)
	_page_window_frame.add_child(_page_window_root)

	if status_label.get_parent() != null:
		status_label.get_parent().remove_child(status_label)
	_page_window_root.add_child(status_label)

	_page_host_scroll = ScrollContainer.new()
	_page_host_scroll.name = "PageHost"
	_page_host_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_host_scroll.custom_minimum_size = Vector2.ZERO
	_page_host_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page_host_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_page_window_root.add_child(_page_host_scroll)

	_page_host = VBoxContainer.new()
	_page_host.name = "PageHostContent"
	_page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_host.custom_minimum_size = Vector2.ZERO
	_page_host.add_theme_constant_override("separation", 10)
	_page_host_scroll.add_child(_page_host)

	if result_panel.get_parent() != null:
		result_panel.get_parent().remove_child(result_panel)
	_page_window_root.add_child(result_panel)
	action_scroll.visible = false


func _apply_ui_framework() -> void:
	theme = PageUIThemeScript.build_theme()
	PageUIThemeScript.ensure_background(self)
	PageUIThemeScript.apply_panel_variant(summary_panel, "highlight")
	PageUIThemeScript.apply_panel_variant(actions_panel, "panel")
	PageUIThemeScript.apply_panel_variant(_page_window_frame, "panel")
	PageUIThemeScript.apply_panel_variant(inventory_summary_panel, "alt")
	PageUIThemeScript.apply_panel_variant(fade_debug_panel, "panel")
	PageUIThemeScript.apply_panel_variant(result_panel, "alt")
	PageUIThemeScript.style_overlay_backdrop(inventory_overlay.get_node_or_null("Backdrop"))
	PageUIThemeScript.style_overlay_backdrop(passport_overlay.get_node_or_null("Backdrop"))
	PageUIThemeScript.style_overlay_backdrop(getting_ready_overlay.get_node_or_null("Backdrop"))
	PageUIThemeScript.apply_panel_variant(inventory_window, "panel")
	PageUIThemeScript.apply_panel_variant(passport_overlay.get_node("PassportMargin/PassportWindow"), "panel")
	PageUIThemeScript.apply_panel_variant(getting_ready_overlay.get_node("GettingReadyMargin/GettingReadyWindow"), "panel")
	PageUIThemeScript.style_header_label(summary_title_label, true)
	PageUIThemeScript.style_body_label(summary_stats_label)
	PageUIThemeScript.style_body_label(condition_stats_label)
	PageUIThemeScript.style_body_label(goal_label, true)
	PageUIThemeScript.style_body_label(status_label)
	PageUIThemeScript.style_section_label(result_title_label, true)
	PageUIThemeScript.style_body_label(result_body_label)
	PageUIThemeScript.style_body_label(inventory_summary_label)
	PageUIThemeScript.style_body_label(selected_item_label, true)
	PageUIThemeScript.style_small_label(inventory_hint_label)
	PageUIThemeScript.style_small_label(fade_debug_label)
	_rebuild_top_bar_layout()
	_rebuild_right_rail_layout()
	_build_persistent_condition_dock()
	_apply_shell_containment_rules()


func _rebuild_top_bar_layout() -> void:
	if summary_root.get_node_or_null("TopBarSections") != null:
		return
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBarSections"
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_theme_constant_override("separation", 10)
	summary_root.add_child(top_bar)
	for label_info in [
		{"title": "ROAD", "label": summary_title_label, "variant": "highlight"},
		{"title": "TIME / WEEK", "label": summary_stats_label, "variant": "panel"},
		{"title": "CONDITION", "label": condition_stats_label, "variant": "panel"},
		{"title": "CURRENT AIM", "label": goal_label, "variant": "panel"}
	]:
		summary_root.remove_child(label_info.label)
		var section := PageUIThemeScript.create_section_panel(label_info.title, label_info.variant)
		section.panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.root.add_child(label_info.label)
		top_bar.add_child(section.panel)
		PageUIThemeScript.style_small_label(section.title)
		if label_info.label == summary_title_label:
			PageUIThemeScript.style_header_label(summary_title_label, true)
		else:
			PageUIThemeScript.style_body_label(label_info.label)
	summary_root.move_child(top_bar, 0)


func _rebuild_right_rail_layout() -> void:
	if inventory_summary_root.get_node_or_null("QuickActionsSection") != null:
		return
	_wrap_right_rail_in_scroll()
	var section_title := Label.new()
	section_title.text = "ROADSIDE KIT"
	PageUIThemeScript.style_small_label(section_title)
	inventory_summary_root.add_child(section_title)
	inventory_summary_root.move_child(section_title, 0)
	var quick_actions := VBoxContainer.new()
	quick_actions.name = "QuickActionsSection"
	quick_actions.add_theme_constant_override("separation", 8)
	inventory_summary_root.add_child(quick_actions)
	var quick_title := Label.new()
	quick_title.text = "QUICK ACTIONS"
	PageUIThemeScript.style_small_label(quick_title)
	quick_actions.add_child(quick_title)
	for button in [open_inventory_button, open_passport_button, open_getting_ready_button]:
		if button.get_parent() != null:
			button.get_parent().remove_child(button)
		PageUIThemeScript.style_button(button, true)
		quick_actions.add_child(button)
	open_getting_ready_button.text = "Travel / Routes"
	var menu_actions := VBoxContainer.new()
	menu_actions.name = "MenuActionsSection"
	menu_actions.add_theme_constant_override("separation", 8)
	inventory_summary_root.add_child(menu_actions)
	for button in [return_to_menu_button, quit_game_button]:
		if button.get_parent() != null:
			button.get_parent().remove_child(button)
		PageUIThemeScript.style_button(button)
		menu_actions.add_child(button)


func _wrap_right_rail_in_scroll() -> void:
	if right_column.get_node_or_null("RightRailScroll") != null:
		return
	var existing_children := right_column.get_children()
	_right_rail_scroll = ScrollContainer.new()
	_right_rail_scroll.name = "RightRailScroll"
	_right_rail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_rail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_rail_scroll.custom_minimum_size = Vector2.ZERO
	_right_rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_right_rail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_column.add_child(_right_rail_scroll)

	_right_rail_content = VBoxContainer.new()
	_right_rail_content.name = "RightRailContent"
	_right_rail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_rail_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_rail_content.custom_minimum_size = Vector2.ZERO
	_right_rail_content.add_theme_constant_override("separation", 10)
	_right_rail_scroll.add_child(_right_rail_content)

	for child in existing_children:
		right_column.remove_child(child)
		_right_rail_content.add_child(child)


func _build_persistent_condition_dock() -> void:
	if _persistent_condition_dock != null:
		return
	_persistent_condition_dock = MarginContainer.new()
	_persistent_condition_dock.name = "PersistentConditionDock"
	_persistent_condition_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_persistent_condition_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_persistent_condition_dock.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_persistent_condition_dock.add_theme_constant_override("margin_left", 0)
	_persistent_condition_dock.add_theme_constant_override("margin_top", 0)
	_persistent_condition_dock.add_theme_constant_override("margin_right", 0)
	_persistent_condition_dock.add_theme_constant_override("margin_bottom", 0)
	summary_root.add_child(_persistent_condition_dock)

	_persistent_condition_strip = ConditionStripWidgetScript.new()
	_persistent_condition_strip.name = "PersistentConditionStrip"
	_persistent_condition_strip.set_title("Road Condition")
	_persistent_condition_strip.set_variant("alt")
	_persistent_condition_strip.set_columns(9)
	_persistent_condition_strip.set_compact_mode(true)
	_persistent_condition_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_persistent_condition_strip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_persistent_condition_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_persistent_condition_dock.add_child(_persistent_condition_strip)
	_set_mouse_filter_recursive(_persistent_condition_strip, Control.MOUSE_FILTER_IGNORE)
	call_deferred("_apply_overlay_shell_offsets")


func _apply_shell_containment_rules() -> void:
	for control in [
		root_layout,
		summary_panel,
		summary_root,
		main_row,
		actions_panel,
		_page_window_frame,
		_page_window_root,
		_page_host_scroll,
		_page_host,
		right_column,
		_right_rail_scroll,
		_right_rail_content
	]:
		if control != null:
			control.custom_minimum_size = Vector2.ZERO
	root_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	main_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.custom_minimum_size = Vector2(260.0, 0.0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _apply_overlay_shell_offsets() -> void:
	var header_bottom = summary_panel.get_global_rect().end.y
	if header_bottom <= 0.0:
		return
	var top_offset = header_bottom + 12.0
	var inventory_backdrop = inventory_overlay.get_node_or_null("Backdrop") as ColorRect
	if inventory_backdrop != null:
		inventory_backdrop.offset_top = header_bottom
	var inventory_margin = inventory_overlay.get_node_or_null("InventoryMargin") as MarginContainer
	if inventory_margin != null:
		inventory_margin.offset_top = top_offset
	var getting_ready_backdrop = getting_ready_overlay.get_node_or_null("Backdrop") as ColorRect
	if getting_ready_backdrop != null:
		getting_ready_backdrop.offset_top = header_bottom
	var getting_ready_margin = getting_ready_overlay.get_node_or_null("GettingReadyMargin") as MarginContainer
	if getting_ready_margin != null:
		var current_height = getting_ready_margin.offset_bottom - getting_ready_margin.offset_top
		if getting_ready_margin.get_global_rect().position.y < top_offset:
			getting_ready_margin.offset_top = top_offset - (get_viewport_rect().size.y * 0.5)
			getting_ready_margin.offset_bottom = getting_ready_margin.offset_top + current_height


func _set_mouse_filter_recursive(node: Node, mouse_filter: int) -> void:
	if node is Control:
		node.mouse_filter = mouse_filter
	for child in node.get_children():
		_set_mouse_filter_recursive(child, mouse_filter)


func _refresh_shell_status(player_state) -> void:
	if player_state == null:
		summary_title_label.text = "First Playable Loop"
		summary_stats_label.text = "Shared state is unavailable."
		condition_stats_label.text = ""
		goal_label.text = ""
		if _persistent_condition_strip != null:
			_persistent_condition_strip.clear_conditions()
		return
	var config = _data_manager.get_loop_config() if _data_manager != null else null
	var current_obligation = player_state.get_current_support_obligation()
	var obligation_label = "No open support due"
	if not current_obligation.is_empty():
		obligation_label = "%s due Day %d" % [
			String(current_obligation.get("label", "Support")),
			int(current_obligation.get("checkpoint_day", player_state.day_limit))
		]
	summary_title_label.text = "First Playable Survival Loop"
	summary_stats_label.text = "%s    %s    Week %d    %d days left    %s    Cash %s    %s    Carry %.2f kg    Fire %s" % [
		player_state.get_time_of_day_label(),
		"Camp" if player_state.loop_location_id == SurvivalLoopRulesScript.LOCATION_CAMP else "Town",
		player_state.get_current_week_index(),
		player_state.get_days_remaining_in_month(),
		obligation_label,
		_format_cents(player_state.money_cents),
		player_state.get_support_progress_label(),
		_get_total_inventory_weight(player_state),
		player_state.get_camp_fire_status_label()
	]
	var appearance_tier = SurvivalLoopRulesScript.get_appearance_tier(player_state, config)
	condition_stats_label.text = "Status %s    Appearance: %s" % [
		player_state.get_loop_status_label(),
		String(appearance_tier.get("label", "Unkept"))
	]
	goal_label.text = player_state.passport_profile.current_goal if player_state.passport_profile != null else ""
	if fade_debug_label != null:
		fade_debug_label.text = "Current Fade Value: %d / 100\nCurrent Fade State: %s\nLast Daily Delta: %s%d" % [
			player_state.fade_value,
			FadingMeterSystemScript.get_state_display_name(player_state.fade_state),
			"+" if player_state.fade_last_daily_delta >= 0 else "",
			player_state.fade_last_daily_delta
		]
	if _persistent_condition_strip != null:
		_persistent_condition_strip.set_conditions(_build_condition_surface_data(player_state))
		_set_mouse_filter_recursive(_persistent_condition_strip, Control.MOUSE_FILTER_IGNORE)


func _build_condition_surface_data(player_state) -> Array:
	var conditions: Array = []
	if player_state == null:
		return conditions
	var inventory = player_state.inventory_state
	var max_weight = inventory.max_total_weight_kg if inventory != null else 0.0
	var total_weight = inventory.get_total_weight_kg() if inventory != null else 0.0
	var passport = player_state.passport_profile
	if passport == null:
		return conditions
	conditions.append(_make_condition_entry(&"warmth", "Warmth", passport.warmth))
	conditions.append(_make_condition_entry(&"stamina", "Stamina", _stats_manager.get_stamina(player_state) if _stats_manager != null else 0))
	conditions.append(_make_condition_entry(&"nutrition", "Nutrition", passport.nutrition))
	conditions.append({
		"stat_id": &"water",
		"label": "Water",
		"value_text": "%d/%d" % [int(player_state.camp_potable_water_units), int(player_state.camp_non_potable_water_units)],
		"note": "Camp water on hand for washing, coffee, and cooking.",
		"display_as_bar": false
	})
	conditions.append(_make_condition_entry(&"morale", "Morale", passport.morale))
	conditions.append(_make_condition_entry(&"hygiene", "Hygiene", passport.hygiene))
	conditions.append(_make_condition_entry(&"presentability", "Presentability", passport.presentability))
	conditions.append({
		"stat_id": &"weight",
		"label": "Weight",
		"value_text": "%.1f/%.0fkg" % [total_weight, max_weight],
		"note": "Carry weight decides how hard the body works to keep moving.",
		"display_as_bar": false
	})
	conditions.append(_make_condition_entry(&"dampness", "Dampness", passport.dampness))
	return conditions


func _make_condition_entry(stat_id: StringName, label: String, value: int) -> Dictionary:
	return {
		"stat_id": stat_id,
		"label": label,
		"value_text": "%d" % clampi(value, 0, 100),
		"current": clampi(value, 0, 100),
		"max": 100,
		"display_as_bar": true
	}


func _get_total_inventory_weight(player_state) -> float:
	var inventory = player_state.inventory_state if player_state != null else null
	return inventory.get_total_weight_kg() if inventory != null else 0.0


func _format_cents(amount_cents: int) -> String:
	return "$%.2f" % (float(amount_cents) / 100.0)


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
		"character_rules": _character_rules,
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
	_cooking_page.bootstrap(self, common_deps)
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
	_ui_manager.register_page(&"CookingPage", _cooking_page)
	_ui_manager.register_page(&"PassportStatsPage", _passport_stats_page)
	_ui_manager.register_page(&"EventEncounterPage", _event_encounter_page)
	_ui_manager.register_page(&"RestCampPage", _rest_camp_page)

	_ui_manager.register_route(_location_manager.PAGE_TOWN, &"WorldMapPage")
	_ui_manager.register_route(_location_manager.PAGE_CAMP, &"WorldMapPage")
	_ui_manager.register_route(_location_manager.ROUTE_TRAVEL, &"TravelPage")
	_ui_manager.register_route(_location_manager.ROUTE_LOCATION_PAGE, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_JOBS_BOARD, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_SEND_MONEY, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_GROCERY, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_HARDWARE, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_GENERAL_STORE, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_MEDICINE, &"LocationPage")
	_ui_manager.register_route(_location_manager.PAGE_DOCTOR_APOTHECARY, &"LocationPage")
	_ui_manager.register_route(_location_manager.ROUTE_CRAFTING_PAGE, &"CraftingPage")
	_ui_manager.register_route(_location_manager.PAGE_HOBOCRAFT, &"CraftingPage")
	_ui_manager.register_route(_location_manager.PAGE_COOKING, &"CookingPage")
	_ui_manager.register_route(_location_manager.PAGE_GETTING_READY, &"RestCampPage")
	_ui_manager.register_route(_location_manager.ROUTE_REST_PAGE, &"RestCampPage")
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
	_refresh_shell_status(player_state)
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
	if not _ui_manager.open_page(route):
		_ui_manager.open_page(_location_manager.PAGE_TOWN)
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
