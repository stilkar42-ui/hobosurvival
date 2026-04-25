class_name ItemDefinition
extends Resource

enum Category {
	FOOD,
	CLOTHING,
	TOOL,
	MATERIAL,
	MEDICAL,
	PERSONAL,
	TRADE_GOOD,
	CONTAINER
}

enum SizeClass {
	SMALL,
	MEDIUM,
	LARGE
}

enum QualityTier {
	POOR,
	COMMON,
	GOOD,
	SUPERIOR,
	EXCEPTIONAL,
	LEGENDARY
}

enum UseResultType {
	NONE,
	CONSUME_DESTROY,
	CONSUME_LEAVE_RESIDUE,
	USE_REDUCE_QUANTITY,
	USE_TRANSFORM,
	READ_PERSISTENT
}

enum FoodType {
	NONE,
	PREPARED_IMMEDIATE,
	STORED_RATION,
	COOK_INGREDIENT
}

const CARRY_PACK := &"pack"
const CARRY_POCKET := &"pocket"
const CARRY_HANDS := &"hands"

const SLOT_BACK := &"slot_back"
const SLOT_SHOULDER_L := &"slot_shoulder_l"
const SLOT_SHOULDER_R := &"slot_shoulder_r"
const SLOT_BELT_WAIST := &"slot_belt_waist"
const SLOT_HAND_L := &"slot_hand_l"
const SLOT_HAND_R := &"slot_hand_r"
const SLOT_PANTS := &"slot_pants"
const SLOT_COAT := &"slot_coat"

const CAP_CONSUME := &"consume"
const CAP_USE := &"use"
const CAP_OPEN := &"open"
const CAP_READ := &"read"
const CAP_INSPECT := &"inspect"
const CAP_EQUIP := &"equip"
const CAP_HOLD := &"hold"
const CAP_TOOL := &"tool"
const CAP_WEAPON := &"weapon"
const CAP_COOK_INGREDIENT := &"cook_ingredient"
const CAPABILITY_FLAG_KEYS := {
	CAP_CONSUME: "can_consume",
	CAP_USE: "can_use",
	CAP_OPEN: "can_open",
	CAP_READ: "can_read",
	CAP_EQUIP: "can_equip",
	CAP_HOLD: "can_hold",
	CAP_TOOL: "usable_as_tool",
	CAP_WEAPON: "usable_as_weapon",
	CAP_COOK_INGREDIENT: "cook_ingredient"
}

const TAG_CONTAINER := &"container"
const TAG_WEARABLE := &"wearable"
const TAG_HOLDABLE := &"holdable"

@export var item_id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var category: Category = Category.MATERIAL
@export_range(0, 5, 1) var quality_tier := QualityTier.COMMON
@export_range(0.0, 5.0, 0.01) var quality_score := 1.0
@export_range(0.01, 80.0, 0.01, "suffix:kg") var unit_weight_kg := 0.1
@export_range(1, 20, 1) var max_stack := 1
@export var size_class: SizeClass = SizeClass.MEDIUM
@export_range(1, 8, 1) var large_medium_slots := 2
@export var allowed_carry_zones: PackedStringArray = PackedStringArray(["pack"])
@export var hand_holdable := false
@export var behavior_tags: PackedStringArray = PackedStringArray()
@export var capabilities: PackedStringArray = PackedStringArray()
@export var capability_flags: Dictionary = {}
@export var equip_slot_ids: PackedStringArray = PackedStringArray()
@export_range(0, 10000, 1, "suffix:cents") var trade_value_cents := 0
@export var visible_to_others := true
@export var is_consumable := false
@export_multiline var use_message := ""
@export_multiline var read_text := ""
@export var use_result_type: UseResultType = UseResultType.NONE
@export var use_outputs: Dictionary = {}
@export var food_type: FoodType = FoodType.NONE

@export_group("Survival Effects")
@export_range(0, 100, 1) var nutrition_value := 0
@export_range(0, 100, 1) var warmth_value := 0
@export_range(0, 100, 1) var fatigue_relief := 0
@export_range(0, 100, 1) var hygiene_value := 0
@export_range(0, 100, 1) var presentability_value := 0
@export_range(0, 100, 1) var dampness_relief := 0
@export_range(-100, 100, 1) var morale_value := 0

@export_group("System Tags")
@export var work_tags: PackedStringArray = []
@export var social_tags: PackedStringArray = []
@export var fading_food_source: StringName = &""
@export_range(0, 10, 1) var fading_comfort_load := 0

@export_group("Tool Function")
@export_range(0, 100, 1) var cooking_max_uses := 0
@export_range(0, 100, 1) var cooking_use_cost := 1
@export_range(0.0, 3.0, 0.05) var cooking_efficiency := 1.0
@export_range(0.0, 3.0, 0.05) var cooking_stability := 1.0
@export var carry_profile := ""


func can_stack() -> bool:
	return max_stack > 1


