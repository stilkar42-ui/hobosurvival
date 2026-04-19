class_name Inventory
extends Resource

const InventoryStackScript := preload("res://scripts/inventory/inventory_stack.gd")
const ContainerProfileScript := preload("res://scripts/inventory/container_profile.gd")
const StorageProviderDefinitionScript := preload("res://scripts/inventory/storage_provider_definition.gd")

const SLOT_BACK := &"slot_back"
const SLOT_SHOULDER_L := &"slot_shoulder_l"
const SLOT_SHOULDER_R := &"slot_shoulder_r"
const SLOT_BELT_WAIST := &"slot_belt_waist"
const SLOT_HAND_L := &"slot_hand_l"
const SLOT_HAND_R := &"slot_hand_r"
const SLOT_PANTS := &"slot_pants"
const SLOT_COAT := &"slot_coat"

const CARRY_HANDS := SLOT_HAND_L
const CARRY_HANDS_R := SLOT_HAND_R
const CARRY_GROUND := &"ground_nearby"
const CARRY_PACK := &"pack"
const CARRY_POCKET := &"pocket"
const SMALL_UNITS_PER_MEDIUM_SLOT := 4

signal inventory_changed
signal item_added(item, quantity: int, carry_zone: StringName)
signal item_removed(item, quantity: int, carry_zone: StringName)

@export_range(1.0, 80.0, 0.1, "suffix:kg") var max_total_weight_kg := 28.0
@export var stacks: Array = []
@export var storage_providers: Dictionary = {}
@export var provider_aliases: Dictionary = {}
@export var equipment_slots: Dictionary = {}
var item_catalog = null


func _init() -> void:
	reset_storage_providers_to_base()


func set_item_catalog(new_item_catalog) -> void:
	item_catalog = new_item_catalog


func reset_storage_providers_to_base() -> void:
	storage_providers.clear()
	provider_aliases.clear()
	equipment_slots.clear()

	for slot_id in get_equipment_slot_ids():
		equipment_slots[slot_id] = _create_empty_equipment_slot(slot_id)

	_add_storage_provider(_create_provider(
		CARRY_HANDS,
		"Hand Slot L",
		&"",
		SLOT_HAND_L,
		StorageProviderDefinitionScript.MountSlot.NONE,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.TRAVEL,
		0.0,
		0.0,
		_create_container_profile(CARRY_HANDS, "Left Hand", 1, 4, 0, 1.0, 8.0),
		PackedStringArray(["hands"])
	))
	_add_storage_provider(_create_provider(
		CARRY_HANDS_R,
		"Hand Slot R",
		&"",
		SLOT_HAND_R,
		StorageProviderDefinitionScript.MountSlot.HANDS_CARRY,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.TRAVEL,
		0.0,
		0.0,
		_create_container_profile(CARRY_HANDS_R, "Right Hand", 1, 4, 0, 1.0, 8.0),
		PackedStringArray(["hands"])
	))
	_add_storage_provider(_create_provider(
		CARRY_GROUND,
		"Ground / Nearby",
		&"",
		CARRY_GROUND,
		StorageProviderDefinitionScript.MountSlot.NONE,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.SLOW,
		0.0,
		0.0,
		_create_container_profile(CARRY_GROUND, "Ground / Nearby", 8, 32, 8, 1.0, 999.0),
		PackedStringArray(["pack", "pocket", "hands"])
	))
	provider_aliases[CARRY_HANDS] = CARRY_HANDS
	provider_aliases[&"hands"] = CARRY_HANDS
	provider_aliases[CARRY_HANDS_R] = CARRY_HANDS_R
	provider_aliases[CARRY_GROUND] = CARRY_GROUND
	provider_aliases[&"ground"] = CARRY_GROUND
	_rebuild_aliases()


func equip_storage_provider(provider) -> Dictionary:
	if provider == null or not provider.is_valid_definition():
		return _operation_result(false, "Invalid storage provider.", -1)
	if storage_providers.has(provider.provider_id):
		return _operation_result(false, "%s is already equipped." % provider.display_name, -1)
	if not equipment_slots.has(provider.equipment_slot_id):
		return _operation_result(false, "%s has no valid equipment slot." % provider.display_name, -1)
	if not _equipment_slot_can_receive_provider(provider, provider.equipment_slot_id):
		return _operation_result(false, "%s is already occupied." % _get_slot_display_name(provider.equipment_slot_id), -1)
	if not _mount_slots_available(provider):
		return _operation_result(false, "%s cannot be equipped; mount slots are occupied." % provider.display_name, -1)

	_add_storage_provider(provider)
	_set_equipment_provider(provider)
	inventory_changed.emit()
	return _operation_result(true, "Equipped %s." % provider.display_name, -1)


func unequip_storage_provider(provider_id: StringName) -> Dictionary:
	return unequip_container_to_ground(provider_id)


func unequip_container_to_ground(provider_id: StringName) -> Dictionary:
	var resolved_provider_id = _resolve_provider_id(provider_id)
	if resolved_provider_id == CARRY_HANDS or resolved_provider_id == CARRY_HANDS_R or resolved_provider_id == CARRY_GROUND:
		return _operation_result(false, "Base carry providers cannot be removed.", -1)
	var provider = storage_providers.get(resolved_provider_id)
	if provider == null:
		return _operation_result(false, "No provider found: %s." % provider_id, -1)
	if provider.source_item_id == &"":
		return _operation_result(false, "%s is not a container item." % provider.display_name, -1)
	if provider.equipment_slot_id == CARRY_GROUND:
		return _operation_result(false, "%s is already on the ground." % provider.display_name, -1)

	_clear_equipment_provider(resolved_provider_id)
	provider.equipment_slot_id = CARRY_GROUND
	_apply_slot_mount(provider, CARRY_GROUND)
	_set_equipment_provider(provider)
	_rebuild_aliases()
	inventory_changed.emit()
	return _operation_result(true, "Dropped %s." % provider.display_name, -1)


func equip_container_to_slot(provider_id: StringName, target_slot_id: StringName) -> Dictionary:
	var resolved_provider_id = _resolve_provider_id(provider_id)
	var provider = storage_providers.get(resolved_provider_id)
	if provider == null:
		return _operation_result(false, "No container selected.", -1)
	if provider.source_item_id == &"":
		return _operation_result(false, "%s is not an equippable container." % provider.display_name, -1)
	if not equipment_slots.has(target_slot_id) or target_slot_id == CARRY_GROUND:
		return _operation_result(false, "%s is not an equipment slot." % target_slot_id, -1)
	if not _container_can_use_slot(provider, target_slot_id):
		return _operation_result(false, "%s cannot equip to %s." % [provider.display_name, _get_slot_display_name(target_slot_id)], -1)
	if provider.equipment_slot_id == target_slot_id:
		return _operation_result(false, "%s is already equipped there." % provider.display_name, -1)
	if not _equipment_slot_can_receive_provider(provider, target_slot_id):
		return _operation_result(false, "%s is occupied." % _get_slot_display_name(target_slot_id), -1)
	if (target_slot_id == SLOT_HAND_L or target_slot_id == SLOT_HAND_R) and _provider_has_contents(target_slot_id):
		return _operation_result(false, "%s is holding something." % _get_slot_display_name(target_slot_id), -1)

	_clear_equipment_provider(resolved_provider_id)
	provider.equipment_slot_id = target_slot_id
	_apply_slot_mount(provider, target_slot_id)
	_set_equipment_provider(provider)
	_rebuild_aliases()
	inventory_changed.emit()
	return _operation_result(true, "Equipped %s to %s." % [provider.display_name, _get_slot_display_name(target_slot_id)], -1)


