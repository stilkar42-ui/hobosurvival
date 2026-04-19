class_name InventoryPanel
extends PanelContainer

signal stack_selected(stack_index: int)
signal container_selected(provider_id: StringName)
signal destination_focus_changed(provider_id: StringName)
signal stack_context_requested(stack_index: int, screen_position: Vector2)
signal container_context_requested(provider_id: StringName, screen_position: Vector2)
signal move_requested(request: Dictionary)
signal container_popup_requested(provider_id: StringName)

const InventoryDragButtonScript := preload("res://scripts/ui/inventory_drag_button.gd")
const InventoryProviderDropButtonScript := preload("res://scripts/ui/inventory_provider_drop_button.gd")
const InventoryProviderDropTargetScript := preload("res://scripts/ui/inventory_provider_drop_target.gd")

const SMALL_UNITS_PER_MEDIUM_SLOT := 4
const SLOT_BACK := &"slot_back"
const SLOT_SHOULDER_L := &"slot_shoulder_l"
const SLOT_SHOULDER_R := &"slot_shoulder_r"
const SLOT_BELT_WAIST := &"slot_belt_waist"
const SLOT_HAND_L := &"slot_hand_l"
const SLOT_HAND_R := &"slot_hand_r"
const SLOT_PANTS := &"slot_pants"
const SLOT_COAT := &"slot_coat"
const SLOT_GROUND := &"ground_nearby"

var inventory = null
var selected_stack_index := -1
var selected_container_provider_id: StringName = &""
var selected_slot_id: StringName = &""
var focused_destination_provider_id: StringName = &""
var opened_container_provider_id: StringName = &""
var use_focused_container_popups := false

var _root = null
var _summary_label = null
var _main_area = null
var _body_slot_panel = null
var _detail_panel = null
var _container_overlay_host = null
var _container_overlay = null
var _slot_grid = null
var _ledger_panel = null
var _ledger_body = null
var _ledger_toggle_button = null
var _detail_body = null
var _ground_panel = null
var _ground_body = null
var _render_callable = Callable()
var _ledger_visible := false
var _focused_container_provider_id: StringName = &""


func _ready() -> void:
	_render_callable = Callable(self, "_render")
	_build_static_layout()
	_render()


func set_inventory(new_inventory) -> void:
	if _render_callable.is_null():
		_render_callable = Callable(self, "_render")

	if inventory != null and inventory.inventory_changed.is_connected(_render_callable):
		inventory.inventory_changed.disconnect(_render_callable)

	inventory = new_inventory

	if inventory != null and not inventory.inventory_changed.is_connected(_render_callable):
		inventory.inventory_changed.connect(_render_callable)

	_select_default_slot()
	_render()


func set_selected_stack_index(stack_index: int) -> void:
	selected_stack_index = stack_index
	selected_container_provider_id = &""
	_select_slot_for_stack(stack_index)
	_render()
	stack_selected.emit(selected_stack_index)


func set_selected_container_provider_id(provider_id: StringName) -> void:
	selected_stack_index = -1
	selected_container_provider_id = provider_id
	_select_slot_for_provider(provider_id)
	_render()
	container_selected.emit(selected_container_provider_id)


func set_focused_destination_provider_id(provider_id: StringName, should_render: bool = true) -> void:
	var resolved_provider_id = _resolve_destination_provider_id(provider_id)
	if focused_destination_provider_id == resolved_provider_id:
		if should_render:
			_render()
		return
	focused_destination_provider_id = resolved_provider_id
	if should_render:
		_render()
	destination_focus_changed.emit(focused_destination_provider_id)


func open_container(provider_id: StringName) -> void:
	selected_container_provider_id = provider_id
	_select_slot_for_provider(provider_id)
	_render()
	container_popup_requested.emit(provider_id)


func clear_selection() -> void:
	set_selected_stack_index(-1)


func build_stack_drag_payload(stack_index: int) -> Dictionary:
	if inventory == null:
		return {}
	var stack = inventory.get_stack_at(stack_index)
	if stack == null or stack.item == null:
		return {}
	return {
		"kind": &"inventory_drag",
		"dragged_ref": {"type": "stack", "stack_index": stack_index},
		"source_provider_id": StringName(stack.carry_zone)
	}


func build_provider_drag_payload(provider_id: StringName) -> Dictionary:
	if inventory == null:
		return {}
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return {}
	return {
		"kind": &"inventory_drag",
		"dragged_ref": {"type": "provider", "provider_id": provider_id},
		"source_provider_id": StringName(provider.equipment_slot_id)
	}


func preview_move_for_drag(data: Variant, target_provider_id: StringName) -> Dictionary:
	if inventory == null or not inventory.has_method("preview_move"):
		return _drag_move_error(&"inventory_unavailable", "Inventory is not available.", target_provider_id)
	var request = _build_move_request_from_drag_data(data, target_provider_id)
	if request.is_empty():
		return _drag_move_error(&"invalid_drag_payload", "That drag does not describe inventory.", target_provider_id)
	return inventory.preview_move(request)


func request_move_for_drag(data: Variant, target_provider_id: StringName) -> void:
	var request = _build_move_request_from_drag_data(data, target_provider_id)
	if request.is_empty():
		return
	move_requested.emit(request)


func build_container_popup_body(provider_id: StringName) -> Control:
	var provider = inventory.get_storage_provider(provider_id) if inventory != null else null
	var body = VBoxContainer.new()
	body.name = "InventoryContainerPopupBody"
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if provider == null:
		body.add_child(_build_label("That container is no longer available."))
		return body

	body.add_child(_build_label("%s | %s | %.2f kg" % [
		provider.get_mount_label(),
		provider.get_access_speed_name(),
		inventory.get_provider_weight_kg(provider_id)
	]))
	body.add_child(_build_compact_storage_provider_area(provider_id))
	return body


func focus_destination_provider(provider_id: StringName) -> void:
	selected_slot_id = _get_slot_for_provider(provider_id)
	focused_destination_provider_id = _resolve_destination_provider_id(provider_id)
	_render()
	destination_focus_changed.emit(focused_destination_provider_id)


