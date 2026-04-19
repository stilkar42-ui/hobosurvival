extends SceneTree
func _init():
	var source := TileSetAtlasSource.new()
	print('has_create_tile=', source.has_method('create_tile'))
	print('has_set_texture_region_size=', source.has_method('set_texture_region_size'))
	print('has_get_runtime_texture=', source.has_method('get_runtime_texture'))
	quit()