func open_container(provider_id: StringName) -> Dictionary:
	var resolved_provider_id = _resolve_provider_id(provider_id)
	var provider = storage_providers.get(resolved_provider_id)
	if provider == null:
		return _operation_result(false, "No container selected.", -1)
	if provider.source_item_id == &"":
		return _operation_result(false, "%s is not a container item." % provider.display_name, -1)
	var item_definition = get_item_definition(provider.source_item_id)
	if item_definition != null and not item_definition.can_open():
		return _operation_result(false, "%s cannot be opened." % provider.display_name, -1)
	return _operation_result(true, "Opened %s." % provider.display_name, -1)


func set_pack_container(container_id: StringName) -> Dictionary:
	if container_id == &"bindle":
		return equip_or_replace_provider(_create_bindle_provider())
	if container_id == &"backpack":
		return equip_or_replace_provider(_create_backpack_provider())
	return _operation_result(false, "Unknown storage container: %s." % container_id, -1)


func equip_or_replace_provider(provider) -> Dictionary:
	var old_provider_id = _find_provider_for_mount(provider.mount_slot)
	if provider.mount_slot == StorageProviderDefinitionScript.MountSlot.HANDS_CARRY:
		old_provider_id = _find_hand_carried_provider()
	if old_provider_id != &"" and not _provider_has_contents(old_provider_id):
		storage_providers.erase(old_provider_id)
		_clear_equipment_provider(old_provider_id)
		_rebuild_aliases()
	return equip_storage_provider(provider)


func add_item(item, quantity: int = 1, preferred_carry_zone: StringName = CARRY_GROUND) -> int:
	return add_item_with_quality(item, quantity, preferred_carry_zone)


func add_item_with_quality(item, quantity: int = 1, preferred_carry_zone: StringName = CARRY_GROUND, quality_tier: int = -1, quality_score: float = -1.0, durability_uses_remaining: int = -1) -> int:
	if item == null or quantity <= 0:
		return quantity
	var provider_id = _resolve_provider_id(preferred_carry_zone)
	if provider_id == &"":
		return quantity
	if not _provider_accepts_item(item, provider_id):
		return quantity

	var remaining = quantity
	remaining = _add_to_existing_stacks(item, remaining, provider_id, quality_tier)
	remaining = _add_to_new_stacks(item, remaining, provider_id, quality_tier, quality_score, durability_uses_remaining)

	var accepted = quantity - remaining
	if accepted > 0:
		item_added.emit(item, accepted, provider_id)
		inventory_changed.emit()
	return remaining


func remove_item(item_id: StringName, quantity: int = 1, carry_zone: StringName = &"") -> int:
	if quantity <= 0:
		return 0

	var provider_filter = _resolve_provider_id(carry_zone) if carry_zone != &"" else &""
	var remaining = quantity
	var removed = 0
	for index in range(stacks.size() - 1, -1, -1):
		var stack = stacks[index]
		if stack == null or stack.is_empty():
			stacks.remove_at(index)
			continue
		if stack.item.item_id != item_id:
			continue
		if provider_filter != &"" and stack.carry_zone != provider_filter:
			continue

		var removed_from_stack = stack.remove_quantity(remaining)
		removed += removed_from_stack
		remaining -= removed_from_stack
		item_removed.emit(stack.item, removed_from_stack, stack.carry_zone)

		if stack.is_empty():
			stacks.remove_at(index)
		if remaining <= 0:
			break

	if removed > 0:
		inventory_changed.emit()
	return removed


func move_stack_to_zone(stack_index: int, target_carry_zone: StringName) -> Dictionary:
	var stack = get_stack_at(stack_index)
	if stack == null:
		return _operation_result(false, "No stack selected.", stack_index)
	var provider_id = _resolve_provider_id(target_carry_zone)
	if provider_id == &"":
		return _operation_result(false, "No storage provider grants %s." % target_carry_zone, stack_index)
	if stack.carry_zone == provider_id:
		return _operation_result(false, "Stack is already in %s." % get_container_profile(provider_id).display_name, stack_index)
	if (provider_id == SLOT_HAND_L or provider_id == SLOT_HAND_R) and get_equipment_slot(provider_id).get("item_id", &"") != &"":
		return _operation_result(false, "%s is occupied." % _get_slot_display_name(provider_id), stack_index)
	if not _provider_accepts_item(stack.item, provider_id):
		return _operation_result(false, "%s cannot be placed in %s." % [stack.item.display_name, get_container_profile(provider_id).display_name], stack_index)
	if not _provider_can_accept_size(stack.item, stack.quantity, provider_id):
		return _operation_result(false, "%s lacks size capacity." % get_container_profile(provider_id).display_name, stack_index)
	if not _provider_can_accept_weight(stack.item, stack.quantity, provider_id):
		return _operation_result(false, "%s cannot carry that much weight." % get_container_profile(provider_id).display_name, stack_index)

	stack.carry_zone = provider_id
	inventory_changed.emit()
	if provider_id == CARRY_GROUND:
		return _operation_result(true, "Dropped %s." % stack.item.display_name, stack_index)
	return _operation_result(true, "Moved %s to %s." % [stack.item.display_name, get_container_profile(provider_id).display_name], stack_index)


func remove_quantity_from_stack(stack_index: int, quantity: int = 1) -> Dictionary:
	var stack = get_stack_at(stack_index)
	if stack == null:
		return _operation_result(false, "No stack selected.", stack_index)
	if quantity <= 0:
		return _operation_result(false, "Remove quantity must be positive.", stack_index)

	var removed = stack.remove_quantity(quantity)
	if removed <= 0:
		return _operation_result(false, "Nothing was removed.", stack_index)

	var item_name = stack.item.display_name
	var old_provider = stack.carry_zone
	if stack.is_empty():
		stacks.remove_at(stack_index)
		stack_index = -1
	item_removed.emit(stack.item, removed, old_provider)
	inventory_changed.emit()
	return _operation_result(true, "Removed %d from %s." % [removed, item_name], stack_index)


func split_stack(stack_index: int, split_quantity: int = -1) -> Dictionary:
	var stack = get_stack_at(stack_index)
	if stack == null:
		return _operation_result(false, "No stack selected.", stack_index)
	if stack.quantity <= 1:
		return _operation_result(false, "%s cannot be split." % stack.item.display_name, stack_index)

	var quantity_to_split = split_quantity
	if quantity_to_split <= 0:
		quantity_to_split = floori(float(stack.quantity) / 2.0)
	if quantity_to_split <= 0 or quantity_to_split >= stack.quantity:
		return _operation_result(false, "Split quantity must leave items in both stacks.", stack_index)

	stack.quantity -= quantity_to_split
	var new_stack = InventoryStackScript.new()
	new_stack.setup(stack.item, quantity_to_split, stack.carry_zone, stack.quality_tier, stack.quality_score, stack.durability_uses_remaining)
	stacks.insert(stack_index + 1, new_stack)
	inventory_changed.emit()
	return _operation_result(true, "Split %d from %s." % [quantity_to_split, stack.item.display_name], stack_index + 1)


