class_name StorageProviderDefinition
extends Resource

enum AccessSpeed {
	TRAVEL,
	SLOW
}

enum MountSlot {
	NONE,
	BACK,
	LEFT_SHOULDER,
	RIGHT_SHOULDER,
	HANDS_CARRY
}

const SHOULDER_SIZE_SMALL := 1
const SHOULDER_SIZE_MEDIUM := 2

@export var provider_id: StringName = &""
@export var display_name := ""
@export var source_item_id: StringName = &""
@export var equipment_slot_id: StringName = &""
@export var mount_slot: MountSlot = MountSlot.NONE
@export_range(0, 2, 1) var shoulder_slots_required := 0
@export_range(0, 2, 1) var hand_carry_slots_required := 0
@export var access_speed: AccessSpeed = AccessSpeed.TRAVEL
@export_range(0.0, 4.0, 0.05) var fatigue_modifier := 0.0
@export_range(0.0, 4.0, 0.05) var awkward_carry_modifier := 0.0
var container_profile = null
@export var allowed_item_zones: PackedStringArray = PackedStringArray()


func is_valid_definition() -> bool:
	return provider_id != &"" and display_name.strip_edges() != "" and container_profile != null


func get_access_speed_name() -> String:
	if access_speed == AccessSpeed.TRAVEL:
		return "travel access"
	return "slow access"


func get_mount_label() -> String:
	match mount_slot:
		MountSlot.BACK:
			return "back"
		MountSlot.LEFT_SHOULDER:
			return "left shoulder"
		MountSlot.RIGHT_SHOULDER:
			return "right shoulder"
		MountSlot.HANDS_CARRY:
			return "hands carry"
		_:
			return "worn clothing"
