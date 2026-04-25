class_name SurvivalLoopConfig
extends Resource

# Phase 1 loop tuning lives here so balance can move without rewriting logic.
@export_range(1, 3650, 1) var day_limit := 28
@export_range(0, 1000000, 1, "suffix:cents") var support_goal_cents := 1500
@export_range(0, 1000000, 1, "suffix:cents") var starter_money_cents := 140
@export_range(1, 1000000, 1) var job_generation_seed := 1931
@export_range(0, 1439, 1, "suffix:min") var day_start_minutes := 390
@export_range(0, 1439, 1, "suffix:min") var sleep_rough_unlock_minutes := 1080
@export_range(0, 100, 1) var emergency_sleep_fatigue_threshold := 82
@export_range(0, 1439, 1, "suffix:min") var sleep_rough_window_start_minutes := 1140
@export_range(0, 1439, 1, "suffix:min") var sleep_rough_window_end_minutes := 240
@export_range(0, 100, 1) var rest_anytime_stamina_threshold := 25
@export_range(1, 240, 1, "suffix:min") var wait_action_minutes := 30
@export_range(1, 360, 1, "suffix:min") var item_use_minutes := 10
@export_range(1, 720, 1, "suffix:min") var buy_supply_minutes := 20
@export_range(1, 720, 1, "suffix:min") var prepared_food_purchase_minutes := 5
@export_range(1, 720, 1, "suffix:min") var send_support_minutes := 30
@export_range(1, 720, 1, "suffix:min") var doctor_clean_up_minutes := 25
@export_range(1, 720, 1, "suffix:min") var doctor_foot_care_minutes := 30
@export_range(1, 720, 1, "suffix:min") var doctor_tonic_advice_minutes := 15
@export_range(1, 720, 1, "suffix:min") var doctor_basic_checkup_minutes := 35
@export_range(1, 720, 1, "suffix:min") var town_to_camp_travel_minutes := 35
@export_range(1, 720, 1, "suffix:min") var camp_to_town_travel_minutes := 35
@export_range(1, 240, 1, "suffix:min") var passive_nutrition_minutes_per_point := 45
@export_range(1, 240, 1, "suffix:min") var passive_fatigue_minutes_per_point := 60
@export_range(0, 100, 1) var work_block_nutrition_threshold := 20
@export_range(0, 100, 1) var work_block_fatigue_threshold := 80
@export_range(0, 100, 1) var low_warmth_threshold := 25
@export_range(0, 100, 1) var low_morale_threshold := 20
@export_range(1, 6, 1) var min_jobs_per_day := 1
@export_range(1, 6, 1) var max_jobs_per_day := 4
@export_range(0, 100, 1, "suffix:%") var weekly_job_rotation_drop_chance_percent := 35
@export var appearance_tiers: Array = [
	{"tier_id": &"filthy_unkept", "label": "Filthy / Unkept", "rank": 0},
	{"tier_id": &"disheveled", "label": "Disheveled", "rank": 1},
	{"tier_id": &"grimey", "label": "Grimey", "rank": 2},
	{"tier_id": &"presentable", "label": "Presentable", "rank": 3},
	{"tier_id": &"well_kept", "label": "Clean / Well Kept", "rank": 4}
]
@export var appearance_rules: Array = [
	{"tier_id": &"well_kept", "min_hygiene": 70, "max_hygiene": 100, "min_presentability": 70, "max_presentability": 100},
	{"tier_id": &"presentable", "min_hygiene": 45, "max_hygiene": 100, "min_presentability": 45, "max_presentability": 100},
	{"tier_id": &"grimey", "min_hygiene": 0, "max_hygiene": 44, "min_presentability": 45, "max_presentability": 100},
	{"tier_id": &"disheveled", "min_hygiene": 45, "max_hygiene": 100, "min_presentability": 0, "max_presentability": 44},
	{"tier_id": &"filthy_unkept", "min_hygiene": 0, "max_hygiene": 44, "min_presentability": 0, "max_presentability": 44}
]
@export var job_templates: Array = []