func merge_stack(stack_index: int) -> Dictionary:
	var stack = get_stack_at(stack_index)
	if stack == null:
		return _operation_result(false, "No stack selected.", stack_index)

	var moved = 0
	for index in range(stacks.size()):
		if index == stack_index:
			continue
		var target_stack = stacks[index]
		if target_stack == null or not target_stack.can_stack_with(stack.item, stack.carry_zone, stack.quality_tier):
			continue
		var before = stack.quantity
		var remaining = target_stack.add_quantity(stack.quantity)
		moved += before - remaining
		stack.quantity = remaining
		if stack.quantity <= 0:
			var selected_after_merge = index
			if stack_index < index:
				selected_after_merge -= 1
			stacks.remove_at(stack_index)
			inventory_changed.emit()
			return _operation_result(true, "Merged %d into another %s stack." % [moved, target_stack.item.display_name], selected_after_merge)

	if moved <= 0:
		return _operation_result(false, "No valid stack could merge with %s." % stack.item.display_name, stack_index)

	inventory_changed.emit()
	return _operation_result(true, "Merged %d items. Some remain selected." % moved, stack_index)


func delete_stack(stack_index: int) -> Dictionary:
	var stack = get_stack_at(stack_index)
	if stack == null:
		return _operation_result(false, "No stack selected.", stack_index)

	var item_name = stack.item.display_name
	var quantity = stack.quantity
	stacks.remove_at(stack_index)
	inventory_changed.emit()
	return _operation_result(true, "Deleted %s x%d." % [item_name, quantity], -1)


func move(request: Dictionary) -> Dictionary:
	var normalized_request = request.duplicate(true)
	normalized_request["dry_run"] = bool(normalized_request.get("dry_run", false))
	var dragged_ref = _normalize_dragged_ref(normalized_request)
	if dragged_ref.is_empty():
		return _move_result(false, &"invalid_drag_ref", "No inventory item was selected to move.", normalized_request, &"", &"", false, -1)

	match String(dragged_ref.get("type", "")):
		"stack":
			var target_provider_id = _resolve_provider_id(StringName(normalized_request.get("target_provider_id", &"")))
			if target_provider_id == &"":
				return _move_result(false, &"invalid_target_provider", "No visible place was found for that drop.", normalized_request, _get_drag_source_provider_id(dragged_ref), &"", false, _get_drag_stack_index(dragged_ref))
			return _move_stack_drag_ref(dragged_ref, target_provider_id, normalized_request)
		"provider":
			var target_slot_id = _resolve_provider_move_target_id(StringName(normalized_request.get("target_provider_id", &"")))
			if target_slot_id == &"":
				return _move_result(false, &"invalid_target_provider", "No visible place was found for that drop.", normalized_request, _get_drag_source_provider_id(dragged_ref), &"", false, -1)
			return _move_provider_drag_ref(dragged_ref, target_slot_id, normalized_request)
		_:
			return _move_result(false, &"invalid_drag_ref", "That inventory object cannot be moved yet.", normalized_request, &"", &"", false, -1)


func preview_move(request: Dictionary) -> Dictionary:
	var preview_request = request.duplicate(true)
	preview_request["dry_run"] = true
	return move(preview_request)


func get_visible_provider_states() -> Array:
	var provider_states: Array = []
	for provider_id in get_storage_provider_ids():
		provider_states.append(get_provider_state(provider_id))
	return provider_states


func get_provider_state(provider_id: StringName) -> Dictionary:
	var resolved_provider_id = _resolve_provider_id(provider_id)
	var provider = storage_providers.get(resolved_provider_id)
	if provider == null:
		return {}
	var container = get_container_profile(resolved_provider_id)
	return {
		"provider_id": resolved_provider_id,
		"display_name": provider.display_name,
		"visible": true,
		"reachable": true,
		"source_item_id": provider.source_item_id,
		"equipment_slot_id": provider.equipment_slot_id,
		"access_speed": provider.access_speed,
		"capacity": {
			"medium_slots": container.medium_slots if container != null else 0,
			"small_capacity": container.small_capacity if container != null else 0,
			"overflow_small_capacity": container.overflow_small_capacity if container != null else 0,
			"max_weight_kg": container.max_weight_kg if container != null else 0.0
		},
		"usage": {
			"medium_units": get_provider_medium_units(resolved_provider_id),
			"small_units": get_provider_small_units(resolved_provider_id),
			"free_medium_units": get_provider_free_medium_units(resolved_provider_id),
			"free_small_units": get_provider_free_small_units(resolved_provider_id),
			"weight_kg": get_provider_weight_kg(resolved_provider_id)
		},
		"contents": _get_provider_content_tokens(resolved_provider_id),
		"warning_state": &""
	}


func get_stack_at(stack_index: int):
	if stack_index < 0 or stack_index >= stacks.size():
		return null
	var stack = stacks[stack_index]
	if stack == null or stack.is_empty():
		return null
	return stack


func get_storage_provider_ids() -> Array:
	var ordered_provider_ids: Array = []
	for provider_id in [CARRY_HANDS, CARRY_HANDS_R]:
		if storage_providers.has(provider_id):
			ordered_provider_ids.append(provider_id)
	for provider_id in storage_providers.keys():
		if not ordered_provider_ids.has(provider_id):
			if provider_id == CARRY_GROUND:
				continue
			ordered_provider_ids.append(provider_id)
	if storage_providers.has(CARRY_GROUND):
		ordered_provider_ids.append(CARRY_GROUND)
	return ordered_provider_ids


func get_storage_provider(provider_id: StringName):
	return storage_providers.get(_resolve_provider_id(provider_id))


func get_item_definition(item_id: StringName):
	if item_catalog == null or item_id == &"":
		return null
	return item_catalog.get_item(item_id)


func get_item_definition_for_provider(provider_id: StringName):
	var provider = get_storage_provider(provider_id)
	if provider == null or provider.source_item_id == &"":
		return null
	return get_item_definition(provider.source_item_id)


func get_equipment_slot_ids() -> Array:
	return [
		SLOT_BACK,
		SLOT_SHOULDER_L,
		SLOT_SHOULDER_R,
		SLOT_BELT_WAIST,
		SLOT_HAND_L,
		SLOT_HAND_R,
		SLOT_PANTS,
		SLOT_COAT,
		CARRY_GROUND
	]


func get_equipment_slot(slot_id: StringName) -> Dictionary:
	var slot_state = equipment_slots.get(slot_id, _create_empty_equipment_slot(slot_id)).duplicate()
	if (slot_id == SLOT_HAND_L or slot_id == SLOT_HAND_R) and slot_state.get("item_id", &"") == &"":
		var hand_state = _get_hand_stack_slot_state(slot_id)
		if not hand_state.is_empty():
			slot_state["item_id"] = hand_state["item_id"]
			slot_state["item_name"] = hand_state["item_name"]
			slot_state["occupant_kind"] = &"stack"
	return slot_state


func get_slot_storage_provider_ids(slot_id: StringName) -> Array:
	var provider_ids: Array = []
	var slot_state = get_equipment_slot(slot_id)
	for provider_id in get_storage_provider_ids():
		var provider = storage_providers.get(provider_id)
		if provider != null and provider.equipment_slot_id == slot_id:
			if (slot_id == SLOT_HAND_L or slot_id == SLOT_HAND_R) and slot_state.get("item_id", &"") != &"" and provider.source_item_id == &"":
				if slot_state.get("occupant_kind", &"") == &"container":
					continue
			provider_ids.append(provider_id)
	return provider_ids


func get_provider_weight_kg(provider_id: StringName) -> float:
	var resolved_id = _resolve_provider_id(provider_id)
	var total = 0.0
	for stack in stacks:
		if stack != null and not stack.is_empty() and stack.carry_zone == resolved_id:
			total += stack.get_weight_kg()
	return total