func _build_static_layout() -> void:
	if _root != null and is_instance_valid(_root) and _root.get_parent() == self:
		return
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", _make_panel_style(Color("1f1c19"), Color("6a5847"), 2, 10))

	_root = VBoxContainer.new()
	_root.name = "InventoryPanelRoot"
	_root.add_theme_constant_override("separation", 10)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_root)

	var title_label = Label.new()
	title_label.name = "InventoryPanelTitle"
	title_label.text = "Carried Gear"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.modulate = Color("ddd3c2")
	_root.add_child(title_label)

	_summary_label = Label.new()
	_summary_label.text = "No inventory assigned."
	_summary_label.modulate = Color("bda98f")
	_root.add_child(_summary_label)

	_main_area = VBoxContainer.new()
	_main_area.name = "InventoryBodyCenteredSurface"
	_main_area.add_theme_constant_override("separation", 12)
	_main_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_area.custom_minimum_size = Vector2(0.0, 360.0)
	_root.add_child(_main_area)

	_body_slot_panel = _build_body_slot_panel()
	_detail_panel = _build_detail_panel()
	_main_area.add_child(_body_slot_panel)
	_main_area.add_child(_detail_panel)
	_root.add_child(_build_ground_panel())
	_container_overlay_host = Control.new()
	_container_overlay_host.name = "InventoryPopupLayer"
	_container_overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container_overlay_host)
	_container_overlay = _build_container_overlay()
	_container_overlay_host.add_child(_container_overlay)


func _build_body_slot_panel() -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color("26221d"), Color("7c6950"), 1, 8))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)

	var title = Label.new()
	title.text = "Carried Body"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color("dcd0bc")
	content.add_child(title)

	var hint = Label.new()
	hint.text = "Choose a body location. Items still live in the belongings ledger and storage providers."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color("bda98f")
	content.add_child(hint)

	_slot_grid = VBoxContainer.new()
	_slot_grid.name = "InventoryBodyAnchors"
	_slot_grid.add_theme_constant_override("separation", 6)
	_slot_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slot_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_slot_grid)

	_ledger_toggle_button = Button.new()
	_ledger_toggle_button.name = "BelongingsLedgerToggleButton"
	_ledger_toggle_button.text = "Belongings Ledger"
	_ledger_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_style(_ledger_toggle_button, false, "action")
	_ledger_toggle_button.pressed.connect(Callable(self, "_on_ledger_toggle_pressed"))
	content.add_child(_ledger_toggle_button)

	_ledger_panel = PanelContainer.new()
	_ledger_panel.name = "BelongingsLedgerPanel"
	_ledger_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ledger_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("211d19"), Color("5f5042"), 1, 8))
	content.add_child(_ledger_panel)

	var ledger_scroll = ScrollContainer.new()
	ledger_scroll.name = "BelongingsLedgerScroll"
	ledger_scroll.custom_minimum_size = Vector2(0.0, 180.0)
	ledger_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ledger_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ledger_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ledger_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_ledger_panel.add_child(ledger_scroll)

	_ledger_body = VBoxContainer.new()
	_ledger_body.name = "InventoryItemLedgerRows"
	_ledger_body.add_theme_constant_override("separation", 6)
	_ledger_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ledger_scroll.add_child(_ledger_body)

	return panel


func _build_detail_panel() -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.custom_minimum_size = Vector2(0.0, 112.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color("201e1b"), Color("60554a"), 1, 8))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)

	var title = Label.new()
	title.text = "Location Summary"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color("d9d2c4")
	content.add_child(title)

	var detail_scroll = ScrollContainer.new()
	detail_scroll.name = "SelectedSlotScroll"
	detail_scroll.custom_minimum_size = Vector2(0.0, 64.0)
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(detail_scroll)

	_detail_body = VBoxContainer.new()
	_detail_body.add_theme_constant_override("separation", 8)
	_detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	detail_scroll.add_child(_detail_body)

	return panel


func _build_ground_panel() -> Control:
	_ground_panel = PanelContainer.new()
	_ground_panel.name = "GroundInventoryArea"
	_ground_panel.custom_minimum_size = Vector2(0.0, 150.0)
	_ground_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ground_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_ground_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("1d1916"), Color("705740"), 1, 8))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ground_panel.add_child(content)

	var title = Label.new()
	title.text = "Ground / Nearby"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color("d9cdb8")
	content.add_child(title)

	_ground_body = VBoxContainer.new()
	_ground_body.add_theme_constant_override("separation", 8)
	_ground_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ground_body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_child(_ground_body)

	return _ground_panel


func _render() -> void:
	if _summary_label == null or _slot_grid == null or _ledger_body == null or _detail_body == null or _ground_body == null:
		return

	_clear_children(_slot_grid)
	_clear_children(_ledger_body)
	_clear_children(_detail_body)
	_clear_children(_ground_body)
	if _ledger_panel != null:
		_ledger_panel.visible = _ledger_visible

	if inventory == null:
		_summary_label.text = "No inventory assigned."
		return

	_validate_selection()
	if _focused_container_provider_id != &"" and inventory.get_storage_provider(_focused_container_provider_id) == null:
		_focused_container_provider_id = &""
	if _detail_panel != null:
		_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_summary_label.text = "Total %.2f / %.2f kg    Travel %.2f    Stamina Load %.2f    Awkward %.2f" % [
		inventory.get_total_weight_kg(),
		inventory.max_total_weight_kg,
		inventory.get_travel_speed_modifier(),
		inventory.get_fatigue_burden_modifier(),
		inventory.get_awkward_carry_modifier()
	]

	_render_body_slots()
	_render_selected_slot_detail()
	_render_ground_area()
	_render_container_overlay()


func _render_body_slots() -> void:
	_slot_grid.add_child(_build_silhouette_provider_map())

	if _ledger_toggle_button != null:
		_ledger_toggle_button.text = "Hide Belongings Ledger" if _ledger_visible else "Belongings Ledger"
		_apply_button_style(_ledger_toggle_button, _ledger_visible, "action")

	if not _ledger_visible:
		return

	var has_items := false
	for stack_index in range(inventory.stacks.size()):
		var stack = inventory.get_stack_at(stack_index)
		if stack == null or stack.item == null:
			continue
		has_items = true
		_ledger_body.add_child(_build_stack_row_button(stack_index, stack))

	if not has_items:
		_ledger_body.add_child(_build_label("Nothing carried. That is lighter, but it leaves fewer answers when the road turns."))

	_ledger_body.add_child(_build_heading("Storage Providers"))
	for provider_id in inventory.get_storage_provider_ids():
		_ledger_body.add_child(_build_provider_row_button(provider_id))


