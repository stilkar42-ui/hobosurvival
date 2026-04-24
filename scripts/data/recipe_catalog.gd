class_name RecipeCatalog
extends RefCounted

const ALL_RECIPES := [
	{
		"recipe_id": &"soup_can_stove",
		"display_name": "Soup Can Stove",
		"category": "hobocraft",
		"display_category": "Fire & Heat",
		"summary": "A pierced tin stove for small fire and coffee work.",
		"output_item_id": &"soup_can_stove",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1},
			{"item_id": &"scrap_tin", "quantity": 1}
		]
	},
	{
		"recipe_id": &"repair_roll",
		"display_name": "Repair Roll",
		"category": "hobocraft",
		"display_category": "Repair",
		"summary": "Needle, thread, cloth, and cord kept together for road mending.",
		"output_item_id": &"repair_roll",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"needle_thread", "quantity": 1},
			{"item_id": &"cloth_patch", "quantity": 1},
			{"item_id": &"cordage", "quantity": 1}
		]
	},
	{
		"recipe_id": &"alarm_can_line",
		"display_name": "Alarm Can Line",
		"category": "hobocraft",
		"display_category": "Traps / Warning",
		"summary": "A tin-and-line warning rig for a nervous camp edge.",
		"output_item_id": &"alarm_can_line",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"cordage", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		]
	},
	{
		"recipe_id": &"road_cook_kit",
		"display_name": "Road Cook Kit",
		"category": "hobocraft",
		"display_category": "Food Prep",
		"summary": "A small camp cook bundle for boiling water and stretching staples.",
		"output_item_id": &"road_cook_kit",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"cordage", "quantity": 1},
			{"item_id": &"salt_pouch", "quantity": 1},
			{"item_id": &"dried_beans", "quantity": 1}
		]
	},
	{
		"recipe_id": &"tin_can_heater",
		"display_name": "Tin Can on a Stick",
		"category": "hobocraft",
		"display_category": "Fire & Heat",
		"summary": "A humble tin heater fixed to a dry kindling stick for warming small food over campfire coals.",
		"output_item_id": &"tin_can_heater",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1}
		]
	},
	{
		"recipe_id": &"wire_braced_tin_can_heater",
		"display_name": "Wire-Braced Tin Can on a Stick",
		"category": "hobocraft",
		"display_category": "Fire & Heat",
		"summary": "The same poor tin heater, steadied with baling wire when the store has some to spare.",
		"output_item_id": &"wire_braced_tin_can_heater",
		"output_quantity": 1,
		"inputs": [
			{"item_id": &"empty_can", "quantity": 1},
			{"item_id": &"dry_kindling", "quantity": 1},
			{"item_id": &"baling_wire", "quantity": 1}
		]
	},
	{
		"recipe_id": &"boil_water",
		"display_name": "Fetch / Boil Water",
		"category": "cooking",
		"display_category": "Water",
		"summary": "Fetches camp water if none is on hand, or boils non-potable water into potable water.",
		"inputs_text": "camp water source; fire preferred for boiling",
		"effects_text": "+non-potable water, or converts it to potable water"
	},
	{
		"recipe_id": &"brew_camp_coffee",
		"display_name": "Brew Camp Coffee",
		"category": "cooking",
		"display_category": "Drink",
		"summary": "Coffee made over the fire from bought grounds, water, and a tin. Cheaper than a counter cup.",
		"inputs_text": "coffee grounds + potable water + empty tin + fire",
		"effects_text": "adds hot coffee"
	},
	{
		"recipe_id": &"heat_beans",
		"display_name": "Heat Can of Beans",
		"category": "cooking",
		"display_category": "Hot Food",
		"summary": "Warm a can of beans over the fire and eat it hot instead of cold from the tin.",
		"inputs_text": "can of beans + fire + small cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; leaves an empty tin"
	},
	{
		"recipe_id": &"heat_potted_meat",
		"display_name": "Heat Potted Meat",
		"category": "cooking",
		"display_category": "Hot Food",
		"summary": "Warm preserved meat just enough to make a poor meal sit better.",
		"inputs_text": "potted meat tin + fire + small cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; leaves an empty tin"
	},
	{
		"recipe_id": &"mulligan_stew",
		"display_name": "Mulligan Stew",
		"category": "cooking",
		"display_category": "Camp Meal",
		"summary": "A flexible camp stew that stretches water, staples, and whatever small body the pack can spare.",
		"inputs_text": "potable water + one staple + one meat/fat/flavor support + fire + cooking tool",
		"effects_text": "+nutrition, +warmth, +morale; uses flexible substitutions"
	}
]


static func get_all_recipes() -> Array:
	var recipes: Array = []
	for recipe in ALL_RECIPES:
		recipes.append(_normalize_recipe(recipe))
	return recipes


static func get_recipe(recipe_id: StringName) -> Dictionary:
	for recipe in ALL_RECIPES:
		if StringName(recipe.get("recipe_id", &"")) == recipe_id:
			return _normalize_recipe(recipe)
	return {}


static func get_recipes_by_category(category: String) -> Array:
	var recipes: Array = []
	var normalized_category = category.to_lower().strip_edges()
	for recipe in ALL_RECIPES:
		if String(recipe.get("category", "")).to_lower().strip_edges() != normalized_category:
			continue
		recipes.append(_normalize_recipe(recipe))
	return recipes


static func _normalize_recipe(recipe: Dictionary) -> Dictionary:
	var normalized = recipe.duplicate(true)
	normalized["recipe_category"] = String(normalized.get("category", "")).to_lower().strip_edges()
	if String(normalized.get("display_category", "")).strip_edges() != "":
		normalized["category"] = String(normalized.get("display_category", ""))
	return normalized