func get_provider_medium_units(provider_id: StringName) -> int:
	var resolved_id = _resolve_provider_id(provider_id)
	var total = 0
	for stack in stacks:
		if stack != null and not stack.is_empty() and stack.carry_zone == resolved_id:
			total += stack.item.get_medium_slots_per_unit() * stack.quantity
	return total


func get_provider_small_units(provider_id: StringName) -> int:
	var resolved_id = _resolve_provider_id(provider_id)
	var total = 0
	for stack in stacks:
		if stack != null and not stack.is_empty() and stack.carry_zone == resolved_id:
			total += stack.item.get_small_units_per_unit() * stack.quantity
	return total


func get_provider_free_medium_units(provider_id: StringName) -> int:
	var container = get_container_profile(provider_id)
	if container == null:
		return 0
	return max(container.medium_slots - get_provider_medium_units(provider_id), 0)


func get_provider_free_small_units(provider_id: StringName) -> int:
	var resolved_id = _resolve_provider_id(provider_id)
	var container = get_container_profile(resolved_id)
	if container == null:
		return 0
	return max(_get_total_small_equivalent_capacity(resolved_id) - _get_used_small_equivalent_units(resolved_id), 0)


func get_container_profile(provider_id: StringName):
	var provider = storage_providers.get(_resolve_provider_id(provider_id))
	if provider == null:
		return null
	return provider.container_profile


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	return count_item(item_id) >= quantity


func count_item(item_id: StringName) -> int:
	var total = 0
	for stack in stacks:
		if stack != null and not stack.is_empty() and stack.item.item_id == item_id:
			total += stack.quantity
	return total


func get_total_weight_kg() -> float:
	var total = 0.0
	for stack in stacks:
		if stack != null and not _provider_is_grounded(stack.carry_zone):
			total += stack.get_weight_kg()
	return total


func get_zone_weight_kg(carry_zone: StringName) -> float:
	return get_provider_weight_kg(carry_zone)


func get_used_slots(carry_zone: StringName) -> int:
	return get_provider_medium_units(carry_zone)


func get_free_slots(carry_zone: StringName) -> int:
	return get_provider_free_medium_units(carry_zone)


func get_used_medium_units(carry_zone: StringName) -> int:
	return get_provider_medium_units(carry_zone)


func get_free_medium_units(carry_zone: StringName) -> int:
	return get_provider_free_medium_units(carry_zone)


func get_used_small_units(carry_zone: StringName) -> int:
	return get_provider_small_units(carry_zone)


func get_free_small_units(carry_zone: StringName) -> int:
	return get_provider_free_small_units(carry_zone)


func can_accept(item, quantity: int = 1, carry_zone: StringName = CARRY_GROUND) -> bool:
	return get_rejected_quantity(item, quantity, carry_zone) == 0


func get_rejected_quantity(item, quantity: int = 1, carry_zone: StringName = CARRY_GROUND) -> int:
	var test_inventory = duplicate_inventory()
	return test_inventory.add_item(item, quantity, carry_zone)


func get_fatigue_load_factor() -> float:
	return clampf((get_total_weight_kg() + get_fatigue_burden_modifier()) / max_total_weight_kg, 0.0, 1.5)


func get_travel_speed_modifier() -> float:
	var load_factor = get_fatigue_load_factor()
	if load_factor <= 0.75:
		return 1.0
	if load_factor <= 1.0:
		return 0.85
	return 0.65


func get_fatigue_burden_modifier() -> float:
	var total = 0.0
	for provider in storage_providers.values():
		if provider.equipment_slot_id == CARRY_GROUND:
			continue
		total += provider.fatigue_modifier
	return total


func get_awkward_carry_modifier() -> float:
	var total = 0.0
	for provider in storage_providers.values():
		if provider.equipment_slot_id == CARRY_GROUND:
			continue
		total += provider.awkward_carry_modifier
	return total


func get_visible_trade_goods() -> Array:
	var visible: Array = []
	for stack in stacks:
		if stack != null and not stack.is_empty() and stack.item.visible_to_others and stack.item.trade_value_cents > 0:
			visible.append(stack)
	return visible


func duplicate_inventory() -> Resource:
	var inventory = Inventory.new()
	inventory.max_total_weight_kg = max_total_weight_kg
	inventory.set_item_catalog(item_catalog)
	inventory.storage_providers.clear()
	for provider_id in storage_providers.keys():
		var provider_copy = storage_providers[provider_id].duplicate()
		if storage_providers[provider_id].container_profile != null:
			provider_copy.container_profile = storage_providers[provider_id].container_profile.duplicate()
		inventory.storage_providers[provider_id] = provider_copy
	inventory.equipment_slots.clear()
	for slot_id in equipment_slots.keys():
		inventory.equipment_slots[slot_id] = equipment_slots[slot_id].duplicate(true)
	inventory._rebuild_aliases()
	for stack in stacks:
		if stack != null and not stack.is_empty():
			inventory.stacks.append(stack.duplicate_stack())
	return inventory


func to_save_data() -> Dictionary:
	var saved_providers: Array = []
	for provider_id in get_storage_provider_ids():
		if _is_base_provider(provider_id):
			continue
		var provider = storage_providers.get(provider_id)
		if provider == null:
			continue
		saved_providers.append(_serialize_storage_provider(provider))

	var saved_stacks: Array = []
	for stack in stacks:
		if stack != null and not stack.is_empty():
			saved_stacks.append(stack.to_save_data())
	return {
		"max_total_weight_kg": max_total_weight_kg,
		"storage_providers": saved_providers,
		"stacks": saved_stacks
	}


func from_save_data(data: Dictionary, item_catalog) -> bool:
	set_item_catalog(item_catalog)
	reset_storage_providers_to_base()
	stacks.clear()
	max_total_weight_kg = float(data.get("max_total_weight_kg", max_total_weight_kg))

	for provider_data in data.get("storage_providers", []):
		if not _restore_storage_provider_from_save(provider_data):
			return false

	for stack_data in data.get("stacks", []):
		var stack = InventoryStackScript.new()
		if not stack.from_save_data(stack_data, item_catalog):
			return false
		if add_item_with_quality(stack.item, stack.quantity, stack.carry_zone, stack.quality_tier, stack.quality_score, stack.durability_uses_remaining) > 0:
			return false
	return true


func _add_to_existing_stacks(item, quantity: int, provider_id: StringName, quality_tier: int = -1) -> int:
	var remaining = quantity
	var resolved_quality_tier = quality_tier if quality_tier >= 0 else int(item.quality_tier)
	for stack in stacks:
		if remaining <= 0:
			break
		if stack == null or not stack.can_stack_with(item, provider_id, resolved_quality_tier):
			continue
		var addable_by_size = _get_quantity_allowed_by_size(item, remaining, provider_id)
		if addable_by_size <= 0:
			break
		var addable_by_weight = _get_quantity_allowed_by_weight(item, remaining, provider_id)
		if addable_by_weight <= 0:
			break
		remaining = stack.add_quantity(min(remaining, min(addable_by_weight, addable_by_size)))
	return remaining


func _add_to_new_stacks(item, quantity: int, provider_id: StringName, quality_tier: int = -1, quality_score: float = -1.0, durability_uses_remaining: int = -1) -> int:
	var remaining = quantity
	while remaining > 0:
		if not _provider_can_accept_size(item, 1, provider_id):
			break
		var addable_by_weight = _get_quantity_allowed_by_weight(item, remaining, provider_id)
		if addable_by_weight <= 0:
			break
		var addable_by_size = _get_quantity_allowed_by_size(item, remaining, provider_id)
		if addable_by_size <= 0:
			break
		var stack_quantity = min(remaining, min(item.max_stack, min(addable_by_weight, addable_by_size)))
		var stack = InventoryStackScript.new()
		stack.setup(item, stack_quantity, provider_id, quality_tier, quality_score, durability_uses_remaining)
		stacks.append(stack)
		remaining -= stack_quantity
	return remaining


