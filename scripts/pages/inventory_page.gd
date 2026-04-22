class_name InventoryPage
extends RefCounted

const InventoryManagerScript := preload("res://scripts/managers/inventory_manager.gd")
const InventoryScript := preload("res://scripts/inventory/inventory.gd")
const SurvivalLoopRulesScript := preload("res://scripts/gameplay/survival_loop_rules.gd")

const MENU_MOVE_TO := 2001
const MENU_DROP := 2002
const MENU_EQUIP := 2003
const MENU_UNEQUIP := 2004
const MENU_USE := 2005
const MENU_INSPECT := 2006
const MENU_CANCEL := 2007
const MENU_OPEN := 2008
const MENU_READ := 2009

var _overlay: Control = null
var _window: PanelContainer = null
var _close_button: Button = null
var _open_inventory_button: Button = null
var _summary_label: Label = null
var _selected_item_label: Label = null
var _hint_label: Label = null
var _modal_status_label: Label = null
var _action_summary_label: Label = null
var _destination_label: Label = null
var _move_cancel_button: Button = null
var _transfer_button: Button = null
var _drop_button: Button = null
var _equip_button: Button = null
var _unequip_button: Button = null
var _use_button: Button = null
var _inventory_panel = null
var _inventory_radial_menu = null

var _game_state_manager = null
var _inventory_manager = null
var _data_manager = null
var _ui_manager = null
var _show_status := Callable()
var _resolve_return_route := Callable()

var _last_inventory_message := "Drag anything visible to a visible place. Click to inspect."
var _inventory_move_request := {}
var _inventory_context_stack_index := -1
var _inventory_context_provider_id: StringName = &""
var _inventory_open_context: StringName = &"carried"
var _inventory_container_popups: Dictionary = {}


func bootstrap(_scene_root: Control, deps: Dictionary) -> void:
	_overlay = deps.get("overlay", null)
	_window = deps.get("window", null)
	_close_button = deps.get("close_button", null)
	_open_inventory_button = deps.get("open_inventory_button", null)
	_summary_label = deps.get("summary_label", null)
	_selected_item_label = deps.get("selected_item_label", null)
	_hint_label = deps.get("hint_label", null)
	_modal_status_label = deps.get("modal_status_label", null)
	_action_summary_label = deps.get("action_summary_label", null)
	_destination_label = deps.get("destination_label", null)
	_move_cancel_button = deps.get("move_cancel_button", null)
	_transfer_button = deps.get("transfer_button", null)
	_drop_button = deps.get("drop_button", null)
	_equip_button = deps.get("equip_button", null)
	_unequip_button = deps.get("unequip_button", null)
	_use_button = deps.get("use_button", null)
	_inventory_panel = deps.get("inventory_panel", null)
	_inventory_radial_menu = deps.get("inventory_radial_menu", null)

	_game_state_manager = deps.get("game_state_manager", null)
	_inventory_manager = deps.get("inventory_manager", null)
	_data_manager = deps.get("data_manager", null)
	_ui_manager = deps.get("ui_manager", null)
	_show_status = deps.get("show_status", Callable())
	_resolve_return_route = deps.get("resolve_return_route", Callable())

	if _overlay != null:
		_overlay.visible = false
	if _close_button != null and not _close_button.pressed.is_connected(Callable(self, "_close_inventory")):
		_close_button.pressed.connect(Callable(self, "_close_inventory"))
	if _open_inventory_button != null:
		_open_inventory_button.text = "Open Inventory"
		if not _open_inventory_button.pressed.is_connected(Callable(self, "_open_inventory")):
			_open_inventory_button.pressed.connect(Callable(self, "_open_inventory"))
	if _move_cancel_button != null and not _move_cancel_button.pressed.is_connected(Callable(self, "_cancel_inventory_move")):
		_move_cancel_button.pressed.connect(Callable(self, "_cancel_inventory_move"))
	if _transfer_button != null and not _transfer_button.pressed.is_connected(Callable(self, "_on_inventory_transfer_pressed")):
		_transfer_button.pressed.connect(Callable(self, "_on_inventory_transfer_pressed"))
	if _drop_button != null and not _drop_button.pressed.is_connected(Callable(self, "_on_inventory_drop_pressed")):
		_drop_button.pressed.connect(Callable(self, "_on_inventory_drop_pressed"))
	if _equip_button != null and not _equip_button.pressed.is_connected(Callable(self, "_on_inventory_equip_pressed")):
		_equip_button.pressed.connect(Callable(self, "_on_inventory_equip_pressed"))
	if _unequip_button != null and not _unequip_button.pressed.is_connected(Callable(self, "_on_inventory_unequip_pressed")):
		_unequip_button.pressed.connect(Callable(self, "_on_inventory_unequip_pressed"))
	if _use_button != null and not _use_button.pressed.is_connected(Callable(self, "_execute_inventory_use_action").bind(-1)):
		_use_button.pressed.connect(Callable(self, "_execute_inventory_use_action").bind(-1))

	_connect_inventory_panel()
	if _game_state_manager != null and not _game_state_manager.player_state_changed.is_connected(Callable(self, "refresh_from_state")):
		_game_state_manager.player_state_changed.connect(Callable(self, "refresh_from_state"))
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func set_route(route_name: StringName) -> void:
	_inventory_open_context = &"stash" if route_name == &"inventory_ui" else &"carried"
	set_visible(true)


