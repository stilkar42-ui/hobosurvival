class_name PlayerStateRuntime
extends RefCounted

const SERVICE_NAME := "PlayerStateService"
const PlayerStateServiceScript := preload("res://scripts/player/player_state_service.gd")


static func get_or_create_service(context: Node):
	if context == null or context.get_tree() == null:
		return null

	var tree = context.get_tree()
	var root = tree.root
	if root == null:
		return null

	var current_scene = tree.current_scene
	if current_scene != null:
		var scene_service = current_scene.get_node_or_null(SERVICE_NAME)
		if scene_service != null:
			if scene_service.has_method("ensure_bootstrapped"):
				scene_service.ensure_bootstrapped()
			return scene_service

	var existing_service = root.get_node_or_null(SERVICE_NAME)
	if existing_service != null:
		if existing_service.has_method("ensure_bootstrapped"):
			existing_service.ensure_bootstrapped()
		return existing_service

	var service = PlayerStateServiceScript.new()
	service.name = SERVICE_NAME
	if current_scene != null:
		current_scene.add_child(service)
	else:
		root.add_child(service)
	if service.has_method("ensure_bootstrapped"):
		service.ensure_bootstrapped()
	return service