func _build_silhouette_provider_map() -> Control:
	var map = HBoxContainer.new()
	map.name = "InventoryProviderMap"
	map.add_theme_constant_override("separation", 8)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var left_column = VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 6)
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(_build_provider_group("Left Side", [SLOT_SHOULDER_L, SLOT_HAND_L, SLOT_COAT, SLOT_PANTS], 1))
	map.add_child(left_column)

	var silhouette = PanelContainer.new()
	silhouette.name = "InventoryProviderSilhouette"
	silhouette.custom_minimum_size = Vector2(260.0, 330.0)
	silhouette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	silhouette.size_flags_vertical = Control.SIZE_EXPAND_FILL
	silhouette.add_theme_stylebox_override("panel", _make_panel_style(Color("181612"), Color("6f5c47"), 1, 8))
	map.add_child(silhouette)

	var silhouette_root = VBoxContainer.new()
	silhouette_root.add_theme_constant_override("separation", 8)
	silhouette_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	silhouette_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	silhouette.add_child(silhouette_root)

	silhouette_root.add_child(_build_head_anchor_button())
	var torso = _build_label("shoulders\ncoat / torso\nbelt / waist\npants")
	torso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	torso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	torso.size_flags_vertical = Control.SIZE_EXPAND_FILL
	torso.add_theme_font_size_override("font_size", 18)
	torso.modulate = Color("d8cbb8")
	silhouette_root.add_child(torso)
	var feet = _build_label("items belong to providers")
	feet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feet.modulate = Color("8f826f")
	silhouette_root.add_child(feet)

	var right_column = VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 6)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_child(_build_provider_group("Right Side", [SLOT_SHOULDER_R, SLOT_HAND_R, SLOT_BACK, SLOT_BELT_WAIST], 1))
	map.add_child(right_column)

	return map


func _build_head_anchor_button() -> Button:
	var button = Button.new()
	button.name = "InventoryLocationButton_head"
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "Head\nno storage provider"
	button.disabled = true
	_apply_disabled_button_style(button)
	return button


func _build_provider_group(title_text: String, slot_ids: Array, columns: int) -> Control:
	var group = VBoxContainer.new()
	group.add_theme_constant_override("separation", 5)
	group.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title = _build_label(title_text)
	title.name = "InventoryProviderGroup_%s" % title_text.replace(" ", "_").replace(",", "")
	title.modulate = Color("d6cab6")
	group.add_child(title)

	var grid = GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group.add_child(grid)

	for slot_id in slot_ids:
		grid.add_child(_build_slot_button(slot_id))

	return group


func _build_slot_button(slot_id: StringName) -> Button:
	var slot_state = inventory.get_equipment_slot(slot_id)
	var button = InventoryProviderDropButtonScript.new()
	button.provider_id = slot_id
	button.inventory_panel = self
	button.name = "InventoryLocationButton_%s" % String(slot_id)
	button.custom_minimum_size = Vector2(146.0, 76.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var item_name = String(slot_state.get("item_name", ""))
	var prefix = ""
	var preferred_provider_id = _get_preferred_destination_provider_for_slot(slot_id)
	if selected_slot_id == slot_id:
		prefix += "* "
	if slot_id == SLOT_GROUND:
		item_name = "nearby"
	if item_name == "":
		item_name = _get_provider_count_label(slot_id)
	elif _get_provider_count_label(slot_id) != "":
		item_name = "%s\n%s" % [item_name, _get_provider_count_label(slot_id)]

	button.text = "%s%s\n%s" % [
		prefix,
		_get_body_slot_label(slot_id),
		item_name
	]
	_apply_button_style(button, selected_slot_id == slot_id, "slot")
	button.pressed.connect(Callable(self, "_on_slot_pressed").bind(slot_id))
	button.gui_input.connect(Callable(self, "_on_slot_button_gui_input").bind(slot_id, button))
	return button


func _render_selected_slot_detail() -> void:
	var selected_stack = inventory.get_stack_at(selected_stack_index)
	if selected_stack != null and selected_stack.item != null:
		_detail_body.add_child(_build_heading(selected_stack.item.display_name))
		_detail_body.add_child(_build_label("Qty %d | %s | %.2f kg | %s" % [
			selected_stack.quantity,
			selected_stack.item.get_category_name().capitalize(),
			selected_stack.get_weight_kg(),
			_get_provider_display_name(StringName(selected_stack.carry_zone))
		]))
		return

	if selected_container_provider_id != &"":
		var selected_provider = inventory.get_storage_provider(selected_container_provider_id)
		if selected_provider != null:
			_detail_body.add_child(_build_heading(selected_provider.display_name))
			_detail_body.add_child(_build_label("%s | %s | %.2f kg | %s" % [
				selected_provider.get_mount_label(),
				selected_provider.get_access_speed_name(),
				inventory.get_provider_weight_kg(selected_container_provider_id),
				_get_container_summary_text(selected_container_provider_id)
			]))
			if selected_provider.source_item_id != &"":
				_detail_body.add_child(_build_container_select_button(selected_container_provider_id))
			return

	if selected_slot_id == &"":
		_detail_body.add_child(_build_label("Select an item or storage place."))
		return

	var slot_state = inventory.get_equipment_slot(selected_slot_id)
	_detail_body.add_child(_build_heading("Place"))

	var item_name = String(slot_state.get("item_name", ""))
	if selected_slot_id == SLOT_GROUND:
		_detail_body.add_child(_build_label("Nearby ground and dropped containers."))
	else:
		_detail_body.add_child(_build_label("Place: %s" % _get_body_slot_label(selected_slot_id)))
		if item_name != "":
			_detail_body.add_child(_build_label("Readied or worn: %s" % item_name))

	var provider_ids = inventory.get_slot_storage_provider_ids(selected_slot_id)
	if provider_ids.is_empty():
		_detail_body.add_child(_build_label("No storage granted."))
		return

	var lines: Array[String] = []
	for provider_id in provider_ids:
		var provider = inventory.get_storage_provider(provider_id)
		if provider != null:
			lines.append("%s %.2f kg" % [provider.display_name, inventory.get_provider_weight_kg(provider_id)])
	_detail_body.add_child(_build_label(" | ".join(lines)))


func _render_ground_area() -> void:
	var ground_stack_indices = _get_stack_indices_for_provider(SLOT_GROUND)
	var grounded_containers = _get_grounded_container_provider_ids()

	if ground_stack_indices.is_empty() and grounded_containers.is_empty():
		_ground_body.add_child(_build_ground_summary_area(ground_stack_indices))
		return

	_ground_body.add_child(_build_ground_summary_area(ground_stack_indices))
	for provider_id in grounded_containers:
		_ground_body.add_child(_build_storage_provider_area(provider_id, true))


func _build_container_overlay() -> Control:
	var overlay = PanelContainer.new()
	overlay.name = "FocusedContainerOverlay"
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.custom_minimum_size = Vector2(420.0, 448.0)
	overlay.size = overlay.custom_minimum_size
	overlay.add_theme_stylebox_override("panel", _make_panel_style(Color("14120f"), Color("9b7a54"), 2, 8))
	return overlay


func _render_container_overlay() -> void:
	if _container_overlay == null:
		return
	_clear_children(_container_overlay)
	_container_overlay.visible = false


func _position_container_overlay() -> void:
	if _container_overlay == null:
		return
	var parent_rect = get_global_rect()
	var overlay_size = Vector2(
		minf(420.0, maxf(320.0, parent_rect.size.x - 32.0)),
		minf(448.0, maxf(300.0, parent_rect.size.y - 32.0))
	)
	var overlay_position = Vector2(
		maxf(12.0, parent_rect.size.x - overlay_size.x - 18.0),
		84.0
	)
	var bottom_limit = parent_rect.size.y - overlay_size.y - 12.0
	if overlay_position.y > bottom_limit:
		overlay_position.y = maxf(12.0, bottom_limit)
	_container_overlay.custom_minimum_size = overlay_size
	_container_overlay.size = overlay_size
	_container_overlay.position = overlay_position


func _build_ground_summary_area(stack_indices: Array) -> Control:
	var zone_panel = InventoryProviderDropTargetScript.new()
	zone_panel.provider_id = SLOT_GROUND
	zone_panel.inventory_panel = self
	zone_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	zone_panel.add_theme_stylebox_override("panel", _make_provider_panel_style(SLOT_GROUND))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_panel.add_child(content)

	var provider = inventory.get_storage_provider(SLOT_GROUND)
	var provider_name = "Ground / Nearby" if provider == null else provider.display_name
	var provider_weight = 0.0 if provider == null else inventory.get_provider_weight_kg(SLOT_GROUND)
	var title = Label.new()
	title.text = "%s    %.2f kg" % [provider_name, provider_weight]
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color("ddd2bf")
	content.add_child(title)

	if stack_indices.is_empty():
		content.add_child(_build_label("Nothing loose is on the ground nearby."))
		return zone_panel

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)

	for stack_index in stack_indices:
		var stack = inventory.get_stack_at(stack_index)
		if stack == null or stack.item == null:
			continue
		grid.add_child(_build_item_cell({
			"stack_index": stack_index,
			"name": "%s x%d" % [_short_name(stack.item.display_name), stack.quantity],
			"size": stack.item.get_size_class_name()
		}, Vector2(150.0, 50.0)))

	return zone_panel