func set_visible(visible: bool) -> void:
	if _overlay != null:
		_overlay.visible = visible
	if not visible:
		_cancel_inventory_move("")
		_close_all_inventory_container_popups()
		if _inventory_radial_menu != null:
			_inventory_radial_menu.hide_menu()


func refresh_from_state(player_state) -> void:
	if _inventory_panel == null:
		return
	if player_state == null:
		_inventory_panel.set_inventory(null)
		return
	_inventory_panel.set_inventory(player_state.inventory_state)
	_refresh_inventory_summary(player_state)
	_refresh_inventory_modal(player_state)
	_refresh_inventory_container_popups()


func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if _overlay != null and _overlay.visible:
			_close_inventory()
		else:
			_open_inventory()
		return true
	if _overlay == null or not _overlay.visible:
		return false
	if event.is_action_pressed("ui_cancel"):
		if _inventory_radial_menu != null and _inventory_radial_menu.visible:
			_inventory_radial_menu.hide_menu()
			return true
		if not _inventory_move_request.is_empty():
			_cancel_inventory_move("Move canceled.")
			return true
		_close_inventory()
		return true
	return false


func _connect_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	_inventory_panel.use_focused_container_popups = false
	if not _inventory_panel.stack_selected.is_connected(Callable(self, "_on_inventory_selection_changed")):
		_inventory_panel.stack_selected.connect(Callable(self, "_on_inventory_selection_changed"))
	if not _inventory_panel.container_selected.is_connected(Callable(self, "_on_inventory_selection_changed")):
		_inventory_panel.container_selected.connect(Callable(self, "_on_inventory_selection_changed"))
	if not _inventory_panel.destination_focus_changed.is_connected(Callable(self, "_on_inventory_destination_focus_changed")):
		_inventory_panel.destination_focus_changed.connect(Callable(self, "_on_inventory_destination_focus_changed"))
	if not _inventory_panel.stack_context_requested.is_connected(Callable(self, "_on_inventory_stack_context_requested")):
		_inventory_panel.stack_context_requested.connect(Callable(self, "_on_inventory_stack_context_requested"))
	if not _inventory_panel.container_context_requested.is_connected(Callable(self, "_on_inventory_container_context_requested")):
		_inventory_panel.container_context_requested.connect(Callable(self, "_on_inventory_container_context_requested"))
	if not _inventory_panel.move_requested.is_connected(Callable(self, "_on_inventory_move_requested")):
		_inventory_panel.move_requested.connect(Callable(self, "_on_inventory_move_requested"))
	if not _inventory_panel.container_popup_requested.is_connected(Callable(self, "_on_inventory_container_popup_requested")):
		_inventory_panel.container_popup_requested.connect(Callable(self, "_on_inventory_container_popup_requested"))
	if _inventory_radial_menu != null:
		if not _inventory_radial_menu.action_selected.is_connected(Callable(self, "_on_inventory_context_menu_id_pressed")):
			_inventory_radial_menu.action_selected.connect(Callable(self, "_on_inventory_context_menu_id_pressed"))
		if not _inventory_radial_menu.canceled.is_connected(Callable(self, "_on_inventory_context_menu_canceled")):
			_inventory_radial_menu.canceled.connect(Callable(self, "_on_inventory_context_menu_canceled"))


