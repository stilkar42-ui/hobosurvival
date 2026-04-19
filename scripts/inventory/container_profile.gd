class_name ContainerProfile
extends Resource

@export var container_id: StringName
@export var display_name := ""
@export_range(0, 24, 1) var medium_slots := 0
@export_range(0, 96, 1) var small_capacity := 0
@export_range(0, 24, 1) var overflow_small_capacity := 0
@export_range(0.5, 2.0, 0.05) var organization_modifier := 1.0
@export_range(0.0, 80.0, 0.1, "suffix:kg") var max_weight_kg := 0.0


func get_effective_small_capacity() -> int:
	return max(floori(float(small_capacity) * organization_modifier), 0) + overflow_small_capacity


func get_capacity_label() -> String:
	return "%s: %d medium / %d small equivalent (+%d overflow) / %.1f kg" % [
		display_name,
		medium_slots,
		max(floori(float(small_capacity) * organization_modifier), 0),
		overflow_small_capacity,
		max_weight_kg
	]