func _build_storage_provider_area(provider_id: StringName, allow_full_width: bool) -> Control:
	var provider = inventory.get_storage_provider(provider_id)
	var zone_panel = InventoryProviderDropTargetScript.new()
	zone_panel.provider_id = provider_id
	zone_panel.inventory_panel = self
	zone_panel.custom_minimum_size = _get_provider_panel_minimum_size(provider_id, allow_full_width)
	zone_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if allow_full_width else Control.SIZE_SHRINK_BEGIN
	zone_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	zone_panel.add_theme_stylebox_override("panel", _make_provider_panel_style(provider_id))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_panel.add_child(content)

	var title = InventoryDragButtonScript.new() if provider.source_item_id != &"" else Label.new()
	title.text = "%s    %.2f kg" % [provider.display_name, inventory.get_provider_weight_kg(provider_id)]
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color("ddd2bf")
	if provider.source_item_id != &"":
		title.flat = true
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.drag_payload = build_provider_drag_payload(provider_id)
		_apply_button_style(title, selected_container_provider_id == provider_id, "slot")
		title.pressed.connect(Callable(self, "_on_container_pressed").bind(provider_id))
		title.gui_input.connect(Callable(self, "_on_container_button_gui_input").bind(provider_id, title))
	content.add_child(title)

	if provider.source_item_id != &"":
		content.add_child(_build_container_select_button(provider_id))

	var meta = Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.text = "%s | %s | stamina load %.2f | awkward %.2f" % [
		provider.get_mount_label(),
		provider.get_access_speed_name(),
		provider.fatigue_modifier,
		provider.awkward_carry_modifier
	]
	meta.modulate = Color("b6a892")
	content.add_child(meta)

	var container = inventory.get_container_profile(provider_id)
	var capacity = Label.new()
	capacity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	capacity.text = "No container profile." if container == null else container.get_capacity_label()
	capacity.modulate = Color("c9bda7")
	content.add_child(capacity)

	content.add_child(_build_medium_slot_section(provider_id, container))
	content.add_child(_build_small_section(provider_id, container, false))
	content.add_child(_build_small_section(provider_id, container, true))

	return zone_panel


func _build_compact_storage_provider_area(provider_id: StringName) -> Control:
	var provider = inventory.get_storage_provider(provider_id)
	var zone_panel = InventoryProviderDropTargetScript.new()
	zone_panel.provider_id = provider_id
	zone_panel.inventory_panel = self
	zone_panel.custom_minimum_size = Vector2(300.0, 0.0)
	zone_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	zone_panel.add_theme_stylebox_override("panel", _make_provider_panel_style(provider_id))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_panel.add_child(content)

	var title = Label.new()
	title.text = "%s    %.2f kg" % [provider.display_name, inventory.get_provider_weight_kg(provider_id)]
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color("ddd2bf")
	content.add_child(title)

	var meta = Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.text = "%s | %s | %s" % [
		provider.get_mount_label(),
		provider.get_access_speed_name(),
		_get_container_summary_text(provider_id)
	]
	meta.modulate = Color("b6a892")
	content.add_child(meta)

	var container = inventory.get_container_profile(provider_id)
	var capacity = Label.new()
	capacity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	capacity.text = "No container profile." if container == null else container.get_capacity_label()
	capacity.modulate = Color("c9bda7")
	content.add_child(capacity)

	var tokens: Array = []
	tokens.append_array(_get_medium_slot_tokens(provider_id))
	tokens.append_array(_get_small_unit_tokens(provider_id))
	if tokens.is_empty():
		content.add_child(_build_label("Empty. Drag something here to stow it."))
		return zone_panel

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for token in tokens:
		grid.add_child(_build_item_cell(token, Vector2(142.0, 46.0)))

	return zone_panel