@export_group("Trade")
@export_range(1, 720, 1, "suffix:min") var sell_scrap_minutes := 45
@export_range(1, 20, 1) var sell_scrap_quantity := 2
@export_range(0, 1000000, 1, "suffix:cents") var sell_scrap_pay_cents := 26

@export_group("Supplies")
@export var bread_item_id: StringName = &"bread_loaf"
@export_range(0, 1000000, 1, "suffix:cents") var bread_price_cents := 16
@export var coffee_item_id: StringName = &"hot_coffee"
@export_range(0, 1000000, 1, "suffix:cents") var coffee_price_cents := 14
@export var stew_item_id: StringName = &"stew_tin"
@export_range(0, 1000000, 1, "suffix:cents") var stew_price_cents := 44
@export var tobacco_item_id: StringName = &"smoke_tobacco"
@export_range(0, 1000000, 1, "suffix:cents") var tobacco_price_cents := 18
@export var grocery_beans_item_id: StringName = &"beans_can"
@export_range(0, 1000000, 1, "suffix:cents") var grocery_beans_price_cents := 30
@export var grocery_potted_meat_item_id: StringName = &"potted_meat"
@export_range(0, 1000000, 1, "suffix:cents") var grocery_potted_meat_price_cents := 24
@export var grocery_coffee_grounds_item_id: StringName = &"coffee_grounds"
@export_range(0, 1000000, 1, "suffix:cents") var grocery_coffee_grounds_price_cents := 6
@export var hardware_matches_item_id: StringName = &"match_safe"
@export_range(0, 1000000, 1, "suffix:cents") var hardware_matches_price_cents := 14
@export var hardware_empty_can_item_id: StringName = &"empty_can"
@export_range(0, 1000000, 1, "suffix:cents") var hardware_empty_can_price_cents := 3
@export var hardware_cordage_item_id: StringName = &"cordage"
@export_range(0, 1000000, 1, "suffix:cents") var hardware_cordage_price_cents := 12
@export_range(1, 365, 1, "suffix:days") var store_refresh_days_per_week := 7
@export_range(1, 1000000, 1) var store_stock_seed := 1937
@export_range(4, 8, 1) var min_store_stock_items := 4
@export_range(4, 8, 1) var max_store_stock_items := 8
@export_range(1, 720, 1, "suffix:min") var hobocraft_action_minutes := 35

@export_group("Doctor / Apothecary")
@export_range(0, 1000000, 1, "suffix:cents") var doctor_clean_up_cost_cents := 18
@export_range(0, 1000000, 1, "suffix:cents") var doctor_foot_care_cost_cents := 32
@export_range(0, 1000000, 1, "suffix:cents") var doctor_tonic_advice_cost_cents := 22
@export_range(0, 1000000, 1, "suffix:cents") var doctor_basic_checkup_cost_cents := 40
@export_range(0, 100, 1) var doctor_clean_up_hygiene_gain := 16
@export_range(0, 100, 1) var doctor_clean_up_presentability_gain := 6
@export_range(0, 100, 1) var doctor_clean_up_dampness_relief := 4
@export_range(0, 100, 1) var doctor_foot_care_dampness_relief := 10
@export_range(0, 100, 1) var doctor_foot_care_fatigue_relief := 5
@export_range(-100, 100, 1) var doctor_foot_care_morale_gain := 2
@export_range(0, 100, 1) var doctor_tonic_advice_fatigue_relief := 2
@export_range(-100, 100, 1) var doctor_tonic_advice_morale_gain := 4
@export_range(0, 100, 1) var doctor_basic_checkup_hygiene_gain := 1
@export_range(0, 100, 1) var doctor_basic_checkup_presentability_gain := 1
@export_range(-100, 100, 1) var doctor_basic_checkup_morale_gain := 5

