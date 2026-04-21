class_name CampWorldObject
extends RefCounted

var id: StringName = &""
var position: Vector2i = Vector2i.ZERO
var type: StringName = &""
var interaction_type: StringName = &""
var route_id: StringName = &""
var display_name := ""
var prompt_action := ""
var action_id: StringName = &""
var page_id: StringName = &""
var size_tiles: Vector2i = Vector2i.ONE
var blocks_movement := true
var is_interactable := true
var detail_text := ""


func _init(config: Dictionary = {}) -> void:
	id = StringName(config.get("id", id))
	position = config.get("position", position)
	type = StringName(config.get("type", type))
	interaction_type = StringName(config.get("interaction_type", interaction_type))
	route_id = StringName(config.get("route_id", route_id))
	display_name = String(config.get("display_name", display_name))
	prompt_action = String(config.get("prompt_action", prompt_action))
	action_id = StringName(config.get("action_id", action_id))
	page_id = StringName(config.get("page_id", page_id))
	size_tiles = config.get("size_tiles", size_tiles)
	blocks_movement = bool(config.get("blocks_movement", blocks_movement))
	is_interactable = bool(config.get("is_interactable", is_interactable))
	detail_text = String(config.get("detail_text", detail_text))


func get_occupied_tiles() -> Array:
	var tiles: Array = []
	for y in range(max(size_tiles.y, 1)):
		for x in range(max(size_tiles.x, 1)):
			tiles.append(position + Vector2i(x, y))
	return tiles


func get_interaction_payload() -> Dictionary:
	return {
		"id": id,
		"position": position,
		"type": type,
		"interaction_type": interaction_type,
		"route_id": route_id,
		"display_name": display_name,
		"prompt_action": prompt_action,
		"action_id": action_id,
		"page_id": page_id,
		"detail_text": detail_text
	}