func _build_container_select_button(provider_id: StringName) -> Button:
	var provider = inventory.get_storage_provider(provider_id)
	var button = InventoryDragButtonScript.new()
	button.drag_payload = build_provider_drag_payload(provider_id)
	var selected_prefix = ""
	if selected_container_provider_id == provider_id:
		selected_prefix += "* "
	button.text = "%sInspect %s" % [selected_prefix, provider.display_name]
	_apply_button_style(button, selected_container_provider_id == provider_id, "action")
	button.pressed.connect(Callable(self, "_on_container_pressed").bind(provider_id))
	button.gui_input.connect(Callable(self, "_on_container_button_gui_input").bind(provider_id, button))
	return button


func _build_focused_container_view(provider_id: StringName) -> Control:
	var provider = inventory.get_storage_provider(provider_id)
	var panel = PanelContainer.new()
	panel.name = "FocusedContainerView"
	panel.custom_minimum_size = Vector2(400.0, 420.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", _make_provider_panel_style(provider_id))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(header)

	var title = Label.new()
	title.text = "Container Detail: %s" % (String(provider_id) if provider == null else provider.display_name)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color("eadcc8")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button = Button.new()
	close_button.name = "CloseFocusedContainerButton"
	close_button.text = "Back to Belongings"
	_apply_button_style(close_button, false, "action")
	close_button.pressed.connect(Callable(self, "_on_close_focused_container_pressed"))
	header.add_child(close_button)

	if provider == null:
		content.add_child(_build_label("That container is no longer available."))
		return panel

	content.add_child(_build_label("%s | %s | %.2f kg" % [
		provider.get_mount_label(),
		provider.get_access_speed_name(),
		inventory.get_provider_weight_kg(provider_id)
	]))

	var body_scroll = ScrollContainer.new()
	body_scroll.name = "FocusedContainerBodyScroll"
	body_scroll.custom_minimum_size = Vector2(0.0, 330.0)
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(body_scroll)

	var body = VBoxContainer.new()
	body.name = "FocusedContainerBody"
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body_scroll.add_child(body)

	var contents_panel = PanelContainer.new()
	contents_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	contents_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("211e1a"), Color("655444"), 1, 8))
	body.add_child(contents_panel)

	var contents_root = VBoxContainer.new()
	contents_root.add_theme_constant_override("separation", 8)
	contents_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents_panel.add_child(contents_root)
	contents_root.add_child(_build_heading("Inside"))
	contents_root.add_child(_build_compact_storage_provider_area(provider_id))

	var destination_panel = PanelContainer.new()
	destination_panel.custom_minimum_size = Vector2(0.0, 0.0)
	destination_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	destination_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	destination_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("1d1a17"), Color("5e5145"), 1, 8))
	body.add_child(destination_panel)

	var destination_root = VBoxContainer.new()
	destination_root.add_theme_constant_override("separation", 8)
	destination_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	destination_panel.add_child(destination_root)
	destination_root.add_child(_build_heading("Visible Places"))
	for slot_id in [SLOT_HAND_L, SLOT_HAND_R, SLOT_COAT, SLOT_BELT_WAIST, SLOT_PANTS, SLOT_SHOULDER_L, SLOT_SHOULDER_R, SLOT_BACK]:
		destination_root.add_child(_build_slot_button(slot_id))
	destination_root.add_child(_build_provider_row_button(SLOT_GROUND))

	return panel


func _build_container_summary_area(provider_id: StringName, allow_full_width: bool) -> Control:
	var provider = inventory.get_storage_provider(provider_id)
	var zone_panel = InventoryProviderDropTargetScript.new()
	zone_panel.provider_id = provider_id
	zone_panel.inventory_panel = self
	zone_panel.custom_minimum_size = Vector2(320.0, 160.0)
	zone_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if allow_full_width else Control.SIZE_SHRINK_BEGIN
	zone_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	zone_panel.add_theme_stylebox_override("panel", _make_provider_panel_style(provider_id))

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone_panel.add_child(content)

	var title = Label.new()
	title.text = "%s    %.2f kg" % [provider.display_name, inventory.get_provider_weight_kg(provider_id)]
	title.add_theme_font_size_override("font_size", 16)
	title.modulate = Color("ddd2bf")
	content.add_child(title)

	content.add_child(_build_container_select_button(provider_id))

	var meta = Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.text = "%s | %s | stamina load %.2f | awkward %.2f" % [
		provider.get_mount_label(),
		provider.get_access_speed_name(),
		provider.fatigue_modifier,
		provider.awkward_carry_modifier
	]
	meta.modulate = Color("b6a892")
	content.add_child(meta)

	var container = inventory.get_container_profile(provider_id)
	var capacity = Label.new()
	capacity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	capacity.text = "No container profile." if container == null else container.get_capacity_label()
	capacity.modulate = Color("c9bda7")
	content.add_child(capacity)

	var contents_label = Label.new()
	contents_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents_label.text = _get_container_summary_text(provider_id)
	contents_label.modulate = Color("d0c1ab")
	content.add_child(contents_label)

	return zone_panel


func _build_medium_slot_section(provider_id: StringName, container) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var label = _build_label("Medium Slots")
	label.modulate = Color("d6cab6")
	section.add_child(label)

	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 4)
	section.add_child(grid)

	if container == null or container.medium_slots <= 0:
		grid.add_child(_build_disabled_cell("none"))
		return section

	var tokens = _get_medium_slot_tokens(provider_id)
	var used_slots = 0
	for token in tokens:
		var span = int(token.get("span", 1))
		var span_width = (110.0 * float(span)) + (4.0 * float(max(span - 1, 0)))
		grid.add_child(_build_item_cell(token, Vector2(span_width, 48.0)))
		used_slots += span

	for index in range(max(container.medium_slots - used_slots, 0)):
		grid.add_child(_build_disabled_cell("empty"))

	return section


