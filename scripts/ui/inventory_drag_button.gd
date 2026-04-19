class_name InventoryDragButton
extends Button

var drag_payload: Dictionary = {}


func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty():
		return null

	var preview = Label.new()
	preview.text = text
	preview.modulate = Color("eadcc8")
	preview.add_theme_font_size_override("font_size", 14)
	set_drag_preview(preview)
	return drag_payload.duplicate(true)