func _open_inventory() -> void:
	if _ui_manager != null:
		_ui_manager.switch_to(&"inventory_ui")


func _close_inventory() -> void:
	if _ui_manager == null or _resolve_return_route.is_null():
		return
	_ui_manager.switch_to(StringName(_resolve_return_route.call()))


func _refresh_inventory_summary(player_state) -> void:
	var inventory = player_state.inventory_state
	var food_count = _count_item_group(inventory, [&"beans_can", &"bread_loaf", &"stew_tin", &"potted_meat"])
	var comfort_count = _count_item_group(inventory, [&"hot_coffee", &"coffee_thermos", &"smoke_tobacco"])
	var camp_supply_count = _count_item_group(inventory, [&"coffee_grounds", &"empty_can", &"cordage", &"dry_kindling"])
	var scrap_count = inventory.count_item(&"scrap_tin")
	_summary_label.text = "Carry %.2f / %.2f kg\nFood %d    Comfort %d    Camp %d    Scrap %d\nFire %s" % [
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
		_selected_item_label.text = "No item selected.\nOpen inventory to choose food, coffee, tobacco, soap, papers, or other carried items for direct use."
		_selected_item_label.tooltip_text = ""
		_hint_label.text = "Inventory and passport access."
		return
	var detail_text = _build_selected_item_text(selected_stack)
	if player_state.has_method("is_stack_equipped") and player_state.is_stack_equipped(_inventory_panel.selected_stack_index):
		detail_text += "\nReadied in %s." % _get_slot_label(StringName(selected_stack.carry_zone))
	_selected_item_label.text = detail_text
	_selected_item_label.tooltip_text = selected_stack.item.get_inventory_tooltip_text() if selected_stack.item != null else ""
	_selected_item_label.modulate = selected_stack.get_quality_color() if selected_stack.has_method("get_quality_color") else Color("d9e2e6")
	_hint_label.text = "Inventory and passport access."


func _refresh_inventory_modal(player_state) -> void:
	if _modal_status_label == null:
		return
	_modal_status_label.text = _build_inventory_modal_status(player_state)
	_action_summary_label.text = _build_inventory_action_summary(player_state)
	_destination_label.text = _build_inventory_destination_text(player_state)
	if _move_cancel_button != null:
		_move_cancel_button.visible = not _inventory_move_request.is_empty()


func _on_inventory_selection_changed(_value = null) -> void:
	if not _inventory_move_request.is_empty() and _inventory_panel.selected_stack_index != int(_inventory_move_request.get("stack_index", -1)):
		_cancel_inventory_move("Move canceled.")
		return
	refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)


func _on_inventory_destination_focus_changed(_provider_id = &"") -> void:
	if _inventory_move_request.is_empty():
		refresh_from_state(_game_state_manager.get_player_state() if _game_state_manager != null else null)
		return
	_attempt_inventory_move_destination()


func _on_inventory_move_requested(request: Dictionary) -> void:
	_inventory_move_request = {}
	var payload = request.duplicate(true)
	payload["source"] = "inventory.drag_move"
	var result = _inventory_manager.execute_action(InventoryManagerScript.ACTION_MOVE, payload)
	_apply_inventory_result(result)


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
		_overlay.add_child(popup)
		popup.position = Vector2(40.0 + (24.0 * _inventory_container_popups.size()), 80.0 + (18.0 * _inventory_container_popups.size()))
	_rebuild_inventory_container_popup(provider_id, popup)


