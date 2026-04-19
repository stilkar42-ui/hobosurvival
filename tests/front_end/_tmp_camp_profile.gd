extends SceneTree
const CampLayerScene := preload("res://scenes/front_end/camp_isometric_play_layer.tscn")
func _init():
	var layer = CampLayerScene.instantiate()
	print("layer_instantiated=", layer != null)
	print("world_objects=", layer.get("_world_objects").size())
	quit()
