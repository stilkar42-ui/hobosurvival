extends Control

const InventoryScript := preload("res://scripts/inventory/inventory.gd")
const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")
const PlayerStateRuntimeScript := preload("res://scripts/player/player_state_runtime.gd")
const PlayerStateServiceScript := preload("res://scripts/player/player_state_service.gd")

@onready var inventory_panel = $Root/InventoryPanel
@onready var status_label = $Root/DebugActions/ActionRoot/StatusLabel

var inventory = null
var focused_destination_provider_id: StringName = &""
var _player_state_service = null


func _ready() -> void:
	inventory_panel.stack_selected.connect(Callable(self, "_on_stack_selected"))
	inventory_panel.container_selected.connect(Callable(self, "_on_container_selected"))
	inventory_panel.destination_focus_changed.connect(Callable(self, "_on_destination_focus_changed"))
	_connect_action_buttons()

	_player_state_service = PlayerStateRuntimeScript.get_or_create_service(self)
	if _player_state_service == null:
		inventory_panel.set_inventory(null)
		_set_status("No shared player state service is available.")
		return

	if not _player_state_service.player_state_changed.is_connected(Callable(self, "_on_player_state_changed")):
		_player_state_service.player_state_changed.connect(Callable(self, "_on_player_state_changed"))
	_apply_player_state(_player_state_service.get_player_state(), true)


func _exit_tree() -> void:
	# The debug shell caches this page and swaps it back into view later, so the shared
	# state connection should survive temporary tree exits.
	pass


func _on_player_state_changed(player_state) -> void:
	_apply_player_state(player_state, false)


func _apply_player_state(player_state, initial_bind: bool) -> void:
	if player_state == null or player_state.inventory_state == null:
		inventory = null
		inventory_panel.set_inventory(null)
		_set_status("Shared player state is live, but no inventory state is assigned.")
		return

	inventory = player_state.inventory_state
	inventory_panel.set_inventory(inventory)
	_apply_default_debug_selection()
	if initial_bind:
		_set_status("Inventory now reads PlayerState.inventory_state and sends actions through PlayerStateService.")
	else:
		_set_status("Inventory refreshed from the shared player backbone.")
	_print_inventory_summary()


func _apply_default_debug_selection() -> void:
	var default_provider_id = &"backpack_back"
	if inventory == null or inventory.get_storage_provider(default_provider_id) == null:
		var provider_ids = inventory.get_storage_provider_ids() if inventory != null else []
		default_provider_id = InventoryScript.CARRY_GROUND if provider_ids.is_empty() else StringName(provider_ids[0])
	inventory_panel.set_focused_destination_provider_id(default_provider_id)
	inventory_panel.set_selected_stack_index(0)


func _print_inventory_summary() -> void:
	print("--- Inventory MVP Debug Scene ---")
	print("Carried weight: %.2f kg / %.2f kg" % [inventory.get_total_weight_kg(), inventory.max_total_weight_kg])
	print("Travel speed modifier: %.2f" % inventory.get_travel_speed_modifier())
	print("Hand L: %.2f kg | Pockets: %.2f kg | Backpack: %.2f kg" % [
		inventory.get_zone_weight_kg(ItemDefinitionScript.CARRY_HANDS),
		inventory.get_zone_weight_kg(ItemDefinitionScript.CARRY_POCKET),
		inventory.get_zone_weight_kg(&"backpack_back")
	])
	var backpack_container = inventory.get_container_profile(&"backpack_back")
	if backpack_container != null:
		print("Backpack container: %s" % backpack_container.get_capacity_label())

	for stack in inventory.stacks:
		if stack == null or stack.is_empty():
			continue
		var line = "- %s x%d (%s, %.2f kg)" % [
			stack.item.display_name,
			stack.quantity,
			stack.carry_zone,
			stack.get_weight_kg()
		]
		print(line)