func _build_inventory_container_popup(provider_id: StringName, display_name: String) -> PanelContainer:
	var popup = PanelContainer.new()
	popup.name = "InventoryContainerPopup_%s" % String(provider_id)
	popup.custom_minimum_size = Vector2(420.0, 380.0)
	popup.size = popup.custom_minimum_size
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	popup.add_child(root)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)
	var title = Label.new()
	title.name = "InventoryContainerPopupTitle"
	title.text = display_name
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button = Button.new()
	close_button.text = "Close"
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
	if _inventory_panel != null and _inventory_panel.has_method("build_container_popup_body"):
		body_scroll.add_child(_inventory_panel.call("build_container_popup_body", provider_id))
	popup.size = popup.custom_minimum_size
	popup.move_to_front()


func _refresh_inventory_container_popups() -> void:
	if _overlay == null or not _overlay.visible:
		return
	for provider_id in _inventory_container_popups.keys():
		var popup = _inventory_container_popups.get(provider_id, null)
		if popup == null or not is_instance_valid(popup):
			continue
		_rebuild_inventory_container_popup(StringName(provider_id), popup)


func _close_inventory_container_popup(provider_id: StringName) -> void:
	var popup = _inventory_container_popups.get(provider_id, null)
	_inventory_container_popups.erase(provider_id)
	if popup != null and is_instance_valid(popup):
		popup.queue_free()


func _close_all_inventory_container_popups() -> void:
	for provider_id in _inventory_container_popups.keys():
		var popup = _inventory_container_popups.get(provider_id, null)
		if popup != null and is_instance_valid(popup):
			popup.queue_free()
	_inventory_container_popups.clear()


func _on_inventory_stack_context_requested(stack_index: int, screen_position: Vector2) -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var stack = _inventory_manager.get_stack_at(player_state, stack_index)
	if stack == null or stack.item == null:
		return
	_inventory_panel.set_selected_stack_index(stack_index)
	_inventory_context_stack_index = stack_index
	_inventory_context_provider_id = &""
	_show_inventory_radial_menu(_build_inventory_stack_context_actions(player_state, stack_index, stack), screen_position)


func _on_inventory_container_context_requested(provider_id: StringName, screen_position: Vector2) -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var provider = _inventory_manager.get_storage_provider(player_state, provider_id)
	if provider == null:
		return
	_inventory_panel.set_selected_container_provider_id(provider_id)
	_inventory_context_stack_index = -1
	_inventory_context_provider_id = provider_id
	_show_inventory_radial_menu(_build_inventory_container_context_actions(player_state, provider), screen_position)


func _show_inventory_radial_menu(actions: Array, screen_position: Vector2) -> void:
	if _inventory_radial_menu != null and not actions.is_empty():
		_inventory_radial_menu.popup_actions(actions, screen_position)


func _on_inventory_context_menu_id_pressed(id: int) -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	if _inventory_radial_menu != null:
		_inventory_radial_menu.hide_menu()
	var stack_index = _inventory_context_stack_index if _inventory_context_stack_index >= 0 else _inventory_panel.selected_stack_index
	var provider_id = _inventory_context_provider_id if _inventory_context_provider_id != &"" else _inventory_panel.selected_container_provider_id
	match id:
		MENU_MOVE_TO:
			if stack_index >= 0:
				_inventory_panel.set_selected_stack_index(stack_index)
				_start_inventory_move_mode("")
		MENU_OPEN:
			if provider_id != &"":
				_inventory_panel.set_selected_container_provider_id(provider_id)
				_open_selected_container()
		MENU_DROP:
			_on_inventory_drop_pressed(stack_index, provider_id)
		MENU_EQUIP:
			_on_inventory_equip_pressed(stack_index, provider_id)
		MENU_UNEQUIP:
			_on_inventory_unequip_pressed(stack_index, provider_id)
		MENU_USE:
			_execute_inventory_use_action(stack_index)
		MENU_READ:
			_execute_inventory_read_action(stack_index)
		MENU_INSPECT:
			_execute_inventory_inspect_action(stack_index, provider_id)
		MENU_CANCEL:
			pass
	refresh_from_state(player_state)


func _on_inventory_context_menu_canceled() -> void:
	_inventory_context_stack_index = -1
	_inventory_context_provider_id = &""
	refresh_from_state(_get_player_state())


