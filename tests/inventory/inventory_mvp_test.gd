extends SceneTree

const InventoryScript := preload("res://scripts/inventory/inventory.gd")
const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")
const PlayerStateServiceScript := preload("res://scripts/player/player_state_service.gd")

var _failed := false


func _init() -> void:
	var catalog = load("res://data/items/inventory_catalog.tres")
	catalog.rebuild_index()

	var inventory = InventoryScript.new()
	inventory.set_item_catalog(catalog)
	_expect(inventory.set_pack_container(&"backpack").get("success", false), "debug backpack provider is visible")
	_expect(inventory.equip_storage_provider(inventory.create_debug_coat_provider()).get("success", false), "debug coat provider is visible")
	_expect(inventory.equip_storage_provider(inventory.create_debug_satchel_provider()).get("success", false), "debug satchel provider is visible")
	var beans = catalog.get_item(&"beans_can")
	var coat = catalog.get_item(&"wool_coat")
	var letter = catalog.get_item(&"family_letter")

	_expect(beans != null, "beans item is defined")
	_expect(coat != null, "coat item is defined")
	_expect(letter != null, "letter item is defined")

	_expect(inventory.add_item(beans, 4, ItemDefinitionScript.CARRY_PACK) == 0, "beans split into finite pack stacks")
	_expect(inventory.count_item(&"beans_can") == 4, "beans quantity is tracked")
	_expect(inventory.get_used_slots(ItemDefinitionScript.CARRY_PACK) == 4, "beans occupy one medium slot per can")

	_expect(inventory.add_item(letter, 1, ItemDefinitionScript.CARRY_PACK) == 0, "letter can be carried in pack")
	_expect(inventory.add_item(letter, 1, ItemDefinitionScript.CARRY_POCKET) == 0, "letter can be carried in pocket")

	_expect(inventory.add_item(coat, 20, ItemDefinitionScript.CARRY_PACK) > 0, "pack rejects coats beyond slots and weight")
	_expect(inventory.get_total_weight_kg() <= inventory.max_total_weight_kg, "inventory never exceeds total weight")
	_expect(inventory.get_travel_speed_modifier() <= 1.0, "load exposes travel speed pressure")

	var saved = inventory.to_save_data()
	var loaded = InventoryScript.new()
	_expect(loaded.from_save_data(saved, catalog), "inventory restores from saved item ids")
	_expect(loaded.count_item(&"beans_can") == inventory.count_item(&"beans_can"), "loaded inventory preserves stack quantities")

	var move_inventory = InventoryScript.new()
	move_inventory.set_item_catalog(catalog)
	_expect(move_inventory.equip_storage_provider(move_inventory.create_debug_coat_provider()).get("success", false), "move test coat provider is visible")
	_expect(move_inventory.equip_storage_provider(move_inventory.create_debug_satchel_provider()).get("success", false), "move test satchel provider is visible")
	_expect(move_inventory.add_item(beans, 1, &"satchel_shoulder") == 0, "move test item starts in satchel")
	var move_result = move_inventory.move({
		"dragged_ref": {"type": "stack", "stack_index": 0},
		"target_provider_id": InventoryScript.SLOT_HAND_L
	})
	_expect(move_result.get("success", false), "unified move moves a stack to a visible hand provider")
	_expect(move_result.get("reason_code", &"") == &"move_committed", "unified move reports stable success reason")
	_expect(move_inventory.get_stack_at(0).carry_zone == InventoryScript.SLOT_HAND_L, "unified move commits stack provider")

	var dry_inventory = move_inventory.duplicate_inventory()
	var dry_result = dry_inventory.preview_move({
		"dragged_ref": {"type": "stack", "stack_index": 0},
		"target_provider_id": InventoryScript.CARRY_GROUND
	})
	_expect(dry_result.get("success", false), "preview move validates through the unified path")
	_expect(dry_result.get("changed", true) == false, "preview move does not mutate state")
	_expect(dry_inventory.get_stack_at(0).carry_zone == InventoryScript.SLOT_HAND_L, "preview move leaves stack in source provider")

	var invalid_result = move_inventory.move({
		"dragged_ref": {"type": "stack", "stack_index": 0},
		"target_provider_id": &"missing_provider"
	})
	_expect(not invalid_result.get("success", true), "unified move rejects missing target providers")
	_expect(invalid_result.get("reason_code", &"") == &"invalid_target_provider", "unified move reports stable missing target reason")

	var visible_provider_states = move_inventory.get_visible_provider_states()
	_expect(visible_provider_states.size() >= 4, "inventory exposes visible provider states")
	_expect(_provider_state_exists(visible_provider_states, InventoryScript.SLOT_HAND_L), "visible providers include left hand")
	_expect(_provider_state_exists(visible_provider_states, InventoryScript.CARRY_GROUND), "visible providers include ground")

	var provider_move_inventory = InventoryScript.new()
	provider_move_inventory.set_item_catalog(catalog)
	_expect(provider_move_inventory.equip_storage_provider(provider_move_inventory.create_debug_satchel_provider()).get("success", false), "provider move test satchel starts visible")
	var provider_preview = provider_move_inventory.preview_move({
		"dragged_ref": {"type": "provider", "provider_id": &"satchel_shoulder"},
		"target_provider_id": InventoryScript.SLOT_SHOULDER_R
	})
	_expect(provider_preview.get("success", false), "preview move validates provider-backed item movement")
	_expect(provider_preview.get("changed", true) == false, "provider preview does not mutate state")
	_expect(provider_move_inventory.get_storage_provider(&"satchel_shoulder").equipment_slot_id == InventoryScript.SLOT_SHOULDER_L, "provider preview leaves container in source provider")
	var provider_move_result = provider_move_inventory.move({
		"dragged_ref": {"type": "provider", "provider_id": &"satchel_shoulder"},
		"target_provider_id": InventoryScript.SLOT_SHOULDER_R
	})
	_expect(provider_move_result.get("success", false), "unified move moves provider-backed items")
	_expect(provider_move_result.get("reason_code", &"") == &"move_committed", "provider move reports stable success reason")
	_expect(provider_move_inventory.get_storage_provider(&"satchel_shoulder").equipment_slot_id == InventoryScript.SLOT_SHOULDER_R, "provider move commits target provider")

	var state_service = PlayerStateServiceScript.new()
	state_service.ensure_bootstrapped()
	var player_state = state_service.get_player_state()
	var service_stack_index = _find_stack_index(player_state.inventory_state, &"beans_can")
	_expect(service_stack_index >= 0, "service move test finds a starter beans stack")
	var service_move_result = state_service.execute_action("inventory.move", {
		"dragged_ref": {"type": "stack", "stack_index": service_stack_index},
		"target_provider_id": InventoryScript.CARRY_GROUND
	})
	_expect(service_move_result.get("success", false), "player state service routes unified inventory move")
	_expect(service_move_result.get("reason_code", &"") == &"move_committed", "service move preserves inventory reason code")
	_expect(player_state.inventory_state.get_stack_at(service_stack_index).carry_zone == InventoryScript.CARRY_GROUND, "service move commits through inventory state")
	state_service.free()

	var exit_code = 0
	if _failed:
		exit_code = 1
	quit(exit_code)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)


func _provider_state_exists(provider_states: Array, provider_id: StringName) -> bool:
	for provider_state in provider_states:
		if not (provider_state is Dictionary):
			continue
		if StringName(provider_state.get("provider_id", &"")) == provider_id:
			return true
	return false


func _find_stack_index(inventory, item_id: StringName) -> int:
	for stack_index in range(inventory.stacks.size()):
		var stack = inventory.get_stack_at(stack_index)
		if stack != null and stack.item != null and stack.item.item_id == item_id:
			return stack_index
	return -1
