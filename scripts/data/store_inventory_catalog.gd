class_name StoreInventoryCatalog
extends RefCounted

const ItemDefinitionScript := preload("res://scripts/inventory/item_definition.gd")

const STORE_GROCERY := &"grocery"
const STORE_HARDWARE := &"hardware"
const STORE_GENERAL := &"general_store"
const STORE_MEDICINE := &"medicine"
const STORE_SPECIALIST_GROCERY := &"specialist_grocery"
const STORE_SPECIALIST_HARDWARE := &"specialist_hardware"
const STORE_SPECIALIST_MEDICINE := &"specialist_medicine"

const LEGENDARY_STOCK_POLICY := "Legendary goods never appear in ordinary rotating store stock; they are quested, crafted, gifted, found, or story-earned."

const GROCERY_STOCK_POOL := [
	{"item_id": &"bread_loaf", "base_price_cents": 16, "weight": 12, "min_quality": 0, "max_quality": 2},
	{"item_id": &"beans_can", "base_price_cents": 30, "weight": 10, "min_quality": 0, "max_quality": 2},
	{"item_id": &"potted_meat", "base_price_cents": 24, "weight": 9, "min_quality": 0, "max_quality": 2},
	{"item_id": &"coffee_grounds", "base_price_cents": 6, "weight": 11, "min_quality": 0, "max_quality": 2},
	{"item_id": &"oats_sack", "base_price_cents": 10, "weight": 8, "min_quality": 0, "max_quality": 2},
	{"item_id": &"dried_beans", "base_price_cents": 12, "weight": 8, "min_quality": 0, "max_quality": 2},
	{"item_id": &"salt_pouch", "base_price_cents": 5, "weight": 6, "min_quality": 0, "max_quality": 2},
	{"item_id": &"lard_tin", "base_price_cents": 18, "weight": 5, "min_quality": 0, "max_quality": 2}
]

const HARDWARE_STOCK_POOL := [
	{"item_id": &"match_safe", "base_price_cents": 14, "weight": 10, "min_quality": 0, "max_quality": 2},
	{"item_id": &"empty_can", "base_price_cents": 3, "weight": 12, "min_quality": 0, "max_quality": 2},
	{"item_id": &"cordage", "base_price_cents": 12, "weight": 11, "min_quality": 0, "max_quality": 2},
	{"item_id": &"scrap_tin", "base_price_cents": 5, "weight": 8, "min_quality": 0, "max_quality": 1},
	{"item_id": &"baling_wire", "base_price_cents": 9, "weight": 8, "min_quality": 0, "max_quality": 2},
	{"item_id": &"church_key", "base_price_cents": 7, "weight": 5, "min_quality": 0, "max_quality": 2},
	{"item_id": &"box_nails", "base_price_cents": 8, "weight": 6, "min_quality": 0, "max_quality": 2},
	{"item_id": &"cloth_patch", "base_price_cents": 7, "weight": 7, "min_quality": 0, "max_quality": 2},
	{"item_id": &"needle_thread", "base_price_cents": 11, "weight": 6, "min_quality": 0, "max_quality": 2}
]

const GENERAL_STOCK_POOL := [
	{"item_id": &"bread_loaf", "base_price_cents": 16, "weight": 10, "min_quality": 0, "max_quality": 2},
	{"item_id": &"coffee_grounds", "base_price_cents": 6, "weight": 8, "min_quality": 0, "max_quality": 2},
	{"item_id": &"dried_beans", "base_price_cents": 12, "weight": 8, "min_quality": 0, "max_quality": 2},
	{"item_id": &"match_safe", "base_price_cents": 14, "weight": 6, "min_quality": 0, "max_quality": 2},
	{"item_id": &"cordage", "base_price_cents": 12, "weight": 6, "min_quality": 0, "max_quality": 2},
	{"item_id": &"clean_rag_bundle", "base_price_cents": 8, "weight": 6, "min_quality": 0, "max_quality": 2},
	{"item_id": &"bandage_roll", "base_price_cents": 16, "weight": 4, "min_quality": 1, "max_quality": 2},
	{"item_id": &"carbolic_soap", "base_price_cents": 18, "weight": 4, "min_quality": 1, "max_quality": 2}
]

