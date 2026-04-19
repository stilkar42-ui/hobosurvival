class_name SurvivalJobTemplate
extends Resource

@export var template_id: StringName
@export var title := ""
@export_multiline var summary := ""
@export var job_category: StringName = &"day_labor"
@export var decay_behavior: StringName = &"expire"
@export_range(0, 1000000, 1, "suffix:cents/day") var pay_decay_cents_per_day := 0
@export_range(0, 1000000, 1, "suffix:cents") var minimum_pay_cents := 0
@export var min_appearance_tier: StringName = &""
@export var max_appearance_tier: StringName = &""
@export var appearance_requirement_text := ""
@export_range(1, 100, 1) var weight := 10
@export_range(1, 720, 1, "suffix:min") var duration_minutes := 180
@export_range(0, 1000000, 1, "suffix:cents") var pay_cents := 0
@export_range(0, 100, 1) var nutrition_drain := 0
@export_range(-100, 100, 1) var fatigue_delta := 0
@export_range(-100, 100, 1) var morale_delta := 0
@export_range(-100, 100, 1) var hygiene_delta := 0
@export_range(0, 1439, 1, "suffix:min") var available_from_minutes := 360
@export_range(0, 1439, 1, "suffix:min") var available_until_minutes := 1080
@export var required_item_id: StringName = &""
@export var reward_item_id: StringName = &""
@export_range(0, 20, 1) var reward_item_quantity := 0
@export var can_persist := false
@export_range(0, 100, 1, "suffix:%") var persistence_chance_percent := 0
@export_range(1, 7, 1, "suffix:days") var persistent_days_min := 2
@export_range(1, 7, 1, "suffix:days") var persistent_days_max := 3
@export var fading_income_source: StringName = &"labor"


func is_valid_template() -> bool:
	return template_id != &"" and title.strip_edges() != "" and duration_minutes > 0 and weight > 0


func to_job_entry(current_day: int, instance_id: StringName, expires_on_day: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"template_id": template_id,
		"title": title,
		"summary": summary,
		"job_category": job_category,
		"decay_behavior": decay_behavior,
		"base_pay_cents": pay_cents,
		"pay_decay_cents_per_day": pay_decay_cents_per_day,
		"minimum_pay_cents": minimum_pay_cents,
		"min_appearance_tier": min_appearance_tier,
		"max_appearance_tier": max_appearance_tier,
		"appearance_requirement_text": appearance_requirement_text,
		"duration_minutes": duration_minutes,
		"pay_cents": pay_cents,
		"nutrition_drain": nutrition_drain,
		"fatigue_delta": fatigue_delta,
		"morale_delta": morale_delta,
		"hygiene_delta": hygiene_delta,
		"available_from_minutes": available_from_minutes,
		"available_until_minutes": available_until_minutes,
		"required_item_id": required_item_id,
		"reward_item_id": reward_item_id,
		"reward_item_quantity": reward_item_quantity,
		"fading_income_source": fading_income_source,
		"generated_day": current_day,
		"expires_on_day": expires_on_day,
		"persistent": expires_on_day > current_day
	}
