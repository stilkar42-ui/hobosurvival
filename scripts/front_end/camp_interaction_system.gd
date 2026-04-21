class_name CampInteractionSystem
extends Node

signal prompt_changed(title: String, detail: String, object_id: StringName)
signal interaction_requested(payload: Dictionary)

const CARDINAL_DIRS := [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]

var player_grid_position := Vector2i.ZERO
var world_objects: Array = []
var default_prompt_title := "Walk the clearing with arrow keys or WASD. Click the ground or an object to move there."
var default_prompt_detail := "Stand beside the fire, bedroll, stash, or tool area to act in camp."

var _active_object_id: StringName = &""
var _interactable_objects: Array = []
var _world_object_by_id := {}


func set_world_objects(new_world_objects: Array) -> void:
	world_objects = new_world_objects
	_rebuild_cache()
	_refresh_active_object()


func set_player_grid_position(new_player_grid_position: Vector2i) -> void:
	player_grid_position = new_player_grid_position
	_refresh_active_object()


func set_default_prompt(title: String, detail: String) -> void:
	default_prompt_title = title
	default_prompt_detail = detail
	if _active_object_id == &"":
		prompt_changed.emit(default_prompt_title, default_prompt_detail, &"")


func get_active_object_id() -> StringName:
	return _active_object_id


func is_player_adjacent_to_object(object_id: StringName) -> bool:
	var world_object = _get_world_object(object_id)
	return world_object != null and _is_tile_adjacent_to_object(player_grid_position, world_object)


func request_active_interaction() -> void:
	if _active_object_id == &"":
		return
	request_object_interaction(_active_object_id)


func request_object_interaction(object_id: StringName) -> void:
	var world_object = _get_world_object(object_id)
	if world_object == null or not world_object.is_interactable:
		return
	if not _is_tile_adjacent_to_object(player_grid_position, world_object):
		return
	interaction_requested.emit(world_object.get_interaction_payload())


func get_interaction_tiles(object_id: StringName) -> Array:
	var world_object = _get_world_object(object_id)
	if world_object == null:
		return []
	var candidates: Array = []
	var seen := {}
	for occupied_tile in world_object.get_occupied_tiles():
		for direction in CARDINAL_DIRS:
			var candidate = occupied_tile + direction
			var key = _tile_key(candidate)
			if seen.has(key):
				continue
			seen[key] = true
			candidates.append(candidate)
	return candidates


func _refresh_active_object() -> void:
	var best_object = null
	var best_distance := 100000
	for world_object in _interactable_objects:
		if not _is_tile_adjacent_to_object(player_grid_position, world_object):
			continue
		var distance = _distance_to_object(player_grid_position, world_object)
		if best_object == null or distance < best_distance:
			best_object = world_object
			best_distance = distance

	var next_object_id: StringName = &"" if best_object == null else best_object.id
	if next_object_id == _active_object_id:
		return
	_active_object_id = next_object_id
	if best_object == null:
		prompt_changed.emit(default_prompt_title, default_prompt_detail, &"")
		return
	prompt_changed.emit(
		"Press E to %s" % best_object.prompt_action,
		best_object.detail_text,
		best_object.id
	)


func _get_world_object(object_id: StringName):
	return _world_object_by_id.get(object_id, null)


func _distance_to_object(tile: Vector2i, world_object) -> int:
	var best_distance := 100000
	for occupied_tile in world_object.get_occupied_tiles():
		var distance = absi(tile.x - occupied_tile.x) + absi(tile.y - occupied_tile.y)
		if distance < best_distance:
			best_distance = distance
	return best_distance


func _is_tile_adjacent_to_object(tile: Vector2i, world_object) -> bool:
	for occupied_tile in world_object.get_occupied_tiles():
		if tile == occupied_tile:
			return false
	for occupied_tile in world_object.get_occupied_tiles():
		var distance = absi(tile.x - occupied_tile.x) + absi(tile.y - occupied_tile.y)
		if distance == 1:
			return true
	return false


func _tile_key(tile: Vector2i) -> String:
	return "%d:%d" % [tile.x, tile.y]


func _rebuild_cache() -> void:
	_interactable_objects.clear()
	_world_object_by_id.clear()
	for world_object in world_objects:
		if world_object == null:
			continue
		_world_object_by_id[world_object.id] = world_object
		if world_object.is_interactable:
			_interactable_objects.append(world_object)