const MEDICINE_STOCK_POOL := [
	{"item_id": &"clean_rag_bundle", "base_price_cents": 8, "weight": 12, "min_quality": 0, "max_quality": 2},
	{"item_id": &"bandage_roll", "base_price_cents": 16, "weight": 11, "min_quality": 1, "max_quality": 2},
	{"item_id": &"carbolic_soap", "base_price_cents": 18, "weight": 10, "min_quality": 1, "max_quality": 2},
	{"item_id": &"iodine_bottle", "base_price_cents": 28, "weight": 8, "min_quality": 1, "max_quality": 3},
	{"item_id": &"healing_salve", "base_price_cents": 22, "weight": 8, "min_quality": 0, "max_quality": 3},
	{"item_id": &"foot_powder", "base_price_cents": 20, "weight": 7, "min_quality": 1, "max_quality": 3},
	{"item_id": &"liniment_bottle", "base_price_cents": 32, "weight": 6, "min_quality": 1, "max_quality": 3},
	{"item_id": &"headache_powder", "base_price_cents": 10, "weight": 6, "min_quality": 0, "max_quality": 2},
	{"item_id": &"cough_syrup", "base_price_cents": 26, "weight": 5, "min_quality": 1, "max_quality": 3},
	{"item_id": &"patent_tonic", "base_price_cents": 30, "weight": 4, "min_quality": 0, "max_quality": 2}
]

const REQUIRED_STOCK_ITEM_IDS := {
	STORE_GROCERY: [&"coffee_grounds", &"beans_can", &"potted_meat"],
	STORE_HARDWARE: [&"baling_wire"],
	STORE_MEDICINE: [&"clean_rag_bundle", &"bandage_roll", &"carbolic_soap"]
}

const STORE_POOLS := {
	STORE_GROCERY: GROCERY_STOCK_POOL,
	STORE_HARDWARE: HARDWARE_STOCK_POOL,
	STORE_GENERAL: GENERAL_STOCK_POOL,
	STORE_MEDICINE: MEDICINE_STOCK_POOL,
	STORE_SPECIALIST_GROCERY: [],
	STORE_SPECIALIST_HARDWARE: [],
	STORE_SPECIALIST_MEDICINE: []
}