func _get_quantity_allowed_by_weight(item, requested_quantity: int, provider_id: StringName) -> int:
	if requested_quantity <= 0:
		return 0
	var container = get_container_profile(provider_id)
	if container == null:
		return 0
	var provider_remaining_kg = container.max_weight_kg - get_provider_weight_kg(provider_id)
	var total_remaining_kg = max_total_weight_kg - get_total_weight_kg()
	var remaining_kg = min(provider_remaining_kg, total_remaining_kg)
	return clampi(floori(remaining_kg / item.unit_weight_kg), 0, requested_quantity)


func _get_quantity_allowed_by_size(item, requested_quantity: int, provider_id: StringName) -> int:
	if requested_quantity <= 0:
		return 0
	if item.get_medium_slots_per_unit() > 0:
		var allowed_by_medium = floori(float(get_provider_free_medium_units(provider_id)) / float(item.get_medium_slots_per_unit()))
		var allowed_by_small_equivalent = floori(float(get_provider_free_small_units(provider_id)) / float(item.get_medium_slots_per_unit() * SMALL_UNITS_PER_MEDIUM_SLOT))
		return clampi(min(allowed_by_medium, allowed_by_small_equivalent), 0, requested_quantity)
	if item.get_small_units_per_unit() > 0:
		return clampi(floori(float(get_provider_free_small_units(provider_id)) / float(item.get_small_units_per_unit())), 0, requested_quantity)
	return requested_quantity


func _provider_can_accept_size(item, quantity: int, provider_id: StringName) -> bool:
	if item.get_medium_slots_per_unit() > 0:
		var medium_units = item.get_medium_slots_per_unit() * quantity
		var small_equivalent_units = medium_units * SMALL_UNITS_PER_MEDIUM_SLOT
		return medium_units <= get_provider_free_medium_units(provider_id) and small_equivalent_units <= get_provider_free_small_units(provider_id)
	if item.get_small_units_per_unit() > 0:
		return item.get_small_units_per_unit() * quantity <= get_provider_free_small_units(provider_id)
	return true


func _provider_can_accept_weight(item, quantity: int, provider_id: StringName) -> bool:
	var container = get_container_profile(provider_id)
	if container == null:
		return false
	var provider_remaining_kg = container.max_weight_kg - get_provider_weight_kg(provider_id)
	var total_remaining_kg = max_total_weight_kg - get_total_weight_kg()
	return item.get_stack_weight_kg(quantity) <= min(provider_remaining_kg, total_remaining_kg)


func _operation_result(success: bool, message: String, stack_index: int = -1) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"stack_index": stack_index
	}


func _move_stack_drag_ref(dragged_ref: Dictionary, target_provider_id: StringName, request: Dictionary) -> Dictionary:
	var stack_index = int(dragged_ref.get("stack_index", -1))
	var stack = get_stack_at(stack_index)
	var source_provider_id = _get_drag_source_provider_id(dragged_ref)
	if stack == null:
		return _move_result(false, &"invalid_drag_ref", "No inventory item was selected to move.", request, source_provider_id, target_provider_id, false, stack_index)
	if source_provider_id == &"":
		source_provider_id = StringName(stack.carry_zone)
	if source_provider_id == target_provider_id:
		return _move_result(false, &"same_provider", "%s is already there." % stack.item.display_name, request, source_provider_id, target_provider_id, false, stack_index)
	if (target_provider_id == SLOT_HAND_L or target_provider_id == SLOT_HAND_R) and get_equipment_slot(target_provider_id).get("item_id", &"") != &"":
		return _move_result(false, &"target_occupied", "%s is full." % _get_slot_display_name(target_provider_id), request, source_provider_id, target_provider_id, false, stack_index)
	if not _provider_accepts_item(stack.item, target_provider_id):
		return _move_result(false, &"target_rejects_item", "%s cannot be placed in %s." % [stack.item.display_name, get_container_profile(target_provider_id).display_name], request, source_provider_id, target_provider_id, false, stack_index)
	if not _provider_can_accept_size(stack.item, stack.quantity, target_provider_id):
		return _move_result(false, &"insufficient_size_capacity", "%s lacks size capacity." % get_container_profile(target_provider_id).display_name, request, source_provider_id, target_provider_id, false, stack_index)
	if not _provider_can_accept_weight(stack.item, stack.quantity, target_provider_id):
		return _move_result(false, &"insufficient_weight_capacity", "%s cannot carry that much weight." % get_container_profile(target_provider_id).display_name, request, source_provider_id, target_provider_id, false, stack_index)

	if bool(request.get("dry_run", false)):
		return _move_result(true, &"move_committed", "Move %s to %s." % [stack.item.display_name, get_container_profile(target_provider_id).display_name], request, source_provider_id, target_provider_id, false, stack_index)

	stack.carry_zone = target_provider_id
	inventory_changed.emit()
	var message = "Dropped %s." % stack.item.display_name if target_provider_id == CARRY_GROUND else "Moved %s to %s." % [stack.item.display_name, get_container_profile(target_provider_id).display_name]
	return _move_result(true, &"move_committed", message, request, source_provider_id, target_provider_id, true, stack_index)


func _move_provider_drag_ref(dragged_ref: Dictionary, target_slot_id: StringName, request: Dictionary) -> Dictionary:
	var provider_id = _resolve_provider_id(StringName(dragged_ref.get("provider_id", &"")))
	var provider = storage_providers.get(provider_id)
	if provider == null or _is_base_provider(provider_id):
		return _move_result(false, &"invalid_drag_ref", "No movable container was selected.", request, &"", target_slot_id, false, -1)
	var source_slot_id = StringName(provider.equipment_slot_id)
	if source_slot_id == target_slot_id:
		return _move_result(false, &"same_provider", "%s is already there." % provider.display_name, request, source_slot_id, target_slot_id, false, -1)
	if provider.source_item_id == &"":
		return _move_result(false, &"target_rejects_provider", "%s cannot be moved that way." % provider.display_name, request, source_slot_id, target_slot_id, false, -1)
	if target_slot_id != CARRY_GROUND and not _container_can_use_slot(provider, target_slot_id):
		return _move_result(false, &"target_rejects_provider", "%s cannot go there." % provider.display_name, request, source_slot_id, target_slot_id, false, -1)
	if target_slot_id != CARRY_GROUND and not _equipment_slot_can_receive_provider(provider, target_slot_id):
		return _move_result(false, &"target_occupied", "%s is full." % _get_slot_display_name(target_slot_id), request, source_slot_id, target_slot_id, false, -1)
	if (target_slot_id == SLOT_HAND_L or target_slot_id == SLOT_HAND_R) and _provider_has_contents(target_slot_id):
		return _move_result(false, &"target_occupied", "%s is holding something." % _get_slot_display_name(target_slot_id), request, source_slot_id, target_slot_id, false, -1)

	if bool(request.get("dry_run", false)):
		return _move_result(true, &"move_committed", "Move %s to %s." % [provider.display_name, _get_slot_display_name(target_slot_id)], request, source_slot_id, target_slot_id, false, -1)

	_clear_equipment_provider(provider_id)
	provider.equipment_slot_id = target_slot_id
	_apply_slot_mount(provider, target_slot_id)
	_set_equipment_provider(provider)
	_rebuild_aliases()
	inventory_changed.emit()
	var message = "Dropped %s." % provider.display_name if target_slot_id == CARRY_GROUND else "Moved %s to %s." % [provider.display_name, _get_slot_display_name(target_slot_id)]
	return _move_result(true, &"move_committed", message, request, source_slot_id, target_slot_id, true, -1)