@export_group("Support")
@export_range(0, 1000000, 1, "suffix:cents") var send_small_amount_cents := 375
@export_range(0, 1000000, 1, "suffix:cents") var send_large_amount_cents := 750
@export_range(-100, 100, 1) var send_support_morale_gain := 6
@export_range(-100, 100, 1) var support_obligation_hit_morale_gain := 2
@export_range(-100, 100, 1) var support_obligation_miss_morale_penalty := -4
@export_range(-100, 100, 1) var monthly_support_failure_morale_penalty := -8
@export_range(0, 1000000, 1, "suffix:cents") var monthly_support_target_cents := 1500
@export var support_obligation_defaults: Array = [
	{"obligation_id": &"week_1", "label": "Week 1", "checkpoint_day": 7, "target_cents": 375},
	{"obligation_id": &"week_2", "label": "Week 2", "checkpoint_day": 14, "target_cents": 375},
	{"obligation_id": &"week_3", "label": "Week 3", "checkpoint_day": 21, "target_cents": 375},
	{"obligation_id": &"week_4", "label": "Week 4", "checkpoint_day": 28, "target_cents": 375}
]
@export var support_send_methods: Array = [
	{"method_id": &"mail", "display_name": "Mail", "fee_cents": 5, "delivery_delay_days": 2},
	{"method_id": &"telegraph", "display_name": "Telegraph", "fee_cents": 25, "delivery_delay_days": 0}
]

@export_group("Rest")
@export_range(1, 12, 1, "suffix:hrs") var sleep_rough_hours := 8
@export_range(0, 100, 1) var sleep_rough_fatigue_recovery := 32
@export_range(0, 100, 1) var sleep_rough_nutrition_drain := 12
@export_range(0, 100, 1) var sleep_rough_warmth_loss := 30
@export_range(-100, 100, 1) var sleep_rough_morale := -10
@export_range(0, 100, 1) var blanket_warmth_buffer := 14
@export_range(0, 100, 1) var blanket_fatigue_bonus := 6
@export_range(0, 100, 1) var low_warmth_extra_fatigue := 10
@export_range(-100, 100, 1) var low_warmth_morale_penalty := -5
@export_range(0, 100, 1) var no_fire_extra_warmth_loss := 12
@export_range(-100, 100, 1) var no_fire_extra_morale_penalty := -4
@export_range(0, 100, 1) var fire_warmth_buffer := 18
@export_range(0, 100, 1) var fire_fatigue_bonus := 8
@export_range(-100, 100, 1) var fire_morale_bonus := 4
@export_range(0, 100, 1) var tended_fire_warmth_buffer := 26
@export_range(0, 100, 1) var tended_fire_fatigue_bonus := 12
@export_range(-100, 100, 1) var tended_fire_morale_bonus := 7

@export_group("Camp Fire")
@export_range(1, 720, 1, "suffix:min") var build_fire_minutes := 45
@export_range(1, 720, 1, "suffix:min") var tend_fire_minutes := 25
@export_range(0, 1439, 1, "suffix:min") var camp_prep_unlock_minutes := 960
@export_range(-100, 100, 1) var build_fire_morale_gain := 2
@export_range(-100, 100, 1) var tend_fire_morale_gain := 2
@export_range(1, 20, 1) var tend_fire_scrap_cost := 1

