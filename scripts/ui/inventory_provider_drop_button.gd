class_name InventoryProviderDropButton
extends Button

var provider_id: StringName = &""
var inventory_panel: Node = null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var result = _preview_drop(data)
	var accepted = bool(result.get("success", false))
	_update_drop_tint(accepted, not result.is_empty())
	return accepted


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_update_drop_tint(false, false)
	if inventory_panel != null and inventory_panel.has_method("request_move_for_drag"):
		inventory_panel.call("request_move_for_drag", data, provider_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_update_drop_tint(false, false)


func _preview_drop(data: Variant) -> Dictionary:
	if inventory_panel == null or not inventory_panel.has_method("preview_move_for_drag"):
		return {}
	return inventory_panel.call("preview_move_for_drag", data, provider_id)


func _update_drop_tint(accepted: bool, has_payload: bool) -> void:
	if not has_payload:
		modulate = Color.WHITE
	elif accepted:
		modulate = Color("d8efd2")
	else:
		modulate = Color("efc8c2")