func _normalize_dragged_ref(request: Dictionary) -> Dictionary:
	var dragged_ref = request.get("dragged_ref", {})
	if dragged_ref is Dictionary:
		if String(dragged_ref.get("type", "")) == "stack" and int(dragged_ref.get("stack_index", -1)) >= 0:
			return dragged_ref.duplicate(true)
		return dragged_ref.duplicate(true)
	if request.has("stack_index"):
		return {
			"type": "stack",
			"stack_index": int(request.get("stack_index", -1))
		}
	return {}


func _get_drag_source_provider_id(dragged_ref: Dictionary) -> StringName:
	var explicit_source = StringName(dragged_ref.get("source_provider_id", &""))
	if explicit_source != &"":
		return _resolve_provider_id(explicit_source)
	if String(dragged_ref.get("type", "")) == "stack":
		var stack = get_stack_at(int(dragged_ref.get("stack_index", -1)))
		if stack != null:
			return StringName(stack.carry_zone)
	if String(dragged_ref.get("type", "")) == "provider":
		var provider = get_storage_provider(StringName(dragged_ref.get("provider_id", &"")))
		if provider != null:
			return StringName(provider.equipment_slot_id)
	return &""


func _get_drag_stack_index(dragged_ref: Dictionary) -> int:
	if String(dragged_ref.get("type", "")) == "stack":
		return int(dragged_ref.get("stack_index", -1))
	return -1


func _resolve_provider_move_target_id(target_id: StringName) -> StringName:
	if target_id == &"":
		return &""
	if target_id == &"ground":
		return CARRY_GROUND
	if equipment_slots.has(target_id):
		return target_id
	var provider = get_storage_provider(target_id)
	if provider != null:
		return StringName(provider.equipment_slot_id)
	return &""


func _move_result(success: bool, reason_code: StringName, message: String, request: Dictionary, source_provider_id: StringName, target_provider_id: StringName, changed: bool, stack_index: int = -1) -> Dictionary:
	return {
		"success": success,
		"reason_code": reason_code,
		"message": message,
		"dragged_ref": request.get("dragged_ref", {}),
		"source_provider_id": source_provider_id,
		"target_provider_id": target_provider_id,
		"changed": changed,
		"stack_index": stack_index
	}


func _get_provider_content_tokens(provider_id: StringName) -> Array:
	var tokens: Array = []
	for stack_index in range(stacks.size()):
		var stack = stacks[stack_index]
		if stack == null or stack.is_empty() or stack.carry_zone != provider_id:
			continue
		tokens.append({
			"dragged_ref": {
				"type": "stack",
				"stack_index": stack_index
			},
			"item_id": stack.item.item_id,
			"display_name": stack.item.display_name,
			"quantity": stack.quantity,
			"weight_kg": stack.get_weight_kg(),
			"size_class": stack.item.get_size_class_name()
		})
	return tokens


func _add_storage_provider(provider) -> void:
	storage_providers[provider.provider_id] = provider
	_rebuild_aliases()


func _create_empty_equipment_slot(slot_id: StringName) -> Dictionary:
	return {
		"slot_id": slot_id,
		"display_name": _get_slot_display_name(slot_id),
		"item_id": &"",
		"item_name": "",
		"occupant_kind": &"",
		"occupant_provider_id": &"",
		"provider_ids": []
	}


func _set_equipment_provider(provider) -> void:
	if not equipment_slots.has(provider.equipment_slot_id):
		equipment_slots[provider.equipment_slot_id] = _create_empty_equipment_slot(provider.equipment_slot_id)
	var slot_state = equipment_slots[provider.equipment_slot_id]
	if provider.source_item_id != &"":
		slot_state["item_id"] = provider.source_item_id
		slot_state["item_name"] = provider.display_name
		slot_state["occupant_kind"] = &"container"
		slot_state["occupant_provider_id"] = provider.provider_id
	var provider_ids = slot_state.get("provider_ids", [])
	if not provider_ids.has(provider.provider_id):
		provider_ids.append(provider.provider_id)
	slot_state["provider_ids"] = provider_ids
	equipment_slots[provider.equipment_slot_id] = slot_state


func _clear_equipment_provider(provider_id: StringName) -> void:
	for slot_id in equipment_slots.keys():
		var slot_state = equipment_slots[slot_id]
		var provider_ids = slot_state.get("provider_ids", [])
		if provider_ids.has(provider_id):
			var clears_displayed_item = slot_state.get("occupant_provider_id", &"") == provider_id
			provider_ids.erase(provider_id)
			slot_state["provider_ids"] = provider_ids
			if provider_ids.is_empty() or clears_displayed_item:
				slot_state["item_id"] = &""
				slot_state["item_name"] = ""
				slot_state["occupant_kind"] = &""
				slot_state["occupant_provider_id"] = &""
			equipment_slots[slot_id] = slot_state


func _get_hand_stack_slot_state(slot_id: StringName) -> Dictionary:
	var held_stack_count = 0
	var held_unit_count = 0
	var first_item_id: StringName = &""
	var first_item_name = ""
	for stack in stacks:
		if stack == null or stack.is_empty() or stack.carry_zone != slot_id:
			continue
		held_stack_count += 1
		held_unit_count += stack.quantity
		if first_item_id == &"":
			first_item_id = stack.item.item_id
			first_item_name = stack.item.display_name

	if held_stack_count <= 0:
		return {}
	if held_stack_count == 1:
		if held_unit_count > 1:
			first_item_name = "%s x%d" % [first_item_name, held_unit_count]
		return {
			"item_id": first_item_id,
			"item_name": first_item_name
		}
	return {
		"item_id": &"held_items",
		"item_name": "%d held items" % held_stack_count
	}


func _equipment_slot_can_receive_provider(provider, slot_id: StringName) -> bool:
	if slot_id == CARRY_GROUND:
		return true
	var slot_state = equipment_slots.get(slot_id, {})
	var provider_ids = slot_state.get("provider_ids", [])
	if provider_ids.has(provider.provider_id):
		return true
	return slot_state.get("item_id", &"") == &""


func _container_can_use_slot(provider, slot_id: StringName) -> bool:
	var item_definition = get_item_definition(provider.source_item_id)
	if item_definition != null:
		return item_definition.can_equip_to_slot(slot_id)
	if provider.source_item_id == &"backpack":
		return slot_id == SLOT_BACK
	if provider.source_item_id == &"satchel":
		return slot_id == SLOT_SHOULDER_L or slot_id == SLOT_SHOULDER_R
	if provider.source_item_id == &"haversack":
		return slot_id == SLOT_SHOULDER_L or slot_id == SLOT_SHOULDER_R
	if provider.source_item_id == &"bindle":
		return slot_id == SLOT_HAND_L or slot_id == SLOT_HAND_R
	if provider.source_item_id == &"pants":
		return slot_id == SLOT_PANTS
	if provider.source_item_id == &"wool_coat":
		return slot_id == SLOT_COAT
	if provider.source_item_id == &"belt":
		return slot_id == SLOT_BELT_WAIST
	return false