@export_group("Camp Prep")
@export_range(1, 720, 1, "suffix:min") var prepare_sleeping_spot_minutes := 20
@export_range(1, 720, 1, "suffix:min") var lay_bedroll_minutes := 15
@export_range(1, 720, 1, "suffix:min") var wash_up_minutes := 20
@export_range(1, 720, 1, "suffix:min") var quiet_comfort_minutes := 25
@export_range(-100, 100, 1) var prepare_sleeping_spot_morale_gain := 1
@export_range(-100, 100, 1) var lay_bedroll_morale_gain := 2
@export_range(0, 100, 1) var sleeping_spot_warmth_buffer := 5
@export_range(0, 100, 1) var sleeping_spot_fatigue_bonus := 5
@export_range(0, 100, 1) var laid_bedroll_warmth_buffer := 16
@export_range(0, 100, 1) var laid_bedroll_fatigue_bonus := 8
@export_range(0, 100, 1) var wash_up_hygiene_gain := 14
@export_range(-100, 100, 1) var wash_up_morale_gain := 2
@export_range(-100, 100, 1) var wash_up_warmth_delta := -2
@export_range(-100, 100, 1) var quiet_comfort_morale_gain := 4
@export_range(0, 100, 1) var quiet_comfort_fatigue_relief := 2
@export_range(1, 720, 1, "suffix:min") var gather_kindling_minutes := 20
@export var gather_kindling_item_id: StringName = &"dry_kindling"
@export_range(1, 10, 1) var gather_kindling_quantity := 1
@export_range(0, 100, 1) var gather_kindling_fatigue_delta := 2
@export_range(-100, 100, 1) var gather_kindling_morale_gain := 1
@export_range(1, 720, 1, "suffix:min") var brew_camp_coffee_minutes := 25
@export var brew_camp_coffee_input_item_id: StringName = &"coffee_grounds"
@export var brew_camp_coffee_water_item_id: StringName = &"clean_water"
@export var brew_camp_coffee_output_item_id: StringName = &"hot_coffee"
@export var brew_camp_coffee_tool_item_id: StringName = &"empty_can"
@export_range(-100, 100, 1) var brew_camp_coffee_morale_gain := 1

@export_group("Getting Ready")
@export_range(1, 720, 1, "suffix:min") var ready_fetch_water_minutes := 15
@export_range(1, 720, 1, "suffix:min") var ready_boil_water_minutes := 20
@export var ready_fetch_water_item_id: StringName = &"non_potable_water"
@export var ready_potable_water_item_id: StringName = &"clean_water"
@export_range(1, 10, 1) var ready_fetch_water_quantity := 1
@export_range(-100, 100, 1) var ready_fetch_water_morale_gain := 1
@export_range(1, 720, 1, "suffix:min") var ready_wash_body_minutes := 10
@export_range(0, 100, 1) var ready_wash_body_hygiene_gain := 25
@export_range(0, 100, 1) var ready_wash_body_presentability_gain := 10
@export_range(0, 100, 1) var ready_wash_body_fatigue_delta := 5
@export_range(-100, 100, 1) var ready_wash_body_morale_gain := 1
@export_range(-100, 100, 1) var ready_wash_body_warmth_delta := -2
@export_range(1, 720, 1, "suffix:min") var ready_wash_face_hands_minutes := 5
@export_range(0, 100, 1) var ready_wash_face_hands_hygiene_gain := 8
@export_range(0, 100, 1) var ready_wash_face_hands_presentability_gain := 8
@export_range(0, 100, 1) var ready_wash_face_hands_fatigue_delta := 1
@export_range(-100, 100, 1) var ready_wash_face_hands_morale_gain := 1
@export_range(1, 720, 1, "suffix:min") var ready_shave_minutes := 8
@export_range(0, 100, 1) var ready_shave_hygiene_gain := 2
@export_range(0, 100, 1) var ready_shave_presentability_gain := 12
@export_range(0, 100, 1) var ready_shave_fatigue_delta := 1
@export_range(-100, 100, 1) var ready_shave_morale_gain := 1
@export_range(1, 720, 1, "suffix:min") var ready_comb_groom_minutes := 3
@export_range(0, 100, 1) var ready_comb_groom_hygiene_gain := 0
@export_range(0, 100, 1) var ready_comb_groom_presentability_gain := 8
@export_range(0, 100, 1) var ready_comb_groom_fatigue_delta := 0
@export_range(-100, 100, 1) var ready_comb_groom_morale_gain := 1
@export_range(1, 720, 1, "suffix:min") var ready_air_out_clothes_minutes := 15
@export_range(0, 100, 1) var ready_air_out_clothes_hygiene_gain := 5
@export_range(0, 100, 1) var ready_air_out_clothes_presentability_gain := 8
@export_range(0, 100, 1) var ready_air_out_clothes_fatigue_delta := 1
@export_range(-100, 100, 1) var ready_air_out_clothes_morale_gain := 1
@export_range(-100, 100, 1) var ready_air_out_clothes_warmth_delta := -1
@export_range(1, 720, 1, "suffix:min") var ready_brush_clothes_minutes := 6
@export_range(0, 100, 1) var ready_brush_clothes_hygiene_gain := 2
@export_range(0, 100, 1) var ready_brush_clothes_presentability_gain := 10
@export_range(0, 100, 1) var ready_brush_clothes_fatigue_delta := 1
@export_range(-100, 100, 1) var ready_brush_clothes_morale_gain := 1