func _on_inventory_transfer_pressed() -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var action = _get_stack_transfer_action(player_state)
	if action.is_empty():
		_last_inventory_message = "Select a stack and a valid destination first."
		refresh_from_state(player_state)
		return
	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE_STACK,
		{
			"source": "inventory.transfer_button",
			"stack_index": _inventory_panel.selected_stack_index,
			"selected_stack_index": _inventory_panel.selected_stack_index,
			"target_provider_id": StringName(action.get("target_provider_id", &""))
		}
	)
	_apply_inventory_result(result)


func _on_inventory_drop_pressed(stack_index: int = -1, provider_id: StringName = &"") -> void:
	var resolved_provider_id = provider_id if provider_id != &"" else _inventory_panel.selected_container_provider_id
	var resolved_stack_index = stack_index if stack_index >= 0 else _inventory_panel.selected_stack_index
	var result = {}
	if resolved_provider_id != &"":
		result = _inventory_manager.execute_action(
			InventoryManagerScript.ACTION_DROP_CONTAINER,
			{"source": "inventory.drop_container", "provider_id": resolved_provider_id}
		)
	else:
		result = _inventory_manager.execute_action(
			InventoryManagerScript.ACTION_DROP_STACK,
			{"source": "inventory.drop_stack", "stack_index": resolved_stack_index, "selected_stack_index": resolved_stack_index}
		)
	_apply_inventory_result(result)


func _on_inventory_equip_pressed(stack_index: int = -1, provider_id: StringName = &"") -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var resolved_provider_id = provider_id if provider_id != &"" else _inventory_panel.selected_container_provider_id
	var resolved_stack_index = stack_index if stack_index >= 0 else _inventory_panel.selected_stack_index
	var result = {}
	if resolved_provider_id != &"":
		var equip_target = _resolve_container_equip_target(player_state, resolved_provider_id)
		if not bool(equip_target.get("success", false)):
			_apply_inventory_result({"success": false, "message": String(equip_target.get("message", "Could not equip the selected container."))})
			return
		result = _inventory_manager.execute_action(
			InventoryManagerScript.ACTION_EQUIP_CONTAINER,
			{
				"source": "inventory.equip_container",
				"provider_id": resolved_provider_id,
				"target_slot_id": StringName(equip_target.get("slot_id", &""))
			}
		)
	else:
		result = _inventory_manager.execute_action(
			InventoryManagerScript.ACTION_EQUIP_STACK,
			{"source": "inventory.equip_stack", "stack_index": resolved_stack_index, "selected_stack_index": resolved_stack_index}
		)
	_apply_inventory_result(result)


func _on_inventory_unequip_pressed(stack_index: int = -1, provider_id: StringName = &"") -> void:
	var player_state = _get_player_state()
	if player_state == null:
		return
	var resolved_provider_id = provider_id if provider_id != &"" else _inventory_panel.selected_container_provider_id
	if resolved_provider_id != &"":
		_apply_inventory_result(_inventory_manager.execute_action(
			InventoryManagerScript.ACTION_DROP_CONTAINER,
			{"source": "inventory.unequip_container", "provider_id": resolved_provider_id}
		))
		return
	if stack_index >= 0:
		_inventory_panel.set_selected_stack_index(stack_index)
	_start_inventory_move_mode("Unequip")


func _open_selected_container() -> void:
	var provider_id = _inventory_panel.selected_container_provider_id
	if provider_id == &"":
		return
	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_OPEN_CONTAINER,
		{"source": "inventory.open_container", "provider_id": provider_id}
	)
	_apply_inventory_result(result)
	if bool(result.get("success", false)):
		_inventory_panel.open_container(provider_id)


func _execute_inventory_use_action(stack_index: int = -1) -> void:
	var resolved_stack_index = stack_index if stack_index >= 0 else _inventory_panel.selected_stack_index
	var result = _game_state_manager.execute_action(String(SurvivalLoopRulesScript.ACTION_USE_SELECTED), {
		"source": "inventory.use",
		"selected_stack_index": resolved_stack_index
	})
	_apply_inventory_result(result)


func _execute_inventory_read_action(stack_index: int) -> void:
	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_READ_STACK,
		{"source": "inventory.read", "stack_index": stack_index, "selected_stack_index": stack_index}
	)
	_apply_inventory_result(result)


