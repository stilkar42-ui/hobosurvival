class_name ItemQualityRules
extends RefCounted

const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")


static func calculate_output_quality(input_items: Array, rng: RandomNumberGenerator = null) -> int:
	if input_items.is_empty():
		return ItemDefinitionScript.QualityTier.COMMON

	var total_score := 0.0
	var counted := 0
	for entry in input_items:
		var score = _extract_quality_score(entry)
		if score < 0.0:
			continue
		total_score += score
		counted += 1

	if counted <= 0:
		return ItemDefinitionScript.QualityTier.COMMON

	var local_rng = rng
	if local_rng == null:
		local_rng = RandomNumberGenerator.new()
		local_rng.randomize()

	# Small variance gives crafting room to breathe later without turning quality
	# into casino math; the average of the actual materials remains dominant.
	var averaged_score = (total_score / float(counted)) + local_rng.randf_range(-0.35, 0.35)
	return clampi(int(round(averaged_score)), ItemDefinitionScript.QualityTier.POOR, ItemDefinitionScript.QualityTier.LEGENDARY)


static func _extract_quality_score(entry) -> float:
	if entry == null:
		return -1.0
	if entry is Dictionary:
		if entry.has("quality_score"):
			return float(entry.get("quality_score", 1.0))
		if entry.has("quality_tier"):
			return float(entry.get("quality_tier", ItemDefinitionScript.QualityTier.COMMON))
		if entry.has("item"):
			return _extract_quality_score(entry.get("item"))
	if not (entry is Object):
		return -1.0
	if entry.has_method("get_quality_score"):
		return float(entry.get_quality_score())
	var property_score = entry.get("quality_score")
	if property_score != null:
		return float(property_score)
	var property_tier = entry.get("quality_tier")
	if property_tier != null:
		return float(property_tier)
	var property_item = entry.get("item")
	if property_item != null:
		return _extract_quality_score(property_item)
	return -1.0