@export_group("Markets")
@export_range(0, 1439, 1, "suffix:min") var sell_scrap_start_minutes := 480
@export_range(0, 1439, 1, "suffix:min") var sell_scrap_end_minutes := 1080

@export_group("Fading")
@export_range(1, 7, 1, "suffix:days") var fade_history_days := 3
@export_range(0.0, 5.0, 0.05) var fade_gain_multiplier := 1.0
@export_range(0.0, 5.0, 0.05) var fade_recovery_multiplier := 0.5
@export_range(-20, 20, 1) var fade_daily_delta_min := -6
@export_range(-20, 20, 1) var fade_daily_delta_max := 8
@export_range(0, 100, 1) var fade_fraying_threshold := 25
@export_range(0, 100, 1) var fade_slipping_threshold := 50
@export_range(0, 100, 1) var fade_lost_threshold := 75
@export_range(0, 100, 1) var fade_collapse_threshold := 100
@export_range(0, 1000000, 1, "suffix:cents") var fade_meaningful_support_threshold_cents := 60
@export_range(0, 1000000, 1, "suffix:cents") var fade_dignified_labor_pay_threshold_cents := 90
@export_range(0, 100, 1) var fade_good_hygiene_threshold := 50
@export_range(-5, 5, 1) var fade_good_sleep_quality_threshold := 2
@export_range(-5, 5, 1) var fade_poor_sleep_quality_threshold := -1
@export_range(1, 7, 1, "suffix:days") var fade_support_neglect_days := 3
@export_range(1, 7, 1, "suffix:days") var fade_low_morale_days := 2
@export_range(1, 7, 1, "suffix:days") var fade_poor_sleep_days := 2
@export_range(1, 7, 1, "suffix:days") var fade_isolation_days := 2
@export_range(1, 5, 1) var fade_comfort_use_threshold := 2
@export_range(0, 10, 1) var fade_honest_labor_recovery := 2
@export_range(0, 10, 1) var fade_dignified_labor_bonus := 1
@export_range(0, 10, 1) var fade_support_recovery := 2
@export_range(0, 10, 1) var fade_meaningful_support_bonus := 1
@export_range(0, 10, 1) var fade_social_recovery := 1
@export_range(0, 10, 1) var fade_self_maintenance_recovery := 1
@export_range(0, 10, 1) var fade_good_sleep_recovery := 1
@export_range(0, 10, 1) var fade_scrounge_gain := 2
@export_range(0, 10, 1) var fade_road_food_gain := 1
@export_range(0, 10, 1) var fade_comfort_dependency_gain := 1
@export_range(0, 10, 1) var fade_poor_sleep_gain := 2
@export_range(0, 10, 1) var fade_unsafe_sleep_gain := 1
@export_range(0, 10, 1) var fade_low_morale_gain := 2
@export_range(0, 10, 1) var fade_isolation_gain := 1
@export_range(0, 10, 1) var fade_support_neglect_gain := 2
@export_range(0, 10, 1) var fade_chronic_low_morale_gain := 2
@export_range(0, 10, 1) var fade_repeated_poor_sleep_gain := 2

@export_group("Fading Morale Hooks")
@export_range(-20, 20, 1) var fade_steady_morale_delta := 0
@export_range(-20, 20, 1) var fade_fraying_morale_delta := 0
@export_range(-20, 20, 1) var fade_slipping_morale_delta := -1
@export_range(-20, 20, 1) var fade_lost_morale_delta := -3
@export_range(-20, 20, 1) var fade_collapse_morale_delta := -6