func can_be_carried_in(carry_zone: StringName) -> bool:
	if carry_zone == CARRY_HANDS:
		return allowed_carry_zones.has(String(carry_zone)) or size_class != SizeClass.LARGE or hand_holdable
	return allowed_carry_zones.has(String(carry_zone))


func has_behavior_tag(tag: StringName) -> bool:
	return behavior_tags.has(String(tag))


func has_capability(capability: StringName) -> bool:
	if capabilities.has(String(capability)):
		return true
	var flag_key = CAPABILITY_FLAG_KEYS.get(capability, "")
	return flag_key != "" and bool(capability_flags.get(flag_key, false))


func can_consume() -> bool:
	return has_capability(CAP_CONSUME) or is_consumable


func can_read() -> bool:
	return has_capability(CAP_READ) or read_text.strip_edges() != ""


func can_open() -> bool:
	return has_capability(CAP_OPEN) or has_behavior_tag(TAG_CONTAINER)


func can_hold() -> bool:
	return has_capability(CAP_HOLD) or can_hold_in_hands()


func can_equip() -> bool:
	# "Equip" means actively readying something already held; holdability alone
	# only means it can sit in a hand.
	return has_capability(CAP_EQUIP) \
		or has_capability(CAP_TOOL) \
		or has_capability(CAP_WEAPON)


func can_use() -> bool:
	return has_capability(CAP_USE) or can_consume() or can_read() or use_result_type != UseResultType.NONE


func usable_as_tool() -> bool:
	return has_capability(CAP_TOOL)


func usable_as_weapon() -> bool:
	return has_capability(CAP_WEAPON)


func is_cook_ingredient() -> bool:
	return has_capability(CAP_COOK_INGREDIENT) or food_type == FoodType.COOK_INGREDIENT


func is_container_item() -> bool:
	return has_behavior_tag(TAG_CONTAINER)


func is_wearable_item() -> bool:
	return has_behavior_tag(TAG_WEARABLE) or not equip_slot_ids.is_empty()


func can_hold_in_hands() -> bool:
	return has_behavior_tag(TAG_HOLDABLE) or has_capability(CAP_HOLD) or can_be_carried_in(CARRY_HANDS)


func get_valid_equip_slots() -> Array:
	var slot_ids: Array = []
	for raw_slot_id in equip_slot_ids:
		var slot_id = StringName(raw_slot_id)
		if slot_id != &"" and not slot_ids.has(slot_id):
			slot_ids.append(slot_id)
	if not slot_ids.is_empty():
		return slot_ids
	if can_hold_in_hands():
		return [SLOT_HAND_L, SLOT_HAND_R]
	return []


func can_equip_to_slot(slot_id: StringName) -> bool:
	return get_valid_equip_slots().has(slot_id)


func get_read_text() -> String:
	var trimmed = read_text.strip_edges()
	if trimmed != "":
		return trimmed
	return description.strip_edges()


func get_quality_name(tier: int = -1) -> String:
	var resolved_tier = quality_tier if tier < 0 else tier
	match clampi(resolved_tier, QualityTier.POOR, QualityTier.LEGENDARY):
		QualityTier.POOR:
			return "poor"
		QualityTier.COMMON:
			return "common"
		QualityTier.GOOD:
			return "good"
		QualityTier.SUPERIOR:
			return "superior"
		QualityTier.EXCEPTIONAL:
			return "exceptional"
		QualityTier.LEGENDARY:
			return "legendary"
		_:
			return "common"


func get_quality_color(tier: int = -1) -> Color:
	var resolved_tier = quality_tier if tier < 0 else tier
	match clampi(resolved_tier, QualityTier.POOR, QualityTier.LEGENDARY):
		QualityTier.POOR:
			return Color(0.55, 0.55, 0.55)
		QualityTier.COMMON:
			return Color(0.93, 0.91, 0.86)
		QualityTier.GOOD:
			return Color(0.43, 0.75, 0.42)
		QualityTier.SUPERIOR:
			return Color(0.34, 0.55, 0.92)
		QualityTier.EXCEPTIONAL:
			return Color(0.63, 0.42, 0.88)
		QualityTier.LEGENDARY:
			return Color(0.95, 0.72, 0.28)
		_:
			return Color(0.93, 0.91, 0.86)


func get_quality_score() -> float:
	if quality_tier != QualityTier.COMMON and is_equal_approx(quality_score, float(QualityTier.COMMON)):
		return float(quality_tier)
	return clampf(quality_score, float(QualityTier.POOR), float(QualityTier.LEGENDARY))


func get_use_output_item_id() -> StringName:
	return StringName(use_outputs.get("spawn_item_id", use_outputs.get("spawn_item", "")))


func get_use_output_quantity() -> int:
	return max(int(use_outputs.get("quantity", 1)), 1)


func get_food_type_name() -> String:
	match food_type:
		FoodType.PREPARED_IMMEDIATE:
			return "prepared immediate"
		FoodType.STORED_RATION:
			return "stored ration"
		FoodType.COOK_INGREDIENT:
			return "cook ingredient"
		_:
			return ""