func _apply_slot_mount(provider, slot_id: StringName) -> void:
	match slot_id:
		SLOT_BACK:
			provider.mount_slot = StorageProviderDefinitionScript.MountSlot.BACK
		SLOT_SHOULDER_L:
			provider.mount_slot = StorageProviderDefinitionScript.MountSlot.LEFT_SHOULDER
		SLOT_SHOULDER_R:
			provider.mount_slot = StorageProviderDefinitionScript.MountSlot.RIGHT_SHOULDER
		SLOT_HAND_L:
			provider.mount_slot = StorageProviderDefinitionScript.MountSlot.HANDS_CARRY
		SLOT_HAND_R:
			provider.mount_slot = StorageProviderDefinitionScript.MountSlot.HANDS_CARRY
		_:
			provider.mount_slot = StorageProviderDefinitionScript.MountSlot.NONE


func _get_slot_display_name(slot_id: StringName) -> String:
	match slot_id:
		SLOT_BACK:
			return "Back Slot"
		SLOT_SHOULDER_L:
			return "Shoulder Slot L"
		SLOT_SHOULDER_R:
			return "Shoulder Slot R"
		SLOT_BELT_WAIST:
			return "Belt/Waist Slots"
		SLOT_HAND_L:
			return "Hand Slot L"
		SLOT_HAND_R:
			return "Hand Slot R"
		SLOT_PANTS:
			return "Pants Slot"
		SLOT_COAT:
			return "Coat Slot"
		CARRY_GROUND:
			return "Ground Area"
		_:
			return String(slot_id)


func _rebuild_aliases() -> void:
	provider_aliases.clear()
	for provider_id in storage_providers.keys():
		var provider = storage_providers[provider_id]
		provider_aliases[provider_id] = provider_id
		if provider.allowed_item_zones.has("hands") and provider.provider_id == CARRY_HANDS:
			provider_aliases[&"hands"] = provider_id
	provider_aliases[CARRY_GROUND] = CARRY_GROUND
	provider_aliases[&"ground"] = CARRY_GROUND
	_assign_first_existing_alias(CARRY_POCKET, [&"pants_pockets", &"coat_pockets"])
	_assign_first_existing_alias(CARRY_PACK, [&"backpack_back", &"satchel_shoulder", &"haversack_shoulder", &"bindle_hand_carry"])


func _resolve_provider_id(provider_id_or_alias: StringName) -> StringName:
	if provider_id_or_alias == &"":
		return &""
	if storage_providers.has(provider_id_or_alias):
		return provider_id_or_alias
	return provider_aliases.get(provider_id_or_alias, &"")


func _assign_storage_alias(alias: StringName, allowed_zones: Array, ignored_provider_ids: Array) -> void:
	for provider_id in storage_providers.keys():
		if ignored_provider_ids.has(provider_id):
			continue
		var provider = storage_providers[provider_id]
		for zone_name in allowed_zones:
			if provider.allowed_item_zones.has(zone_name):
				provider_aliases[alias] = provider_id
				return


func _assign_first_existing_alias(alias: StringName, provider_ids: Array) -> void:
	for provider_id in provider_ids:
		if storage_providers.has(provider_id):
			provider_aliases[alias] = provider_id
			return


func _provider_accepts_item(item, provider_id: StringName) -> bool:
	var provider = storage_providers.get(provider_id)
	if provider == null:
		return false
	if provider.allowed_item_zones.is_empty():
		return item.can_be_carried_in(provider_id)
	for zone_name in provider.allowed_item_zones:
		if item.can_be_carried_in(StringName(zone_name)):
			return true
	return false


func _provider_has_contents(provider_id: StringName) -> bool:
	for stack in stacks:
		if stack != null and not stack.is_empty() and stack.carry_zone == provider_id:
			return true
	return false


func _provider_is_grounded(provider_id: StringName) -> bool:
	var resolved_provider_id = _resolve_provider_id(provider_id)
	if resolved_provider_id == CARRY_GROUND:
		return true
	var provider = storage_providers.get(resolved_provider_id)
	return provider != null and provider.equipment_slot_id == CARRY_GROUND


func _mount_slots_available(provider) -> bool:
	if provider.mount_slot == StorageProviderDefinitionScript.MountSlot.BACK and _find_provider_for_mount(provider.mount_slot) != &"":
		return false
	if provider.mount_slot == StorageProviderDefinitionScript.MountSlot.HANDS_CARRY:
		return _used_hand_carry_slots() + provider.hand_carry_slots_required <= 2
	if provider.shoulder_slots_required > 0:
		return _used_shoulder_slots() + provider.shoulder_slots_required <= 2
	return true


func _find_provider_for_mount(mount_slot: int) -> StringName:
	for provider_id in storage_providers.keys():
		var provider = storage_providers[provider_id]
		if provider.equipment_slot_id == CARRY_GROUND:
			continue
		if provider.mount_slot == mount_slot:
			return provider_id
	return &""


func _find_hand_carried_provider() -> StringName:
	for provider_id in storage_providers.keys():
		var provider = storage_providers[provider_id]
		if provider.equipment_slot_id == CARRY_GROUND:
			continue
		if provider.mount_slot == StorageProviderDefinitionScript.MountSlot.HANDS_CARRY and provider.provider_id != CARRY_HANDS_R:
			return provider_id
	return &""


func _used_hand_carry_slots() -> int:
	var total = 0
	for provider in storage_providers.values():
		if provider.equipment_slot_id == CARRY_GROUND:
			continue
		if provider.provider_id == CARRY_HANDS_R:
			continue
		total += provider.hand_carry_slots_required
	return total


func _used_shoulder_slots() -> int:
	var total = 0
	for provider in storage_providers.values():
		if provider.equipment_slot_id == CARRY_GROUND:
			continue
		total += provider.shoulder_slots_required
	return total


func _provider_over_capacity(provider_id: StringName) -> bool:
	return _provider_medium_over_capacity(provider_id) or _provider_small_over_capacity(provider_id)


func _provider_medium_over_capacity(provider_id: StringName) -> bool:
	var container = get_container_profile(provider_id)
	return container != null and get_provider_medium_units(provider_id) > container.medium_slots


func _provider_small_over_capacity(provider_id: StringName) -> bool:
	var container = get_container_profile(provider_id)
	return container != null and _get_used_small_equivalent_units(provider_id) > _get_total_small_equivalent_capacity(provider_id)


func _get_used_small_equivalent_units(provider_id: StringName) -> int:
	return (get_provider_medium_units(provider_id) * SMALL_UNITS_PER_MEDIUM_SLOT) + get_provider_small_units(provider_id)


func _get_total_small_equivalent_capacity(provider_id: StringName) -> int:
	var container = get_container_profile(provider_id)
	if container == null:
		return 0
	return container.get_effective_small_capacity()


func _create_bindle_provider():
	return _create_provider(
		&"bindle_hand_carry",
		"Bindle",
		&"bindle",
		SLOT_HAND_R,
		StorageProviderDefinitionScript.MountSlot.HANDS_CARRY,
		0,
		1,
		StorageProviderDefinitionScript.AccessSpeed.SLOW,
		0.4,
		0.8,
		_create_container_profile(&"bindle", "Bindle", 4, 16, 2, 1.0, 12.0),
		PackedStringArray(["pack"])
	)


func _create_backpack_provider():
	return _create_provider(
		&"backpack_back",
		"Backpack",
		&"backpack",
		SLOT_BACK,
		StorageProviderDefinitionScript.MountSlot.BACK,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.SLOW,
		0.8,
		0.2,
		_create_container_profile(&"backpack", "Backpack", 8, 32, 6, 1.1, 24.0),
		PackedStringArray(["pack"])
	)


