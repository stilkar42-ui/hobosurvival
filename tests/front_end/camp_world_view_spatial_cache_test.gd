extends SceneTree

const CampWorldViewScript := preload("res://scripts/front_end/camp_world_view.gd")
const CampWorldObjectScript := preload("res://scripts/front_end/camp_world_object.gd")

var _failed := false


func _init() -> void:
	var view = CampWorldViewScript.new()
	view.size = Vector2(1280, 720)
	view.set_world_size(Vector2i(20, 20))
	view.set_player_render_position(Vector2(10, 10))
	view.set_camp_anchor(Vector2i(10, 10))

	var stash = CampWorldObjectScript.new({
		"id": &"stash",
		"position": Vector2i(11, 10),
		"type": &"stash",
		"interaction_type": &"ui",
		"display_name": "Ground Stash"
	})
	var wash_line = CampWorldObjectScript.new({
		"id": &"wash_line",
		"position": Vector2(12.5, 9),
		"type": &"wash_line",
		"interaction_type": &"page",
		"size_tiles": Vector2i(2, 1),
		"display_name": "Wash Line"
	})
	view.set_world_objects([stash, wash_line])

	_expect(view.has_method("has_cached_occupied_tile"), "camp world view exposes cached occupancy lookup")
	_expect(view.has_method("get_cached_interactable_objects"), "camp world view exposes cached interactable lookup for hit testing")
	_expect(bool(view.call("has_cached_occupied_tile", Vector2i(11, 10))), "occupied tile cache recognizes single-tile objects")
	_expect(bool(view.call("has_cached_occupied_tile", Vector2i(13, 9))), "occupied tile cache recognizes multi-tile objects")
	_expect(bool(view.call("has_cached_occupied_tile", Vector2i(12, 9))), "bottom-center anchor expands multi-tile footprints back to the left edge tile")
	_expect(not bool(view.call("has_cached_occupied_tile", Vector2i(5, 5))), "occupied tile cache leaves empty ground unblocked")
	_expect(view.call("get_cached_interactable_objects").size() == 2, "interactable cache retains clickable camp objects")

	var stash_id = StringName(view.call("_get_object_id_at_point", view.call("_world_to_screen", Vector2(11, 10))))
	_expect(stash_id == &"stash", "object hit testing still resolves the stash")

	var wash_line_id = StringName(view.call("_get_object_id_at_point", view.call("_world_to_screen", Vector2(12.5, 9))))
	_expect(wash_line_id == &"wash_line", "object hit testing still resolves the wash line")

	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