func _execute_inventory_inspect_action(stack_index: int, provider_id: StringName) -> void:
	var result = {}
	if provider_id != &"":
		result = _inventory_manager.execute_action(
			InventoryManagerScript.ACTION_INSPECT_CONTAINER,
			{"source": "inventory.inspect_container", "provider_id": provider_id}
		)
	else:
		result = _inventory_manager.execute_action(
			InventoryManagerScript.ACTION_INSPECT_STACK,
			{"source": "inventory.inspect_stack", "stack_index": stack_index, "selected_stack_index": stack_index}
		)
	_apply_inventory_result(result)


func _start_inventory_move_mode(required_verb: String) -> void:
	var player_state = _get_player_state()
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return
	_inventory_move_request = {
		"stack_index": _inventory_panel.selected_stack_index,
		"item_name": selected_stack.item.display_name,
		"quantity": selected_stack.quantity,
		"required_verb": required_verb
	}
	_last_inventory_message = "Unequip %s by left-clicking a storage destination." % selected_stack.item.display_name if required_verb == "Unequip" else "Move %s by left-clicking a destination slot or container." % selected_stack.item.display_name
	refresh_from_state(player_state)


func _cancel_inventory_move(message: String = "") -> void:
	_inventory_move_request = {}
	if message != "":
		_last_inventory_message = message
	refresh_from_state(_get_player_state())


func _attempt_inventory_move_destination() -> void:
	var player_state = _get_player_state()
	if player_state == null or _inventory_move_request.is_empty():
		return
	var focused_provider = _get_focused_destination_provider(player_state)
	if focused_provider == null:
		refresh_from_state(player_state)
		return
	var action = _get_stack_transfer_action_for_target(player_state, StringName(focused_provider.provider_id))
	if action.is_empty():
		_last_inventory_message = "That destination cannot receive %s." % String(_inventory_move_request.get("item_name", "that item"))
		refresh_from_state(player_state)
		return
	var required_verb = String(_inventory_move_request.get("required_verb", ""))
	if required_verb != "" and String(action.get("verb", "")) != required_verb:
		_last_inventory_message = "Select a storage destination to unequip %s into." % String(_inventory_move_request.get("item_name", "that item"))
		refresh_from_state(player_state)
		return
	var result = _inventory_manager.execute_action(
		InventoryManagerScript.ACTION_MOVE_STACK,
		{
			"source": "inventory.move_destination",
			"stack_index": _inventory_panel.selected_stack_index,
			"selected_stack_index": _inventory_panel.selected_stack_index,
			"target_provider_id": StringName(action.get("target_provider_id", &""))
		}
	)
	if bool(result.get("success", false)):
		_inventory_move_request = {}
	_apply_inventory_result(result)


func _apply_inventory_result(result: Dictionary) -> void:
	_last_inventory_message = String(result.get("message", "No result message."))
	if _show_status.is_valid():
		_show_status.call(_last_inventory_message)
	refresh_from_state(_get_player_state())


func _build_inventory_modal_status(player_state) -> String:
	if player_state == null:
		return "Waiting for shared state."
	if not _inventory_move_request.is_empty():
		return "%s\n%s" % [_last_inventory_message, _build_inventory_move_destination_text(player_state)]
	var selected_container = _get_selected_container_provider(player_state)
	if selected_container != null:
		return "%s\nSelected container: %s in %s." % [
			_last_inventory_message,
			selected_container.display_name,
			_get_provider_location_label(player_state.inventory_state, selected_container.provider_id)
		]
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null:
		return "%s\nDetailed inventory management. Left-click to inspect. Right-click an item or container for actions." % _last_inventory_message
	return "%s\nSelected %s in %s." % [
		_last_inventory_message,
		selected_stack.item.display_name,
		_get_provider_location_label(player_state.inventory_state, selected_stack.carry_zone)
	]


