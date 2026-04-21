class_name CampGroundTilemapLayer
extends TileMapLayer

const TILE_WIDTH_PX := 128.0
const TILE_HEIGHT_PX := 64.0
const RUNTIME_SCREEN_TILE_WIDTH := 72.0
const RUNTIME_SCREEN_TILE_HEIGHT := 36.0

const SOURCE_BASE := 0
const SOURCE_TRANSITION := 1
const SOURCE_SCATTER := 2

const BASE_ATLAS_PATH := "res://assets/tilesets/environment/first_pass/atlases/env_ground_base_a01_placeholder.png"
const TRANSITION_ATLAS_PATH := "res://assets/tilesets/environment/first_pass/atlases/env_ground_transition_a01_placeholder.png"
const SCATTER_ATLAS_PATH := "res://assets/tilesets/environment/first_pass/atlases/env_scatter_overlays_a01_placeholder.png"

const TILE_DIRT_COMPACT := [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0)
]
const TILE_DIRT_TRAMPLED := [
	Vector2i(3, 0),
	Vector2i(4, 0),
	Vector2i(5, 0)
]
const TILE_GRASS_SPARSE := [
	Vector2i(6, 0),
	Vector2i(7, 0),
	Vector2i(0, 1)
]
const TILE_FOREST_LITTER := [
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(3, 1)
]
const TILE_CAMP_FOOTPRINT := [
	Vector2i(4, 1),
	Vector2i(5, 1)
]

var _world_bounds := Rect2i(0, 0, 1, 1)
var _camp_center := Vector2i.ZERO


func _ready() -> void:
	z_index = -20
	y_sort_enabled = false
	scale = Vector2(
		RUNTIME_SCREEN_TILE_WIDTH / TILE_WIDTH_PX,
		RUNTIME_SCREEN_TILE_HEIGHT / TILE_HEIGHT_PX
	)
	if tile_set == null:
		tile_set = _build_runtime_tileset()


func setup_ground(world_bounds: Rect2i, camp_center: Vector2i) -> void:
	_world_bounds = world_bounds
	_camp_center = camp_center
	if tile_set == null:
		tile_set = _build_runtime_tileset()
	clear()
	for y in range(_world_bounds.position.y, _world_bounds.end.y):
		for x in range(_world_bounds.position.x, _world_bounds.end.x):
			var tile = Vector2i(x, y)
			var atlas_coords = _resolve_ground_atlas_coords(tile)
			set_cell(tile, SOURCE_BASE, atlas_coords, 0)


func sync_to_player(render_position: Vector2, viewport_size: Vector2, camera_position: Vector2 = render_position) -> void:
	position = viewport_size * 0.5 - _map_vector_to_local(camera_position) * scale


func _build_runtime_tileset() -> TileSet:
	var runtime_tileset = TileSet.new()
	runtime_tileset.tile_size = Vector2i(int(TILE_WIDTH_PX), int(TILE_HEIGHT_PX))
	runtime_tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	runtime_tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_RIGHT
	runtime_tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL

	var base_source = TileSetAtlasSource.new()
	base_source.texture = _load_runtime_texture(BASE_ATLAS_PATH)
	base_source.texture_region_size = Vector2i(int(TILE_WIDTH_PX), int(TILE_HEIGHT_PX))
	for atlas_coords in TILE_DIRT_COMPACT + TILE_DIRT_TRAMPLED + TILE_GRASS_SPARSE + TILE_FOREST_LITTER + TILE_CAMP_FOOTPRINT:
		base_source.create_tile(atlas_coords)
	runtime_tileset.add_source(base_source, SOURCE_BASE)

	var transition_source = TileSetAtlasSource.new()
	transition_source.texture = _load_runtime_texture(TRANSITION_ATLAS_PATH)
	transition_source.texture_region_size = Vector2i(int(TILE_WIDTH_PX), int(TILE_HEIGHT_PX))
	for atlas_coords in [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)
	]:
		transition_source.create_tile(atlas_coords)
	runtime_tileset.add_source(transition_source, SOURCE_TRANSITION)

	var scatter_source = TileSetAtlasSource.new()
	scatter_source.texture = _load_runtime_texture(SCATTER_ATLAS_PATH)
	scatter_source.texture_region_size = Vector2i(int(TILE_WIDTH_PX), int(TILE_HEIGHT_PX))
	for atlas_coords in [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)
	]:
		scatter_source.create_tile(atlas_coords)
	runtime_tileset.add_source(scatter_source, SOURCE_SCATTER)

	return runtime_tileset


func _load_runtime_texture(resource_path: String) -> Texture2D:
	var image = Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _resolve_ground_atlas_coords(tile: Vector2i) -> Vector2i:
	var distance_from_camp = Vector2(tile - _camp_center).length()
	var path_distance = _distance_to_path(Vector2(tile), Vector2(_camp_center), Vector2(_camp_center + Vector2i(11, -10)))
	if path_distance < 1.2 and distance_from_camp > 4.0:
		return _pick_variant(TILE_DIRT_TRAMPLED, tile)
	if distance_from_camp <= 7.5:
		return _pick_variant(TILE_CAMP_FOOTPRINT, tile)
	if distance_from_camp <= 10.5:
		return _pick_variant(TILE_DIRT_COMPACT, tile)
	if distance_from_camp <= 16.0:
		return _pick_variant(TILE_GRASS_SPARSE, tile)
	return _pick_variant(TILE_FOREST_LITTER, tile)


func _pick_variant(variants: Array, tile: Vector2i) -> Vector2i:
	var index = int(floor(_hash01(tile.x, tile.y) * float(variants.size())))
	index = clampi(index, 0, variants.size() - 1)
	return variants[index]


func _map_vector_to_local(grid_position: Vector2) -> Vector2:
	return Vector2(
		(grid_position.x - grid_position.y) * TILE_WIDTH_PX * 0.5,
		(grid_position.x + grid_position.y) * TILE_HEIGHT_PX * 0.5
	)


func _hash01(x: int, y: int) -> float:
	var value = int((x * 73856093) ^ (y * 19349663))
	value = abs(value % 1000)
	return float(value) / 999.0


func _distance_to_path(point: Vector2, path_start: Vector2, path_end: Vector2) -> float:
	var segment = path_end - path_start
	if segment.length_squared() <= 0.001:
		return point.distance_to(path_start)
	var progress = clampf((point - path_start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(path_start + segment * progress)