func _connect_action_buttons() -> void:
	$Root/DebugActions/ActionRoot/EquipButton.pressed.connect(Callable(self, "_on_equip_selected"))
	$Root/DebugActions/ActionRoot/MoveFocusedButton.pressed.connect(Callable(self, "_on_move_to_focused_storage"))
	$Root/DebugActions/ActionRoot/MoveGroundButton.pressed.connect(Callable(self, "_on_move_to_zone").bind(InventoryScript.CARRY_GROUND))
	$Root/DebugActions/ActionRoot/SplitButton.pressed.connect(Callable(self, "_on_split_stack"))
	$Root/DebugActions/ActionRoot/MergeButton.pressed.connect(Callable(self, "_on_merge_stack"))
	$Root/DebugActions/ActionRoot/RemoveOneButton.pressed.connect(Callable(self, "_on_remove_one"))
	$Root/DebugActions/ActionRoot/DeleteButton.pressed.connect(Callable(self, "_on_delete_stack"))
	$Root/DebugActions/ActionRoot/OpenContainerButton.pressed.connect(Callable(self, "_on_open_container"))


func _on_stack_selected(stack_index: int) -> void:
	var stack = inventory.get_stack_at(stack_index)
	if stack == null:
		_set_status("No stack selected.")
		return
	_set_status("Selected %s x%d in %s." % [stack.item.display_name, stack.quantity, stack.carry_zone])


func _on_container_selected(provider_id: StringName) -> void:
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		_set_status("No container selected.")
		return
	_set_status("Selected container %s in %s." % [provider.display_name, provider.equipment_slot_id])


func _on_destination_focus_changed(provider_id: StringName) -> void:
	focused_destination_provider_id = provider_id
	if provider_id == &"":
		return
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		return
	_set_status("Focused destination: %s." % provider.display_name)


func _on_move_to_zone(carry_zone: StringName) -> void:
	_apply_operation_result(_execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_MOVE_STACK,
		{
			"stack_index": inventory_panel.selected_stack_index,
			"target_provider_id": carry_zone
		}
	))


func _on_move_to_focused_storage() -> void:
	var target_provider_id = _get_focused_storage_provider_id()
	if target_provider_id == &"":
		_set_status("Select a storage slot or Ground / Nearby as the focused target.")
		return
	_apply_operation_result(_execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_MOVE_STACK,
		{
			"stack_index": inventory_panel.selected_stack_index,
			"target_provider_id": target_provider_id
		}
	))


func _on_equip_selected() -> void:
	if inventory_panel.selected_container_provider_id != &"":
		_equip_selected_container()
		return
	_equip_selected_stack()


func _on_split_stack() -> void:
	_apply_operation_result(_execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_SPLIT_STACK,
		{"stack_index": inventory_panel.selected_stack_index}
	))


func _on_merge_stack() -> void:
	_apply_operation_result(_execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_MERGE_STACK,
		{"stack_index": inventory_panel.selected_stack_index}
	))


func _on_remove_one() -> void:
	_apply_operation_result(_execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_REMOVE_ONE,
		{"stack_index": inventory_panel.selected_stack_index}
	))


func _on_delete_stack() -> void:
	_apply_operation_result(_execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_DELETE_STACK,
		{"stack_index": inventory_panel.selected_stack_index}
	))


func _equip_selected_container() -> void:
	var provider_id = inventory_panel.selected_container_provider_id
	var provider = inventory.get_storage_provider(provider_id)
	if provider == null:
		_set_status("No container selected.")
		return

	var valid_slots = _get_valid_slots_for_container(provider)
	var slot_result = _resolve_equip_slot(valid_slots, provider.equipment_slot_id, provider.display_name)
	if not slot_result.get("success", false):
		_set_status(String(slot_result.get("message", "Could not resolve an equipment slot.")))
		return

	var target_slot_id = StringName(slot_result.get("slot_id", &""))
	var result = _execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_EQUIP_CONTAINER,
		{
			"provider_id": provider_id,
			"target_slot_id": target_slot_id
		}
	)
	if result.get("success", false):
		inventory_panel.set_selected_container_provider_id(provider_id)
	_apply_container_operation_result(result)


