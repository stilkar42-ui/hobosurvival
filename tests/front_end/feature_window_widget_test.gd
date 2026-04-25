extends SceneTree

const FeatureWindowWidgetScript := preload("res://scripts/ui/widgets/feature_window_widget.gd")

var _failed := false
var _closed := false


func _init() -> void:
	var root = Window.new()
	root.name = "FeatureWindowWidgetTestRoot"
	root.size = Vector2i(900, 560)
	get_root().add_child(root)

	var parent = Control.new()
	parent.name = "WindowBounds"
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(parent)

	var widget = FeatureWindowWidgetScript.new()
	widget.name = "TestFeatureWindow"
	widget.closed.connect(Callable(self, "_on_window_closed"))
	parent.add_child(widget)
	call_deferred("_run_checks", parent, widget)


func _run_checks(parent: Control, widget) -> void:
	await process_frame
	widget.set_window_title("Town Service")
	widget.set_window_size(Vector2(520.0, 340.0))
	widget.center_in_parent()

	var content_root = widget.get_content_root()
	_expect(content_root != null, "feature window exposes a content root")
	var label := Label.new()
	label.name = "InsertedContent"
	label.text = "Window content"
	content_root.add_child(label)
	await process_frame

	_expect(widget.is_visible_in_tree(), "feature window is visible")
	_expect(_control_has_label_text(widget, "Town Service"), "feature window renders title")
	_expect(widget.find_child("InsertedContent", true, false) != null, "feature window accepts content children")
	_expect(_rect_inside(parent.get_global_rect(), widget.get_global_rect()), "feature window starts inside parent bounds")

	widget.position = Vector2(-140.0, -90.0)
	widget.clamp_to_parent()
	await process_frame
	_expect(_rect_inside(parent.get_global_rect(), widget.get_global_rect()), "feature window clamps negative position inside parent bounds")

	var close_button = _find_button_with_text(widget, "Close")
	_expect(close_button != null, "feature window exposes close button")
	if close_button != null:
		close_button.emit_signal("pressed")
		await process_frame
		_expect(_closed, "feature window emits closed signal")

	quit(1 if _failed else 0)


func _on_window_closed() -> void:
	_closed = true


func _find_button_with_text(root: Node, needle: String) -> Button:
	for child in root.find_children("*", "Button", true, false):
		var button = child as Button
		if button != null and button.text.find(needle) != -1:
			return button
	return null


func _control_has_label_text(root: Node, needle: String) -> bool:
	for child in root.find_children("*", "Label", true, false):
		var label = child as Label
		if label != null and label.visible and label.text.find(needle) != -1:
			return true
	return false


func _rect_inside(parent_rect: Rect2, child_rect: Rect2) -> bool:
	return child_rect.position.x >= parent_rect.position.x \
		and child_rect.position.y >= parent_rect.position.y \
		and child_rect.end.x <= parent_rect.end.x \
		and child_rect.end.y <= parent_rect.end.y


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
