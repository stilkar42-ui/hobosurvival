class_name CampPlayerController
extends Node

signal position_changed(grid_position: Vector2i)
signal render_position_changed(render_position: Vector2)

const CARDINAL_DIRS := [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP
]
const STEP_DIRS := [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1)
]

var grid_position := Vector2i.ZERO
var render_position := Vector2.ZERO
var world_bounds := Rect2i(0, 0, 1, 1)
var blocked_tiles: Dictionary = {}
var step_interval := 0.10
var input_enabled := true

var _queued_path: Array = []
var _is_moving := false
var _move_from := Vector2.ZERO
var _move_to := Vector2.ZERO
var _move_elapsed := 0.0
var _intent_direction := Vector2i.ZERO
var _repeat_cooldown := 0.0


func _process(delta: float) -> void:
	if not input_enabled:
		return
	if _is_moving:
		_move_elapsed += delta
		var progress = minf(_move_elapsed / maxf(step_interval, 0.01), 1.0)
		progress = progress * progress * (3.0 - 2.0 * progress)
		render_position = _move_from.lerp(_move_to, progress)
		render_position_changed.emit(render_position)
		if progress >= 1.0:
			_finish_step()
		return
	if _queued_path.is_empty():
		if _intent_direction == Vector2i.ZERO:
			return
		_repeat_cooldown = maxf(_repeat_cooldown - delta, 0.0)
		if _repeat_cooldown > 0.0:
			return
		if request_step(_intent_direction):
			_repeat_cooldown = step_interval * 0.65
		else:
			_repeat_cooldown = 0.04
		return
	var next_tile: Vector2i = _queued_path[0]
	_queued_path.remove_at(0)
	_start_step(next_tile)
	_repeat_cooldown = maxf(_repeat_cooldown - delta, 0.0)
	if _intent_direction != Vector2i.ZERO and _repeat_cooldown <= 0.0 and request_step(_intent_direction):
		_repeat_cooldown = step_interval * 0.65
	elif _intent_direction != Vector2i.ZERO and _repeat_cooldown <= 0.0:
		_repeat_cooldown = 0.04


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		clear_path()
		_intent_direction = Vector2i.ZERO
		_repeat_cooldown = 0.0


func set_grid_position(new_grid_position: Vector2i) -> void:
	grid_position = new_grid_position
	render_position = Vector2(new_grid_position)
	clear_path()
	position_changed.emit(grid_position)
	render_position_changed.emit(render_position)


func set_navigation_data(bounds: Rect2i, new_blocked_tiles: Dictionary) -> void:
	world_bounds = bounds
	blocked_tiles = new_blocked_tiles.duplicate(true)
	blocked_tiles.erase(_tile_key(grid_position))


func clear_path() -> void:
	_queued_path.clear()
	_is_moving = false
	_move_elapsed = 0.0
	_move_from = render_position
	_move_to = render_position


func set_intent_direction(direction: Vector2i) -> void:
	_intent_direction = direction
	if direction == Vector2i.ZERO:
		_repeat_cooldown = 0.0
	else:
		_repeat_cooldown = 0.0


func request_step(direction: Vector2i) -> bool:
	if not input_enabled:
		return false
	var origin_tile = _get_navigation_origin_tile()
	var target_tile = origin_tile + direction
	if not _can_step_between(origin_tile, target_tile):
		return false
	_queued_path = [target_tile]
	return true


func request_path_to(target_tile: Vector2i) -> bool:
	if not input_enabled:
		return false
	var origin_tile = _get_navigation_origin_tile()
	if origin_tile == target_tile:
		return false
	var path = _build_path(origin_tile, target_tile)
	if path.is_empty():
		return false
	_queued_path = path
	return true


func can_enter_tile(tile: Vector2i) -> bool:
	if not world_bounds.has_point(tile):
		return false
	return not blocked_tiles.has(_tile_key(tile))


func _can_step_between(origin_tile: Vector2i, target_tile: Vector2i) -> bool:
	if not can_enter_tile(target_tile):
		return false
	var delta = target_tile - origin_tile
	if absi(delta.x) != 1 or absi(delta.y) != 1:
		return true
	var horizontal_tile = origin_tile + Vector2i(delta.x, 0)
	var vertical_tile = origin_tile + Vector2i(0, delta.y)
	return can_enter_tile(horizontal_tile) or can_enter_tile(vertical_tile)


func _build_path(start_tile: Vector2i, target_tile: Vector2i) -> Array:
	if start_tile == target_tile:
		return []
	if not can_enter_tile(target_tile):
		return []

	var frontier: Array = [start_tile]
	var came_from := {_tile_key(start_tile): start_tile}
	var found := false

	while not frontier.is_empty():
		var current: Vector2i = frontier[0]
		frontier.remove_at(0)
		if current == target_tile:
			found = true
			break
		for direction in _get_path_directions(current, target_tile):
			var candidate = current + direction
			var candidate_key = _tile_key(candidate)
			if came_from.has(candidate_key) or not _can_step_between(current, candidate):
				continue
			came_from[candidate_key] = current
			frontier.append(candidate)

	if not found:
		return []

	var reversed_path: Array = []
	var trace_tile = target_tile
	while trace_tile != start_tile:
		reversed_path.append(trace_tile)
		trace_tile = came_from.get(_tile_key(trace_tile), start_tile)
	reversed_path.reverse()
	return reversed_path


func _start_step(next_tile: Vector2i) -> void:
	_is_moving = true
	_move_elapsed = 0.0
	_move_from = render_position
	_move_to = Vector2(next_tile)


func _finish_step() -> void:
	_is_moving = false
	render_position = _move_to
	grid_position = Vector2i(roundi(render_position.x), roundi(render_position.y))
	position_changed.emit(grid_position)
	render_position_changed.emit(render_position)


func _get_navigation_origin_tile() -> Vector2i:
	if _is_moving:
		return Vector2i(roundi(_move_to.x), roundi(_move_to.y))
	if not _queued_path.is_empty():
		return _queued_path[_queued_path.size() - 1]
	return grid_position


func _get_path_directions(current: Vector2i, target_tile: Vector2i) -> Array:
	var preferred: Array = []
	var delta = target_tile - current
	var primary = Vector2i(signi(delta.x), signi(delta.y))
	if primary != Vector2i.ZERO:
		preferred.append(primary)
	if primary.x != 0:
		preferred.append(Vector2i(primary.x, 0))
	if primary.y != 0:
		preferred.append(Vector2i(0, primary.y))
	for direction in STEP_DIRS:
		if direction == Vector2i.ZERO or preferred.has(direction):
			continue
		preferred.append(direction)
	return preferred


func _tile_key(tile: Vector2i) -> String:
	return "%d:%d" % [tile.x, tile.y]
