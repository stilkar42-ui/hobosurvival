class_name InventoryManager
extends RefCounted

const ACTION_MOVE := &"inventory.move"
const ACTION_MOVE_STACK := &"inventory.move_stack"
const ACTION_DROP_STACK := &"inventory.drop_stack"
const ACTION_EQUIP_STACK := &"inventory.equip_stack"
const ACTION_EQUIP_CONTAINER := &"inventory.equip_container"
const ACTION_DROP_CONTAINER := &"inventory.drop_container"
const ACTION_OPEN_CONTAINER := &"inventory.open_container"
const ACTION_INSPECT_STACK := &"inventory.inspect_stack"
const ACTION_INSPECT_CONTAINER := &"inventory.inspect_container"
const ACTION_READ_STACK := &"inventory.read_stack"
const ACTION_SPLIT_STACK := &"inventory.split_stack"
const ACTION_MERGE_STACK := &"inventory.merge_stack"
const ACTION_REMOVE_ONE := &"inventory.remove_one"
const ACTION_DELETE_STACK := &"inventory.delete_stack"

var _player_state_service = null


func configure(player_state_service):
	_player_state_service = player_state_service
	return self


func get_inventory(player_state = null):
	var resolved_player_state = player_state if player_state != null else _get_player_state()
	if resolved_player_state == null:
		return null
	resolved_player_state.ensure_core_resources()
	return resolved_player_state.inventory_state


func get_stack_at(player_state, stack_index: int):
	var inventory = get_inventory(player_state)
	if inventory == null:
		return null
	return inventory.get_stack_at(stack_index)


func get_storage_provider(player_state, provider_id: StringName):
	var inventory = get_inventory(player_state)
	if inventory == null:
		return null
	return inventory.get_storage_provider(provider_id)


func get_storage_provider_ids(player_state) -> Array:
	var inventory = get_inventory(player_state)
	if inventory == null:
		return []
	return inventory.get_storage_provider_ids()


func get_container_profile(player_state, provider_id: StringName):
	var inventory = get_inventory(player_state)
	if inventory == null:
		return null
	return inventory.get_container_profile(provider_id)


func get_action_availability(action_id: StringName, stack_index: int = -1) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("get_loop_action_availability"):
		return {"enabled": false, "reason": "Inventory service is unavailable.", "action_id": action_id}
	return _player_state_service.get_loop_action_availability(action_id, stack_index)


func execute_action(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	if _player_state_service == null or not _player_state_service.has_method("execute_action"):
		return {
			"success": false,
			"message": "Inventory service is unavailable.",
			"action_id": action_id,
			"state_changed": false
		}
	return _player_state_service.execute_action(String(action_id), context)


func duplicate_inventory(player_state):
	var inventory = get_inventory(player_state)
	if inventory == null:
		return null
	return inventory.duplicate_inventory()


func simulate_stack_move(player_state, stack_index: int, target_provider_id: StringName) -> Dictionary:
	var inventory_copy = duplicate_inventory(player_state)
	if inventory_copy == null:
		return {"success": false, "message": "Inventory state is unavailable."}
	return inventory_copy.move_stack_to_zone(stack_index, target_provider_id)


func simulate_container_equip(player_state, provider_id: StringName, target_slot_id: StringName) -> Dictionary:
	var inventory_copy = duplicate_inventory(player_state)
	if inventory_copy == null:
		return {"success": false, "message": "Inventory state is unavailable."}
	return inventory_copy.equip_container_to_slot(provider_id, target_slot_id)


func _get_player_state():
	if _player_state_service == null or not _player_state_service.has_method("get_player_state"):
		return null
	return _player_state_service.get_player_state()