func _build_inventory_action_summary(player_state) -> String:
	if player_state == null:
		return ""
	if not _inventory_move_request.is_empty():
		return _build_inventory_move_summary(player_state)
	var selected_stack = _get_selected_stack(player_state)
	var selected_container = _get_selected_container_provider(player_state)
	if selected_container != null:
		return "Selected container: %s in %s." % [
			selected_container.display_name,
			_get_provider_location_label(player_state.inventory_state, selected_container.provider_id)
		]
	if selected_stack == null or selected_stack.item == null:
		return "Left-click an item to inspect it. Right-click an item or container for actions."
	var readied_suffix = " (readied)" if player_state.has_method("is_stack_equipped") and player_state.is_stack_equipped(_inventory_panel.selected_stack_index) else ""
	return "Selected item: %s x%d%s in %s." % [
		selected_stack.item.display_name,
		selected_stack.quantity,
		readied_suffix,
		_get_provider_location_label(player_state.inventory_state, selected_stack.carry_zone)
	]


func _build_inventory_destination_text(player_state) -> String:
	var focused_provider = _get_focused_destination_provider(player_state)
	if focused_provider == null:
		return "Destination Focus: none selected."
	return "Destination Focus: %s in %s." % [
		focused_provider.display_name,
		_get_provider_location_label(player_state.inventory_state, focused_provider.provider_id)
	]


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


func _build_inventory_stack_context_actions(player_state, stack_index: int, selected_stack) -> Array:
	var actions: Array = []
	actions.append(_make_radial_action(MENU_MOVE_TO, "Move To...", "Pick a slot or container after choosing this action."))
	actions.append(_make_radial_action(MENU_DROP, "Drop", "Put %s onto the ground nearby." % selected_stack.item.display_name))
	if selected_stack.item.can_equip():
		actions.append(_make_radial_action(MENU_EQUIP, "Equip", "Ready the item as an active tool or improvised weapon."))
	if _is_hand_provider(StringName(selected_stack.carry_zone)):
		actions.append(_make_radial_action(MENU_UNEQUIP, "Unequip", "Choose where to put %s down from your hand." % selected_stack.item.display_name))
	if selected_stack.item.can_use():
		actions.append(_make_radial_action(MENU_USE, "Use", selected_stack.item.get_inventory_tooltip_text()))
	if selected_stack.item.can_read():
		actions.append(_make_radial_action(MENU_READ, "Read", selected_stack.item.get_read_text()))
	actions.append(_make_radial_action(MENU_INSPECT, "Inspect", selected_stack.item.get_inventory_tooltip_text()))
	actions.append(_make_radial_action(MENU_CANCEL, "Cancel", "Close this action menu.", true))
	return actions


func _build_inventory_container_context_actions(player_state, provider) -> Array:
	var actions: Array = []
	var item_definition = _data_manager.get_item_definition(provider.source_item_id) if _data_manager != null else null
	var can_open_container = provider.source_item_id != &""
	if item_definition != null:
		can_open_container = item_definition.can_open()
	if can_open_container:
		actions.append(_make_radial_action(MENU_OPEN, "Open", "Open %s and inspect what it is carrying." % provider.display_name))
	actions.append(_make_radial_action(MENU_EQUIP, "Equip", "Equip %s if a valid slot is open." % provider.display_name))
	if StringName(provider.equipment_slot_id) != InventoryScript.CARRY_GROUND:
		actions.append(_make_radial_action(MENU_UNEQUIP, "Unequip", "Drop %s to the ground nearby." % provider.display_name))
	actions.append(_make_radial_action(MENU_INSPECT, "Inspect", _build_inventory_modal_status(player_state)))
	actions.append(_make_radial_action(MENU_CANCEL, "Cancel", "Close this action menu.", true))
	return actions


func _make_radial_action(action_id: int, label: String, tooltip: String, is_cancel: bool = false) -> Dictionary:
	return {"id": action_id, "label": label, "tooltip": tooltip, "is_cancel": is_cancel}


func _get_stack_transfer_action(player_state) -> Dictionary:
	var target_provider = _get_focused_destination_provider(player_state)
	if target_provider == null:
		return {}
	return _get_stack_transfer_action_for_target(player_state, StringName(target_provider.provider_id))