func create_debug_pants_provider():
	return _create_provider(
		&"pants_pockets",
		"Pants",
		&"pants",
		SLOT_PANTS,
		StorageProviderDefinitionScript.MountSlot.NONE,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.TRAVEL,
		0.0,
		0.0,
		_create_container_profile(&"pants_pockets", "Leg Pockets", 0, 4, 2, 1.0, 1.5),
		PackedStringArray(["pocket"])
	)


func create_debug_satchel_provider():
	return _create_provider(
		&"satchel_shoulder",
		"Small Satchel",
		&"satchel",
		SLOT_SHOULDER_L,
		StorageProviderDefinitionScript.MountSlot.LEFT_SHOULDER,
		StorageProviderDefinitionScript.SHOULDER_SIZE_SMALL,
		0,
		StorageProviderDefinitionScript.AccessSpeed.TRAVEL,
		0.2,
		0.2,
		_create_container_profile(&"satchel", "Small Satchel", 2, 8, 2, 1.0, 6.0),
		PackedStringArray(["pack", "pocket"])
	)


func create_debug_haversack_provider():
	return _create_provider(
		&"haversack_shoulder",
		"Haversack",
		&"haversack",
		SLOT_SHOULDER_R,
		StorageProviderDefinitionScript.MountSlot.RIGHT_SHOULDER,
		StorageProviderDefinitionScript.SHOULDER_SIZE_SMALL,
		0,
		StorageProviderDefinitionScript.AccessSpeed.SLOW,
		0.4,
		0.3,
		_create_container_profile(&"haversack", "Haversack", 4, 16, 2, 1.0, 12.0),
		PackedStringArray(["pack", "pocket"])
	)


func create_debug_coat_provider():
	return _create_provider(
		&"coat_pockets",
		"Worn Wool Coat",
		&"wool_coat",
		SLOT_COAT,
		StorageProviderDefinitionScript.MountSlot.NONE,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.TRAVEL,
		0.1,
		0.0,
		_create_container_profile(&"coat_pockets", "Coat Pockets", 1, 8, 2, 1.0, 3.0),
		PackedStringArray(["pocket", "pack"])
	)


func create_debug_belt_provider():
	return _create_provider(
		&"belt_waist",
		"Work Belt",
		&"belt",
		SLOT_BELT_WAIST,
		StorageProviderDefinitionScript.MountSlot.NONE,
		0,
		0,
		StorageProviderDefinitionScript.AccessSpeed.TRAVEL,
		0.1,
		0.0,
		_create_container_profile(&"belt_waist", "Belt Storage", 1, 4, 0, 1.0, 4.0),
		PackedStringArray(["pack", "hands"])
	)


func _create_provider(provider_id: StringName, display_name: String, source_item_id: StringName, equipment_slot_id: StringName, mount_slot: int, shoulder_slots_required: int, hand_carry_slots_required: int, access_speed: int, fatigue_modifier: float, awkward_carry_modifier: float, container_profile, allowed_item_zones: PackedStringArray):
	var provider = StorageProviderDefinitionScript.new()
	provider.provider_id = provider_id
	provider.display_name = display_name
	provider.source_item_id = source_item_id
	provider.equipment_slot_id = equipment_slot_id
	provider.mount_slot = mount_slot
	provider.shoulder_slots_required = shoulder_slots_required
	provider.hand_carry_slots_required = hand_carry_slots_required
	provider.access_speed = access_speed
	provider.fatigue_modifier = fatigue_modifier
	provider.awkward_carry_modifier = awkward_carry_modifier
	provider.container_profile = container_profile
	provider.allowed_item_zones = allowed_item_zones
	return provider


func _is_base_provider(provider_id: StringName) -> bool:
	return provider_id == CARRY_HANDS or provider_id == CARRY_HANDS_R or provider_id == CARRY_GROUND


func _serialize_storage_provider(provider) -> Dictionary:
	return {
		"provider_id": String(provider.provider_id),
		"display_name": provider.display_name,
		"source_item_id": String(provider.source_item_id),
		"equipment_slot_id": String(provider.equipment_slot_id),
		"mount_slot": int(provider.mount_slot),
		"shoulder_slots_required": provider.shoulder_slots_required,
		"hand_carry_slots_required": provider.hand_carry_slots_required,
		"access_speed": int(provider.access_speed),
		"fatigue_modifier": provider.fatigue_modifier,
		"awkward_carry_modifier": provider.awkward_carry_modifier,
		"allowed_item_zones": Array(provider.allowed_item_zones),
		"container_profile": _serialize_container_profile(provider.container_profile)
	}


func _serialize_container_profile(container_profile) -> Dictionary:
	if container_profile == null:
		return {}
	return {
		"container_id": String(container_profile.container_id),
		"display_name": container_profile.display_name,
		"medium_slots": container_profile.medium_slots,
		"small_capacity": container_profile.small_capacity,
		"overflow_small_capacity": container_profile.overflow_small_capacity,
		"organization_modifier": container_profile.organization_modifier,
		"max_weight_kg": container_profile.max_weight_kg
	}


func _restore_storage_provider_from_save(provider_data: Dictionary) -> bool:
	if typeof(provider_data) != TYPE_DICTIONARY:
		return false

	var provider_id = StringName(provider_data.get("provider_id", ""))
	if provider_id == &"" or _is_base_provider(provider_id):
		return false

	var container_profile_data = provider_data.get("container_profile", {})
	if typeof(container_profile_data) != TYPE_DICTIONARY:
		return false

	var provider = _create_provider(
		provider_id,
		String(provider_data.get("display_name", "")),
		StringName(provider_data.get("source_item_id", "")),
		StringName(provider_data.get("equipment_slot_id", "")),
		int(provider_data.get("mount_slot", StorageProviderDefinitionScript.MountSlot.NONE)),
		int(provider_data.get("shoulder_slots_required", 0)),
		int(provider_data.get("hand_carry_slots_required", 0)),
		int(provider_data.get("access_speed", StorageProviderDefinitionScript.AccessSpeed.TRAVEL)),
		float(provider_data.get("fatigue_modifier", 0.0)),
		float(provider_data.get("awkward_carry_modifier", 0.0)),
		_create_container_profile(
			StringName(container_profile_data.get("container_id", "")),
			String(container_profile_data.get("display_name", "")),
			int(container_profile_data.get("medium_slots", 0)),
			int(container_profile_data.get("small_capacity", 0)),
			int(container_profile_data.get("overflow_small_capacity", 0)),
			float(container_profile_data.get("organization_modifier", 1.0)),
			float(container_profile_data.get("max_weight_kg", 0.0))
		),
		_to_packed_string_array(provider_data.get("allowed_item_zones", []))
	)
	if not provider.is_valid_definition():
		return false

	_add_storage_provider(provider)
	_set_equipment_provider(provider)
	return true


func _to_packed_string_array(value) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		for entry in value:
			result.append(String(entry))
		return result
	if value is Array:
		for entry in value:
			result.append(String(entry))
	return result


func _create_container_profile(container_id: StringName, display_name: String, medium_slots: int, small_capacity: int, overflow_small_capacity: int, organization_modifier: float, max_weight_kg: float):
	var profile = ContainerProfileScript.new()
	profile.container_id = container_id
	profile.display_name = display_name
	profile.medium_slots = medium_slots
	profile.small_capacity = small_capacity
	profile.overflow_small_capacity = overflow_small_capacity
	profile.organization_modifier = organization_modifier
	profile.max_weight_kg = max_weight_kg
	return profile
