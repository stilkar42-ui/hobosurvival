class_name InventoryStack
extends Resource

const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")

var item = null
@export_range(1, 999, 1) var quantity := 1
@export var carry_zone: StringName = ItemDefinitionScript.CARRY_PACK
@export_range(0, 5, 1) var quality_tier := ItemDefinitionScript.QualityTier.COMMON
@export_range(0.0, 5.0, 0.01) var quality_score := 1.0
@export_range(-1, 100, 1) var durability_uses_remaining := -1


func setup(new_item, new_quantity: int, new_carry_zone: StringName, new_quality_tier: int = -1, new_quality_score: float = -1.0, new_durability_uses_remaining: int = -1) -> InventoryStack:
	item = new_item
	quantity = max(new_quantity, 0)
	carry_zone = new_carry_zone
	if item != null:
		quality_tier = clampi(new_quality_tier if new_quality_tier >= 0 else int(item.quality_tier), ItemDefinitionScript.QualityTier.POOR, ItemDefinitionScript.QualityTier.LEGENDARY)
		quality_score = clampf(new_quality_score if new_quality_score >= 0.0 else item.get_quality_score(), float(ItemDefinitionScript.QualityTier.POOR), float(ItemDefinitionScript.QualityTier.LEGENDARY))
	durability_uses_remaining = new_durability_uses_remaining
	return self


func is_empty() -> bool:
	return item == null or quantity <= 0


func can_stack_with(other_item, other_carry_zone: StringName, other_quality_tier: int = -1) -> bool:
	if is_empty() or other_item == null:
		return false
	var resolved_quality_tier = other_quality_tier if other_quality_tier >= 0 else int(other_item.quality_tier)
	return item.item_id == other_item.item_id \
		and carry_zone == other_carry_zone \
		and quality_tier == resolved_quality_tier \
		and quantity < item.max_stack


func get_free_stack_space() -> int:
	if is_empty():
		return 0
	return max(item.max_stack - quantity, 0)


func add_quantity(amount: int) -> int:
	if is_empty() or amount <= 0:
		return amount
	var accepted = min(amount, get_free_stack_space())
	quantity += accepted
	return amount - accepted


func remove_quantity(amount: int) -> int:
	if is_empty() or amount <= 0:
		return 0
	var removed = min(amount, quantity)
	quantity -= removed
	return removed


func get_weight_kg() -> float:
	if is_empty():
		return 0.0
	return item.get_stack_weight_kg(quantity)


func get_quality_name() -> String:
	if item == null:
		return "common"
	return item.get_quality_name(quality_tier)


func get_quality_color() -> Color:
	if item == null:
		return Color(0.93, 0.91, 0.86)
	return item.get_quality_color(quality_tier)


func get_quality_score() -> float:
	return clampf(quality_score, float(ItemDefinitionScript.QualityTier.POOR), float(ItemDefinitionScript.QualityTier.LEGENDARY))


func duplicate_stack() -> InventoryStack:
	var stack = InventoryStack.new()
	stack.setup(item, quantity, carry_zone, quality_tier, quality_score, durability_uses_remaining)
	return stack


func to_save_data() -> Dictionary:
	if is_empty():
		return {}
	return {
		"item_id": String(item.item_id),
		"quantity": quantity,
		"carry_zone": String(carry_zone),
		"quality_tier": quality_tier,
		"quality_score": quality_score,
		"durability_uses_remaining": durability_uses_remaining
	}


func from_save_data(data: Dictionary, item_catalog) -> bool:
	var loaded_item = item_catalog.get_item(StringName(data.get("item_id", "")))
	if loaded_item == null:
		return false
	item = loaded_item
	quantity = int(data.get("quantity", 1))
	carry_zone = StringName(data.get("carry_zone", ItemDefinitionScript.CARRY_PACK))
	quality_tier = clampi(int(data.get("quality_tier", int(item.quality_tier))), ItemDefinitionScript.QualityTier.POOR, ItemDefinitionScript.QualityTier.LEGENDARY)
	quality_score = clampf(float(data.get("quality_score", item.get_quality_score())), float(ItemDefinitionScript.QualityTier.POOR), float(ItemDefinitionScript.QualityTier.LEGENDARY))
	durability_uses_remaining = int(data.get("durability_uses_remaining", durability_uses_remaining))
	return quantity > 0 and carry_zone != &""