func _get_stack_transfer_action_for_target(player_state, target_provider_id: StringName) -> Dictionary:
	var selected_stack = _get_selected_stack(player_state)
	if selected_stack == null or selected_stack.item == null:
		return {}
	var inventory = player_state.inventory_state
	var target_provider = inventory.get_storage_provider(target_provider_id)
	if target_provider == null:
		return {}
	var source_provider_id = StringName(selected_stack.carry_zone)
	if target_provider_id == source_provider_id:
		return {}
	var verb := "Move"
	if _is_ground_provider(target_provider_id):
		verb = "Drop"
	elif _is_hand_provider(target_provider_id):
		verb = "Hold"
	elif _is_ground_provider(source_provider_id):
		verb = "Take"
	elif _is_hand_provider(source_provider_id) and not _is_hand_provider(target_provider_id):
		verb = "Unequip"
	elif not _is_hand_provider(target_provider_id):
		verb = "Store"
	var simulated_result = _inventory_manager.simulate_stack_move(player_state, _inventory_panel.selected_stack_index, target_provider_id)
	return {
		"enabled": bool(simulated_result.get("success", false)),
		"verb": verb,
		"target_provider_id": target_provider_id,
		"reason": String(simulated_result.get("message", ""))
	}


func _resolve_container_equip_target(player_state, provider_id: StringName) -> Dictionary:
	var inventory = player_state.inventory_state
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return {"success": false, "message": "No container selected."}
	var valid_slots = _get_valid_slots_for_container(provider)
	if valid_slots.is_empty():
		return {"success": false, "message": "%s cannot be equipped in this prototype." % provider.display_name}
	var preferred_slots: Array = []
	if valid_slots.has(_inventory_panel.selected_slot_id):
		preferred_slots.append(_inventory_panel.selected_slot_id)
	for slot_id in valid_slots:
		if not preferred_slots.has(slot_id):
			preferred_slots.append(slot_id)
	for slot_id in preferred_slots:
		var simulated = _inventory_manager.simulate_container_equip(player_state, provider_id, slot_id)
		if bool(simulated.get("success", false)):
			return {"success": true, "slot_id": slot_id}
	return {"success": false, "message": "No valid equipment slot is open for that container."}


func _get_valid_slots_for_container(provider) -> Array:
	if provider == null:
		return []
	var item_definition = _data_manager.get_item_definition(provider.source_item_id) if _data_manager != null else null
	if item_definition != null:
		return item_definition.get_valid_equip_slots()
	match provider.source_item_id:
		&"backpack":
			return [InventoryScript.SLOT_BACK]
		&"satchel", &"haversack":
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


func _get_player_state():
	return _game_state_manager.get_player_state() if _game_state_manager != null else null


func _get_selected_stack(player_state):
	return _inventory_manager.get_stack_at(player_state, _inventory_panel.selected_stack_index) if _inventory_manager != null and _inventory_panel != null else null


func _get_selected_container_provider(player_state):
	if player_state == null or _inventory_panel == null or _inventory_panel.selected_container_provider_id == &"":
		return null
	return _inventory_manager.get_storage_provider(player_state, _inventory_panel.selected_container_provider_id)


func _get_focused_destination_provider(player_state):
	if player_state == null or _inventory_panel == null or _inventory_panel.focused_destination_provider_id == &"":
		return null
	return _inventory_manager.get_storage_provider(player_state, _inventory_panel.focused_destination_provider_id)


func _get_provider_location_label(inventory, provider_id: StringName) -> String:
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return "nowhere"
	if provider.provider_id == InventoryScript.CARRY_GROUND:
		return "Ground / Nearby"
	return _get_slot_label(StringName(provider.equipment_slot_id))


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


func _is_hand_provider(provider_id: StringName) -> bool:
	return provider_id == InventoryScript.SLOT_HAND_L or provider_id == InventoryScript.SLOT_HAND_R


func _is_ground_provider(provider_id: StringName) -> bool:
	return provider_id == InventoryScript.CARRY_GROUND


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


func _build_item_effect_summary(item) -> String:
	return ", ".join(item.get_consumable_effect_lines()) if item != null else ""


func _count_item_group(inventory, item_ids: Array) -> int:
	var total := 0
	for item_id in item_ids:
		total += inventory.count_item(StringName(item_id))
	return total