func get_stack_weight_kg(quantity: int) -> float:
	return unit_weight_kg * max(quantity, 0)


func get_medium_slots_per_unit() -> int:
	if size_class == SizeClass.LARGE:
		return max(large_medium_slots, 2)
	if size_class == SizeClass.MEDIUM:
		return 1
	return 0


func get_small_units_per_unit() -> int:
	if size_class == SizeClass.SMALL:
		return 1
	return 0


func get_size_class_name() -> String:
	match size_class:
		SizeClass.SMALL:
			return "small"
		SizeClass.MEDIUM:
			return "medium"
		SizeClass.LARGE:
			return "large"
		_:
			return "unknown"


func get_inventory_tooltip_text() -> String:
	var lines: Array[String] = []
	var trimmed_description = description.strip_edges()
	if trimmed_description != "":
		lines.append(trimmed_description)

	var behavior_line = _build_behavior_line()
	if behavior_line != "":
		if not lines.is_empty():
			lines.append("")
		lines.append(behavior_line)

	lines.append("Quality: %s" % get_quality_name().capitalize())
	var food_type_line = get_food_type_name()
	if food_type_line != "":
		lines.append("Food: %s" % food_type_line)

	var equip_line = _build_equip_line()
	if equip_line != "":
		lines.append(equip_line)
	var tool_line = _build_tool_function_line()
	if tool_line != "":
		lines.append(tool_line)

	var effects := get_consumable_effect_lines()
	if not effects.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append_array(effects)

	return "\n".join(lines)


func get_consumable_effect_lines() -> Array[String]:
	var lines: Array[String] = []
	if nutrition_value > 0:
		lines.append("+%d Nutrition" % nutrition_value)
	if fatigue_relief > 0:
		lines.append("+%d Stamina" % fatigue_relief)
	if warmth_value > 0:
		lines.append("+%d Warmth" % warmth_value)
	if hygiene_value > 0:
		lines.append("+%d Hygiene" % hygiene_value)
	if presentability_value > 0:
		lines.append("+%d Presentability" % presentability_value)
	if dampness_relief > 0:
		lines.append("-%d Dampness" % dampness_relief)
	if morale_value != 0:
		lines.append("%s%d Morale" % ["+" if morale_value > 0 else "", morale_value])
	return lines


func is_valid_definition() -> bool:
	return item_id != &"" and display_name.strip_edges() != "" and unit_weight_kg > 0.0 and max_stack > 0


func get_category_name() -> String:
	match category:
		Category.FOOD:
			return "food"
		Category.CLOTHING:
			return "clothing"
		Category.TOOL:
			return "tool"
		Category.MATERIAL:
			return "material"
		Category.MEDICAL:
			return "medical"
		Category.PERSONAL:
			return "personal"
		Category.TRADE_GOOD:
			return "trade_good"
		Category.CONTAINER:
			return "container"
		_:
			return "unknown"


func _build_behavior_line() -> String:
	var labels: Array[String] = []
	if can_use():
		labels.append("use")
	if can_open():
		labels.append("open")
	if can_read():
		labels.append("read")
	if can_hold_in_hands():
		labels.append("hold")
	if can_equip():
		labels.append("ready")
	if usable_as_tool():
		labels.append("tool")
	if usable_as_weapon():
		labels.append("weapon")
	if is_cook_ingredient():
		labels.append("ingredient")
	if labels.is_empty():
		return ""
	return "Actions: %s" % ", ".join(labels)


func _build_equip_line() -> String:
	var slot_labels: Array[String] = []
	for slot_id in get_valid_equip_slots():
		var label = _get_slot_label(StringName(slot_id))
		if label != "" and not slot_labels.has(label):
			slot_labels.append(label)
	if slot_labels.is_empty():
		return ""
	return "Hold slots: %s" % ", ".join(slot_labels)


func _build_tool_function_line() -> String:
	if cooking_max_uses <= 0 and carry_profile.strip_edges() == "":
		return ""
	var parts: Array[String] = []
	if cooking_max_uses > 0:
		parts.append("cooking uses %d" % cooking_max_uses)
	if not is_equal_approx(cooking_efficiency, 1.0):
		parts.append("efficiency %.2f" % cooking_efficiency)
	if not is_equal_approx(cooking_stability, 1.0):
		parts.append("stability %.2f" % cooking_stability)
	if carry_profile.strip_edges() != "":
		parts.append(carry_profile)
	return "Tool: %s" % ", ".join(parts)


func _get_slot_label(slot_id: StringName) -> String:
	match slot_id:
		SLOT_BACK:
			return "Back"
		SLOT_SHOULDER_L:
			return "Shoulder L"
		SLOT_SHOULDER_R:
			return "Shoulder R"
		SLOT_BELT_WAIST:
			return "Waist"
		SLOT_HAND_L:
			return "Hand L"
		SLOT_HAND_R:
			return "Hand R"
		SLOT_PANTS:
			return "Pants"
		SLOT_COAT:
			return "Coat"
		_:
			return ""