func _build_small_section(provider_id: StringName, container, overflow: bool) -> Control:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var label = _build_label("Loose Overflow" if overflow else "Small Capacity")
	label.modulate = Color("d1c4b0")
	section.add_child(label)

	var grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	section.add_child(grid)

	if container == null:
		grid.add_child(_build_disabled_cell("none", Vector2(76.0, 34.0)))
		return section

	var small_tokens = _get_small_unit_tokens(provider_id)
	var clean_capacity = max(floori(float(container.small_capacity) * container.organization_modifier), 0)
	var medium_blocked = inventory.get_provider_medium_units(provider_id) * SMALL_UNITS_PER_MEDIUM_SLOT
	var clean_free_after_medium = max(clean_capacity - medium_blocked, 0)
	var clean_small_used = min(small_tokens.size(), clean_free_after_medium)
	var overflow_small_used = max(small_tokens.size() - clean_small_used, 0)

	if overflow:
		_populate_small_grid(grid, small_tokens, clean_small_used, overflow_small_used, container.overflow_small_capacity, false)
		return section

	for blocked_index in range(min(medium_blocked, clean_capacity)):
		grid.add_child(_build_disabled_cell("medium", Vector2(76.0, 34.0)))

	_populate_small_grid(grid, small_tokens, 0, clean_small_used, clean_free_after_medium, true)
	return section


func _populate_small_grid(grid: GridContainer, small_tokens: Array, token_start: int, used_count: int, capacity: int, show_empty: bool) -> void:
	for index in range(used_count):
		grid.add_child(_build_item_cell(small_tokens[token_start + index], Vector2(76.0, 34.0)))

	if show_empty:
		for index in range(max(capacity - used_count, 0)):
			grid.add_child(_build_disabled_cell("empty", Vector2(76.0, 34.0)))
	else:
		for index in range(max(capacity - used_count, 0)):
			grid.add_child(_build_disabled_cell("overflow", Vector2(76.0, 34.0)))


func _build_item_cell(token: Dictionary, minimum_size: Vector2 = Vector2(110.0, 48.0)) -> Button:
	var button = InventoryDragButtonScript.new()
	button.custom_minimum_size = minimum_size
	button.text = "%s%s\n%s" % [
		"* " if int(token["stack_index"]) == selected_stack_index else "",
		token["name"],
		token["size"]
	]
	var stack = inventory.get_stack_at(int(token["stack_index"])) if inventory != null else null
	if stack != null and stack.item != null:
		button.tooltip_text = stack.item.get_inventory_tooltip_text()
		button.drag_payload = build_stack_drag_payload(int(token["stack_index"]))
	_apply_button_style(button, int(token["stack_index"]) == selected_stack_index, "item")
	if stack != null and stack.item != null:
		var quality_color = stack.get_quality_color()
		button.add_theme_color_override("font_color", quality_color)
		button.add_theme_color_override("font_hover_color", quality_color.lightened(0.12))
		button.add_theme_color_override("font_pressed_color", quality_color.lightened(0.18))
	button.pressed.connect(Callable(self, "_on_stack_cell_pressed").bind(int(token["stack_index"])))
	button.gui_input.connect(Callable(self, "_on_stack_button_gui_input").bind(int(token["stack_index"]), button))
	return button