func _equip_selected_stack() -> void:
	var stack_index = inventory_panel.selected_stack_index
	var stack = inventory.get_stack_at(stack_index)
	if stack == null:
		_set_status("Select an item or container to equip.")
		return

	var player_state = _player_state_service.get_player_state() if _player_state_service != null else null
	if player_state != null and stack.item != null and stack.item.can_equip() and player_state.has_method("equip_stack"):
		_apply_operation_result(_execute_debug_action(
			PlayerStateServiceScript.ACTION_INVENTORY_EQUIP_STACK,
			{"stack_index": stack_index}
		))
		return

	var valid_slots = _get_valid_slots_for_stack(stack)
	var slot_result = _resolve_equip_slot(valid_slots, stack.carry_zone, stack.item.display_name)
	if not slot_result.get("success", false):
		_set_status(String(slot_result.get("message", "Could not resolve an equipment slot.")))
		return

	var target_slot_id = StringName(slot_result.get("slot_id", &""))
	var result = _execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_MOVE_STACK,
		{
			"stack_index": stack_index,
			"target_provider_id": target_slot_id
		}
	)
	_apply_operation_result(result)


func _on_open_container() -> void:
	var provider_id = inventory_panel.selected_container_provider_id
	var result = _execute_debug_action(
		PlayerStateServiceScript.ACTION_INVENTORY_OPEN_CONTAINER,
		{"provider_id": provider_id}
	)
	_apply_container_operation_result(result)
	if result.get("success", false):
		inventory_panel.open_container(provider_id)


func _apply_operation_result(result: Dictionary) -> void:
	_set_status(String(result.get("message", "No result message.")))
	if result.get("success", false):
		inventory_panel.set_selected_stack_index(int(result.get("stack_index", -1)))


func _apply_container_operation_result(result: Dictionary) -> void:
	_set_status(String(result.get("message", "No result message.")))


func _execute_debug_action(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("execute_action"):
		return {
			"success": false,
			"message": "Shared player state action service is unavailable.",
			"action_id": action_id
		}
	var result = _player_state_service.execute_action(String(action_id), context)
	if result is Dictionary:
		return result
	return {
		"success": false,
		"message": "Action returned no result.",
		"action_id": action_id
	}


func _get_valid_slots_for_container(provider) -> Array:
	var item_definition = inventory.get_item_definition_for_provider(provider.provider_id) if inventory != null else null
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


func _get_focused_storage_provider_id() -> StringName:
	return focused_destination_provider_id


func _get_valid_slots_for_stack(stack) -> Array:
	return stack.item.get_valid_equip_slots()


func _resolve_equip_slot(valid_slots: Array, current_slot_id: StringName, item_name: String) -> Dictionary:
	if valid_slots.is_empty():
		return _slot_result(false, &"", "%s is not equipable in this debug rig." % item_name)

	var selected_slot_id: StringName = inventory_panel.selected_slot_id
	if valid_slots.has(selected_slot_id):
		if selected_slot_id == current_slot_id:
			return _slot_result(false, &"", "%s is already equipped in %s." % [item_name, _get_slot_label(selected_slot_id)])
		if _is_equipment_slot_open(selected_slot_id):
			return _slot_result(true, selected_slot_id, "")
		return _slot_result(false, &"", "%s is occupied." % _get_slot_label(selected_slot_id))

	var open_slots: Array = []
	for slot_id in valid_slots:
		var valid_slot_id = StringName(slot_id)
		if valid_slot_id == current_slot_id:
			continue
		if _is_equipment_slot_open(valid_slot_id):
			open_slots.append(valid_slot_id)

	if open_slots.size() == 1:
		return _slot_result(true, StringName(open_slots[0]), "")
	if open_slots.is_empty():
		if valid_slots.has(current_slot_id):
			return _slot_result(false, &"", "%s is already equipped." % item_name)
		return _slot_result(false, &"", "No valid open slot for %s." % item_name)

	return _slot_result(false, &"", "%s can equip to %s. Select one of those slots, then press Equip." % [item_name, _format_slot_list(open_slots)])


func _is_equipment_slot_open(slot_id: StringName) -> bool:
	return inventory.get_equipment_slot(slot_id).get("item_id", &"") == &""


func _slot_result(success: bool, slot_id: StringName, message: String) -> Dictionary:
	return {
		"success": success,
		"slot_id": slot_id,
		"message": message
	}


func _format_slot_list(slot_ids: Array) -> String:
	var label = ""
	for index in range(slot_ids.size()):
		if index > 0:
			label += " or "
		label += _get_slot_label(StringName(slot_ids[index]))
	return label


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
		_:
			return String(slot_id)


func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message
	print("Inventory debug action: %s" % message)
