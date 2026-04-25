extends SceneTree

const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")

var _failed := false


func _init() -> void:
	var store_catalog_script = load("res://scripts/data/store_inventory_catalog.gd")
	_expect(store_catalog_script != null, "store inventory catalog script loads")
	if store_catalog_script == null:
		quit(1)
		return

	var item_catalog = load("res://data/items/inventory_catalog.tres")
	item_catalog.rebuild_index()

	_assert_supported_store_ids(store_catalog_script)
	_assert_active_pool(store_catalog_script, item_catalog, &"grocery", [&"coffee_grounds", &"beans_can", &"potted_meat"])
	_assert_active_pool(store_catalog_script, item_catalog, &"hardware", [&"baling_wire"])
	_assert_future_profile(store_catalog_script, &"general_store")
	_assert_future_profile(store_catalog_script, &"medicine")
	_assert_future_profile(store_catalog_script, &"specialist_grocery")
	_assert_future_profile(store_catalog_script, &"specialist_hardware")
	_assert_future_profile(store_catalog_script, &"specialist_medicine")

	quit(1 if _failed else 0)


func _assert_supported_store_ids(store_catalog_script) -> void:
	var supported_ids: Array = store_catalog_script.get_supported_store_ids()
	for store_id in [&"grocery", &"hardware", &"general_store", &"medicine", &"specialist_grocery", &"specialist_hardware", &"specialist_medicine"]:
		_expect(supported_ids.has(store_id), "store catalog supports %s" % String(store_id))


func _assert_active_pool(store_catalog_script, item_catalog, store_id: StringName, required_ids: Array) -> void:
	var pool: Array = store_catalog_script.get_store_pool(store_id)
	_expect(not pool.is_empty(), "%s pool is active" % String(store_id))
	for required_id in required_ids:
		_expect(store_catalog_script.get_required_stock_item_ids(store_id).has(required_id), "%s requires %s" % [String(store_id), String(required_id)])
	for entry in pool:
		_expect(entry is Dictionary, "%s pool entry is dictionary data" % String(store_id))
		if not (entry is Dictionary):
			continue
		var item_id = StringName(entry.get("item_id", &""))
		_expect(item_id != &"", "%s pool entry has an item id" % String(store_id))
		_expect(item_catalog.get_item(item_id) != null, "%s pool item %s exists in item catalog" % [String(store_id), String(item_id)])
		_expect(int(entry.get("base_price_cents", 0)) > 0, "%s pool item %s has a base price" % [String(store_id), String(item_id)])
		_expect(int(entry.get("weight", 0)) > 0, "%s pool item %s has a selection weight" % [String(store_id), String(item_id)])
		_expect(entry.has("min_quality"), "%s pool item %s has min quality" % [String(store_id), String(item_id)])
		_expect(entry.has("max_quality"), "%s pool item %s has max quality" % [String(store_id), String(item_id)])
		_expect(int(entry.get("max_quality", -1)) <= ItemDefinitionScript.QualityTier.GOOD, "%s active pool item %s stays within current basic-store quality cap" % [String(store_id), String(item_id)])


func _assert_future_profile(store_catalog_script, store_id: StringName) -> void:
	var profile: Dictionary = store_catalog_script.get_store_profile(store_id)
	_expect(not profile.is_empty(), "%s future profile exists" % String(store_id))
	_expect(StringName(profile.get("store_id", &"")) == store_id, "%s future profile identifies its store id" % String(store_id))
	_expect(profile.has("quality_policy"), "%s future profile describes quality policy" % String(store_id))
	_expect(profile.has("future_manager_notes"), "%s future profile has StoreManager notes" % String(store_id))
	if store_id != &"grocery" and store_id != &"hardware":
		_expect(store_catalog_script.get_store_pool(store_id).is_empty(), "%s future profile has no active stock pool yet" % String(store_id))


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