const STORE_PROFILES := {
	STORE_GROCERY: {
		"store_id": STORE_GROCERY,
		"display_name": "Grocery Store",
		"stock_status": "active",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.COMMON, ItemDefinitionScript.QualityTier.GOOD],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.POOR],
			"rare_tiers": [],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.SUPERIOR, ItemDefinitionScript.QualityTier.EXCEPTIONAL, ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "Basic grocery stock is mostly common/decent staples, with occasional poor goods and no ordinary legendary stock."
		},
		"supply_tags": [&"food", &"staples", &"coffee", &"camp_food"],
		"service_tags": [&"rotating_stock"],
		"merchant_tags": [&"town_basic"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"weekly",
		"future_manager_notes": "Future StoreManager may vary grocery stock by town, season, merchant reliability, and reputation."
	},
	STORE_HARDWARE: {
		"store_id": STORE_HARDWARE,
		"display_name": "Hardware Store",
		"stock_status": "active",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.COMMON, ItemDefinitionScript.QualityTier.GOOD],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.POOR],
			"rare_tiers": [],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.SUPERIOR, ItemDefinitionScript.QualityTier.EXCEPTIONAL, ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "Basic hardware stock is mostly common/decent camp utility, with occasional poor repair goods and no ordinary legendary stock."
		},
		"supply_tags": [&"tools", &"containers", &"wire", &"repair", &"camp_utility"],
		"service_tags": [&"rotating_stock"],
		"merchant_tags": [&"town_basic"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"weekly",
		"future_manager_notes": "Future StoreManager may vary hardware stock by town industry, rail access, merchant relationship, and regional scarcity."
	},
	STORE_GENERAL: {
		"store_id": STORE_GENERAL,
		"display_name": "General Store",
		"stock_status": "active",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.COMMON],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.POOR],
			"rare_tiers": [ItemDefinitionScript.QualityTier.GOOD],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "General stores carry limited crossover grocery, hardware, and medicine stock in restricted quantities; no treatment mechanics are attached."
		},
		"supply_tags": [&"crossover_stock", &"food", &"hardware", &"medicine"],
		"service_tags": [&"rotating_stock"],
		"merchant_tags": [&"town_basic"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"weekly",
		"future_manager_notes": "Future StoreManager may vary general store crossover stock by town, season, merchant reliability, and reputation."
	},
	STORE_MEDICINE: {
		"store_id": STORE_MEDICINE,
		"display_name": "Medicine / Apothecary",
		"stock_status": "prepared_catalog_pool",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.COMMON, ItemDefinitionScript.QualityTier.GOOD],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.POOR],
			"rare_tiers": [ItemDefinitionScript.QualityTier.SUPERIOR],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "Prepared medicine stock includes bandages, clean rags, salves, antiseptic, tonic, headache powder, foot powder, liniment, cough syrup, and patent medicine. These are inventory goods only until treatment rules exist."
		},
		"supply_tags": [&"medical", &"apothecary", &"doctor_supply"],
		"service_tags": [&"prepared_medical_stock"],
		"merchant_tags": [&"apothecary", &"doctor_supply"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"prepared_weekly",
		"future_manager_notes": "Medicine goods are catalog-prepared here but are not generated into runtime state yet; do not add treatment, addiction, sickness, or doctor-service mechanics in this catalog."
	},
	STORE_SPECIALIST_GROCERY: {
		"store_id": STORE_SPECIALIST_GROCERY,
		"display_name": "Specialist Grocery",
		"stock_status": "future_profile_only",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.GOOD, ItemDefinitionScript.QualityTier.SUPERIOR],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.COMMON],
			"rare_tiers": [ItemDefinitionScript.QualityTier.EXCEPTIONAL],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "Future specialist grocery stock should be narrower, more expensive, and potentially town/reputation gated."
		},
		"supply_tags": [&"specialist_food", &"higher_grade_staples"],
		"service_tags": [&"future_specialist_stock"],
		"merchant_tags": [&"specialist"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"future_event_or_weekly",
		"future_manager_notes": "Future StoreManager can gate specialist grocery access by town wealth, relationship, event, or reputation."
	},
	STORE_SPECIALIST_HARDWARE: {
		"store_id": STORE_SPECIALIST_HARDWARE,
		"display_name": "Specialist Hardware",
		"stock_status": "future_profile_only",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.GOOD, ItemDefinitionScript.QualityTier.SUPERIOR],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.COMMON],
			"rare_tiers": [ItemDefinitionScript.QualityTier.EXCEPTIONAL],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "Future specialist hardware stock should be narrower, more durable, expensive, and event/reputation gated."
		},
		"supply_tags": [&"specialist_tools", &"repair", &"camp_utility"],
		"service_tags": [&"future_specialist_stock"],
		"merchant_tags": [&"specialist"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"future_event_or_weekly",
		"future_manager_notes": "Future StoreManager can attach persistent merchant inventories and relationship-based tool access here."
	},
	STORE_SPECIALIST_MEDICINE: {
		"store_id": STORE_SPECIALIST_MEDICINE,
		"display_name": "Specialist Medicine",
		"stock_status": "future_profile_only",
		"quality_policy": {
			"dominant_tiers": [ItemDefinitionScript.QualityTier.GOOD, ItemDefinitionScript.QualityTier.SUPERIOR],
			"occasional_tiers": [ItemDefinitionScript.QualityTier.COMMON],
			"rare_tiers": [ItemDefinitionScript.QualityTier.EXCEPTIONAL],
			"excluded_tiers": [ItemDefinitionScript.QualityTier.LEGENDARY],
			"notes": "Future specialist medicine should be stronger, rarer, and service-gated rather than ordinary rotating stock."
		},
		"supply_tags": [&"specialist_medical", &"doctor_supply"],
		"service_tags": [&"future_specialist_medical_stock"],
		"merchant_tags": [&"doctor_supply", &"specialist"],
		"region_tags": [],
		"reputation_hooks": [],
		"relationship_hooks": [],
		"restock_cadence": &"future_event_or_weekly",
		"future_manager_notes": "Future StoreManager can connect doctor services, town quality gates, and medical supply access here without making this catalog own treatment rules."
	}
}


static func get_store_pool(store_id: StringName) -> Array:
	return _duplicate_dictionary_array(STORE_POOLS.get(store_id, []))


static func get_required_stock_item_ids(store_id: StringName) -> Array:
	return Array(REQUIRED_STOCK_ITEM_IDS.get(store_id, [])).duplicate()


static func get_supported_store_ids() -> Array:
	return [
		STORE_GROCERY,
		STORE_HARDWARE,
		STORE_GENERAL,
		STORE_MEDICINE,
		STORE_SPECIALIST_GROCERY,
		STORE_SPECIALIST_HARDWARE,
		STORE_SPECIALIST_MEDICINE
	]


static func get_store_display_name(store_id: StringName) -> String:
	var profile = get_store_profile(store_id)
	return String(profile.get("display_name", String(store_id).replace("_", " ").capitalize()))


static func get_store_profile(store_id: StringName) -> Dictionary:
	return Dictionary(STORE_PROFILES.get(store_id, {})).duplicate(true)


static func _duplicate_dictionary_array(entries: Array) -> Array:
	var duplicated: Array = []
	for entry in entries:
		if entry is Dictionary:
			duplicated.append(entry.duplicate(true))
	return duplicated
