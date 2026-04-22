class_name EntityManager
extends RefCounted

const InteractionRegistryScript := preload("res://scripts/front_end/adapters/interaction_registry.gd")


func build_camp_interactions(game_state_gateway, player_state, config, page_ids: Dictionary, format_duration: Callable) -> Array:
	return InteractionRegistryScript.build_camp_interactions(game_state_gateway, player_state, config, page_ids, format_duration)


func build_town_interactions(game_state_gateway, config, page_ids: Dictionary, format_duration: Callable) -> Array:
	return InteractionRegistryScript.build_town_interactions(game_state_gateway, config, page_ids, format_duration)


func apply_route_bindings(world_objects: Array, interaction_by_route: Dictionary) -> void:
	InteractionRegistryScript.apply_route_bindings(world_objects, interaction_by_route)


func default_binding_for_route(route_id: StringName) -> Dictionary:
	return InteractionRegistryScript.default_binding_for_route(route_id)


func resolve_prompt_action(route_id: StringName, label: String) -> String:
	return InteractionRegistryScript.resolve_prompt_action(route_id, label)