func _build_stack_row_button(stack_index: int, stack) -> Button:
	var button = InventoryDragButtonScript.new()
	button.name = "InventoryLedgerRow_%d" % stack_index
	button.custom_minimum_size = Vector2(0.0, 58.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var selected_prefix = "* " if stack_index == selected_stack_index else ""
	var action_label = "use" if stack.item.can_use() else "material"
	if stack.item.can_open():
		action_label = "open"
	elif stack.item.can_read():
		action_label = "read"
	button.text = "%s%s x%d    %s    %.2f kg\n%s | %s | %s" % [
		selected_prefix,
		stack.item.display_name,
		stack.quantity,
		_get_provider_display_name(StringName(stack.carry_zone)),
		stack.get_weight_kg(),
		stack.item.get_category_name().capitalize(),
		stack.item.get_size_class_name(),
		action_label
	]
	button.tooltip_text = stack.item.get_inventory_tooltip_text()
	button.drag_payload = build_stack_drag_payload(stack_index)
	_apply_button_style(button, stack_index == selected_stack_index, "item")
	var quality_color = stack.get_quality_color()
	button.add_theme_color_override("font_color", quality_color)
	button.add_theme_color_override("font_hover_color", quality_color.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", quality_color.lightened(0.18))
	button.pressed.connect(Callable(self, "_on_stack_cell_pressed").bind(stack_index))
	button.gui_input.connect(Callable(self, "_on_stack_button_gui_input").bind(stack_index, button))
	return button


func _build_provider_row_button(provider_id: StringName) -> Button:
	var provider = inventory.get_storage_provider(provider_id)
	var button = InventoryProviderDropButtonScript.new()
	button.provider_id = provider_id
	button.inventory_panel = self
	button.name = "InventoryStorageRow_%s" % String(provider_id)
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var selected_prefix = ""
	if selected_container_provider_id == provider_id:
		selected_prefix = "* " + selected_prefix
	var label = String(provider_id) if provider == null else provider.display_name
	button.text = "%s%s    %.2f kg\n%s" % [
		selected_prefix,
		label,
		inventory.get_provider_weight_kg(provider_id),
		_get_provider_capacity_text(provider_id)
	]
	_apply_button_style(button, selected_container_provider_id == provider_id, "slot")
	button.pressed.connect(Callable(self, "_on_container_pressed").bind(provider_id))
	button.gui_input.connect(Callable(self, "_on_container_button_gui_input").bind(provider_id, button))
	return button


func _build_disabled_cell(text: String, minimum_size: Vector2 = Vector2(110.0, 48.0)) -> Button:
	var button = Button.new()
	button.custom_minimum_size = minimum_size
	button.disabled = true
	button.text = text
	_apply_disabled_button_style(button)
	return button


func _build_heading(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color("dfd5c5")
	return label


func _build_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color("cbbca6")
	return label


func _make_provider_panel_style(provider_id: StringName) -> StyleBoxFlat:
	if provider_id == SLOT_GROUND:
		return _make_panel_style(Color("231b16"), Color("7b5d44"), 1, 8)

	var provider = inventory.get_storage_provider(provider_id)
	if provider != null and provider.source_item_id == &"":
		return _make_panel_style(Color("20221f"), Color("596358"), 1, 8)
	return _make_panel_style(Color("24201d"), Color("6b5847"), 1, 8)


func _apply_button_style(button: Button, selected: bool, role: String) -> void:
	var base_color = Color("3a3128")
	var border_color = Color("77624d")
	if role == "slot":
		base_color = Color("332b24")
		border_color = Color("7f6b57")
	elif role == "action":
		base_color = Color("3a2f26")
		border_color = Color("81664d")
	elif role == "item":
		base_color = Color("2f2a24")
		border_color = Color("6b6458")
	if selected:
		base_color = Color("4d3d2f")
		border_color = Color("b28c5a")

	button.add_theme_color_override("font_color", Color("e2d7c5"))
	button.add_theme_color_override("font_hover_color", Color("f0e5d0"))
	button.add_theme_color_override("font_pressed_color", Color("f0e5d0"))
	button.add_theme_color_override("font_disabled_color", Color("857662"))
	button.add_theme_stylebox_override("normal", _make_panel_style(base_color, border_color, 1, 6))
	button.add_theme_stylebox_override("hover", _make_panel_style(base_color.lightened(0.06), border_color.lightened(0.08), 1, 6))
	button.add_theme_stylebox_override("pressed", _make_panel_style(base_color.darkened(0.08), border_color, 1, 6))
	button.add_theme_stylebox_override("disabled", _make_panel_style(Color("28231e"), Color("55493d"), 1, 6))


func _apply_disabled_button_style(button: Button) -> void:
	button.add_theme_color_override("font_disabled_color", Color("776c5d"))
	button.add_theme_stylebox_override("disabled", _make_panel_style(Color("1f1b18"), Color("4d4339"), 1, 6))


func _make_panel_style(bg: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.14)
	style.shadow_size = 6
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	return style


func _get_medium_slot_tokens(provider_id: StringName) -> Array:
	var tokens: Array = []
	for stack_index in range(inventory.stacks.size()):
		var stack = inventory.stacks[stack_index]
		if stack == null or stack.is_empty() or stack.carry_zone != provider_id:
			continue
		var slots_per_unit = stack.item.get_medium_slots_per_unit()
		if slots_per_unit <= 0:
			continue
		for quantity_index in range(stack.quantity):
			var size_label = stack.item.get_size_class_name()
			if slots_per_unit > 1:
				size_label = "%s x%d slots" % [size_label, slots_per_unit]
			tokens.append({
				"stack_index": stack_index,
				"name": _short_name(stack.item.display_name),
				"size": size_label,
				"span": slots_per_unit
			})
	return tokens


func _get_small_unit_tokens(provider_id: StringName) -> Array:
	var tokens: Array = []
	for stack_index in range(inventory.stacks.size()):
		var stack = inventory.stacks[stack_index]
		if stack == null or stack.is_empty() or stack.carry_zone != provider_id:
			continue
		if stack.item.get_small_units_per_unit() <= 0:
			continue
		for quantity_index in range(stack.quantity):
			tokens.append({
				"stack_index": stack_index,
				"name": _short_name(stack.item.display_name),
				"size": stack.item.get_size_class_name()
			})
	return tokens


func _get_grounded_container_provider_ids() -> Array:
	var provider_ids: Array = []
	for provider_id in inventory.get_storage_provider_ids():
		if provider_id == SLOT_GROUND:
			continue
		var provider = inventory.get_storage_provider(provider_id)
		if provider != null and provider.source_item_id != &"" and provider.equipment_slot_id == SLOT_GROUND:
			provider_ids.append(provider_id)
	return provider_ids


func _get_container_summary_text(provider_id: StringName) -> String:
	var stack_count := 0
	var item_total := 0
	for stack in inventory.stacks:
		if stack == null or stack.is_empty() or stack.carry_zone != provider_id:
			continue
		stack_count += 1
		item_total += stack.quantity
	if stack_count <= 0:
		return "Empty."
	return "%d stack%s, %d item%s inside." % [
		stack_count,
		"" if stack_count == 1 else "s",
		item_total,
		"" if item_total == 1 else "s"
	]


func _get_provider_display_name(provider_id: StringName) -> String:
	if inventory == null:
		return String(provider_id)
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return String(provider_id).replace("_", " ").capitalize()
	return provider.display_name


func _get_provider_capacity_text(provider_id: StringName) -> String:
	if inventory == null:
		return ""
	var container = inventory.get_container_profile(provider_id)
	if container == null:
		return "No fixed capacity."
	return "%s | used %d medium, %d small | free %d medium, %d small" % [
		container.get_capacity_label(),
		inventory.get_provider_medium_units(provider_id),
		inventory.get_provider_small_units(provider_id),
		inventory.get_provider_free_medium_units(provider_id),
		inventory.get_provider_free_small_units(provider_id)
	]


func _get_provider_count_label(slot_id: StringName) -> String:
	if inventory == null:
		return ""
	var provider_ids = inventory.get_slot_storage_provider_ids(slot_id)
	if provider_ids.is_empty():
		return "No provider"
	var labels: Array[String] = []
	for provider_id in provider_ids:
		var provider = inventory.get_storage_provider(provider_id)
		if provider == null:
			continue
		var item_total := 0
		for stack in inventory.stacks:
			if stack != null and not stack.is_empty() and stack.carry_zone == provider.provider_id:
				item_total += stack.quantity
		labels.append("%s: %d item%s" % [
			provider.display_name,
			item_total,
			"" if item_total == 1 else "s"
		])
	return "\n".join(labels)


func _get_body_slot_label(slot_id: StringName) -> String:
	match slot_id:
		SLOT_BACK:
			return "Back"
		SLOT_SHOULDER_L:
			return "Left Shoulder"
		SLOT_SHOULDER_R:
			return "Right Shoulder"
		SLOT_BELT_WAIST:
			return "Belt / Waist"
		SLOT_HAND_L:
			return "Left Hand"
		SLOT_HAND_R:
			return "Right Hand"
		SLOT_PANTS:
			return "Pants"
		SLOT_COAT:
			return "Coat"
		SLOT_GROUND:
			return "Ground / Nearby"
		_:
			return String(slot_id).replace("_", " ").capitalize()


func _get_provider_panel_minimum_size(provider_id: StringName, allow_full_width: bool) -> Vector2:
	if not allow_full_width:
		return Vector2(300.0, 0.0)
	var container = inventory.get_container_profile(provider_id)
	if container != null and container.medium_slots >= 4:
		return Vector2(460.0, 0.0)
	return Vector2(320.0, 0.0)


func _get_stack_indices_for_provider(provider_id: StringName) -> Array:
	var stack_indices: Array = []
	if inventory == null:
		return stack_indices
	for stack_index in range(inventory.stacks.size()):
		var stack = inventory.stacks[stack_index]
		if stack == null or stack.is_empty() or stack.carry_zone != provider_id:
			continue
		stack_indices.append(stack_index)
	return stack_indices


func _is_container_provider(provider_id: StringName) -> bool:
	if inventory == null:
		return false
	var provider = inventory.get_storage_provider(provider_id)
	return provider != null and provider.source_item_id != &""


func _select_default_slot() -> void:
	if inventory == null:
		selected_slot_id = &""
		return
	if selected_slot_id == &"":
		var slot_ids = inventory.get_equipment_slot_ids()
		if not slot_ids.is_empty():
			selected_slot_id = slot_ids[0]


func _select_slot_for_stack(stack_index: int) -> void:
	var stack = null
	if inventory != null:
		stack = inventory.get_stack_at(stack_index)
	if stack == null:
		return
	selected_slot_id = _get_slot_for_provider(stack.carry_zone)


func _select_slot_for_provider(provider_id: StringName) -> void:
	selected_slot_id = _get_slot_for_provider(provider_id)


func _get_slot_for_provider(provider_id: StringName) -> StringName:
	if inventory == null:
		return selected_slot_id
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return selected_slot_id
	return provider.equipment_slot_id


func _resolve_destination_provider_id(provider_id: StringName) -> StringName:
	if inventory == null or provider_id == &"":
		return &""
	var provider = inventory.get_storage_provider(provider_id)
	if provider != null:
		return provider.provider_id
	return &""


func _get_preferred_destination_provider_for_slot(slot_id: StringName) -> StringName:
	if inventory == null:
		return &""
	if slot_id == SLOT_GROUND:
		return SLOT_GROUND
	for provider_id in inventory.get_slot_storage_provider_ids(slot_id):
		var provider = inventory.get_storage_provider(provider_id)
		if provider != null and provider.source_item_id != &"":
			return provider.provider_id
	var provider_ids = inventory.get_slot_storage_provider_ids(slot_id)
	if not provider_ids.is_empty():
		return StringName(provider_ids[0])
	return &""


func _validate_selection() -> void:
	if inventory.get_stack_at(selected_stack_index) == null:
		selected_stack_index = -1
	if selected_container_provider_id != &"" and inventory.get_storage_provider(selected_container_provider_id) == null:
		selected_container_provider_id = &""
	if focused_destination_provider_id != &"" and inventory.get_storage_provider(focused_destination_provider_id) == null:
		focused_destination_provider_id = &""
	if selected_container_provider_id != &"" and selected_slot_id == &"":
		selected_slot_id = _get_slot_for_provider(selected_container_provider_id)
	if opened_container_provider_id != &"" and inventory.get_storage_provider(opened_container_provider_id) == null:
		opened_container_provider_id = &""
	if selected_slot_id == &"" or not inventory.get_equipment_slot_ids().has(selected_slot_id):
		_select_default_slot()


func _short_name(display_name: String) -> String:
	if display_name.length() <= 12:
		return display_name
	return display_name.substr(0, 11)


func _build_move_request_from_drag_data(data: Variant, target_provider_id: StringName) -> Dictionary:
	if not (data is Dictionary):
		return {}
	var drag_data: Dictionary = data
	if StringName(drag_data.get("kind", &"")) != &"inventory_drag":
		return {}
	var dragged_ref = drag_data.get("dragged_ref", {})
	if not (dragged_ref is Dictionary):
		return {}
	return {
		"dragged_ref": Dictionary(dragged_ref).duplicate(true),
		"source_provider_id": StringName(drag_data.get("source_provider_id", &"")),
		"target_provider_id": target_provider_id
	}


func _drag_move_error(reason_code: StringName, message: String, target_provider_id: StringName) -> Dictionary:
	return {
		"success": false,
		"reason_code": reason_code,
		"message": message,
		"target_provider_id": target_provider_id,
		"changed": false
	}


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _on_slot_pressed(slot_id: StringName) -> void:
	selected_slot_id = slot_id
	focused_destination_provider_id = &""
	var slot_container_provider_id = _get_first_container_provider_id_for_slot(slot_id)
	selected_stack_index = -1
	selected_container_provider_id = slot_container_provider_id
	if slot_container_provider_id != &"":
		selected_slot_id = _get_slot_for_provider(slot_container_provider_id)
		_render()
		container_selected.emit(selected_container_provider_id)
		container_popup_requested.emit(slot_container_provider_id)
		return
	_render()


func _on_stack_cell_pressed(stack_index: int) -> void:
	set_selected_stack_index(stack_index)


func _on_stack_button_gui_input(event: InputEvent, stack_index: int, button: Button) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	button.accept_event()
	set_selected_stack_index(stack_index)
	stack_context_requested.emit(stack_index, event.global_position)


func _on_slot_button_gui_input(event: InputEvent, slot_id: StringName, button: Button) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	button.accept_event()
	var provider_id = _get_preferred_destination_provider_for_slot(slot_id)
	if provider_id == &"":
		return
	set_selected_container_provider_id(provider_id)
	container_context_requested.emit(provider_id, event.global_position)


func _on_container_pressed(provider_id: StringName) -> void:
	focused_destination_provider_id = &""
	selected_stack_index = -1
	var provider = inventory.get_storage_provider(provider_id) if inventory != null else null
	if provider != null and provider.source_item_id != &"":
		selected_container_provider_id = provider_id
		_select_slot_for_provider(provider_id)
		_render()
		container_selected.emit(selected_container_provider_id)
		container_popup_requested.emit(provider_id)
		return
	set_selected_container_provider_id(provider_id)


func _on_container_button_gui_input(event: InputEvent, provider_id: StringName, button: Button) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	button.accept_event()
	set_selected_container_provider_id(provider_id)
	container_context_requested.emit(provider_id, event.global_position)


func _on_ledger_toggle_pressed() -> void:
	_ledger_visible = not _ledger_visible
	_render()


func _on_close_focused_container_pressed() -> void:
	_focused_container_provider_id = &""
	_render()


func _get_first_container_provider_id_for_slot(slot_id: StringName) -> StringName:
	if slot_id == SLOT_GROUND:
		return &""
	for provider_id in inventory.get_slot_storage_provider_ids(slot_id):
		var provider = inventory.get_storage_provider(provider_id)
		if provider != null and provider.source_item_id != &"":
			return provider_id
	return &""
