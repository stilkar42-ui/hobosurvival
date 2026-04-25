extends SceneTree

const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")

const MEDICAL_ITEM_IDS := [
	&"clean_rag_bundle",
	&"bandage_roll",
	&"carbolic_soap",
	&"iodine_bottle",
	&"healing_salve",
	&"foot_powder",
	&"liniment_bottle",
	&"headache_powder",
	&"cough_syrup",
	&"patent_tonic"
]

var _failed := false


func _init() -> void:
	var item_catalog = load("res://data/items/inventory_catalog.tres")
	_expect(item_catalog != null, "inventory catalog loads")
	if item_catalog == null:
		quit(1)
		return
	item_catalog.rebuild_index()

	for item_id in MEDICAL_ITEM_IDS:
		_assert_medical_item(item_catalog, item_id)

	quit(1 if _failed else 0)


func _assert_medical_item(item_catalog, item_id: StringName) -> void:
	var item = item_catalog.get_item(item_id)
	_expect(item != null, "%s exists in inventory catalog" % String(item_id))
	if item == null:
		return
	_expect(item.is_valid_definition(), "%s is a valid item definition" % String(item_id))
	_expect(item.category == ItemDefinitionScript.Category.MEDICAL, "%s uses the medical category" % String(item_id))
	_expect(item.unit_weight_kg > 0.0, "%s has positive weight" % String(item_id))
	_expect(item.trade_value_cents > 0, "%s has positive trade value" % String(item_id))
	_expect(_has_medical_tag(item), "%s has medical/apothecary behavior tags" % String(item_id))
	_expect(item.capabilities.has("inspect"), "%s can be inspected" % String(item_id))
	_expect(item.capabilities.has("hold"), "%s can be held" % String(item_id))
	_expect(not item.is_consumable, "%s is not consumable yet" % String(item_id))
	_expect(item.use_result_type == ItemDefinitionScript.UseResultType.NONE, "%s has no use result yet" % String(item_id))
	_expect(item.use_outputs.is_empty(), "%s has no use outputs yet" % String(item_id))
	_expect(item.nutrition_value == 0, "%s has no nutrition effect" % String(item_id))
	_expect(item.warmth_value == 0, "%s has no warmth effect" % String(item_id))
	_expect(item.fatigue_relief == 0, "%s has no stamina effect" % String(item_id))
	_expect(item.hygiene_value == 0, "%s has no hygiene effect" % String(item_id))
	_expect(item.presentability_value == 0, "%s has no presentability effect" % String(item_id))
	_expect(item.morale_value == 0, "%s has no morale effect" % String(item_id))


func _has_medical_tag(item) -> bool:
	for tag in ["medical", "apothecary", "wound_care", "hygiene", "comfort", "questionable_medicine"]:
		if item.behavior_tags.has(tag):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
