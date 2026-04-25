extends SceneTree

const ShopStockWidgetScript := preload("res://scripts/ui/widgets/shop_stock_widget.gd")

var _failed := false
var _selected_store: StringName = &""
var _selected_index := -1
var _buy_store: StringName = &""
var _buy_index := -1


func _init() -> void:
	var root = Window.new()
	root.name = "ShopStockWidgetTestRoot"
	root.size = Vector2i(900, 520)
	get_root().add_child(root)

	var widget = ShopStockWidgetScript.new()
	widget.name = "TestShopStockWidget"
	widget.stock_selected.connect(Callable(self, "_on_stock_selected"))
	widget.buy_requested.connect(Callable(self, "_on_buy_requested"))
	root.add_child(widget)
	call_deferred("_run_checks", widget)


func _run_checks(widget) -> void:
	await process_frame
	widget.set_store_title("Test Store", "A compact stock list with a selected detail pane.")
	widget.set_stock_items(&"grocery", [
		{
			"stock_index": 0,
			"title": "Common Beans",
			"button_text": "Beans\n$0.12",
			"description": "A plain tin of beans.",
			"detail_lines": ["Quality: Common", "Price: $0.12"],
			"enabled": true
		},
		{
			"stock_index": 1,
			"title": "Good Soap",
			"button_text": "Soap\n$0.18",
			"description": "Clean enough to matter.",
			"detail_lines": ["Quality: Good", "Price: $0.18"],
			"enabled": true
		}
	], 0)
	await process_frame

	_expect(widget.get_stock_count() == 2, "shop widget renders stock entries")
	_expect(widget.get_selected_stock_index() == 0, "shop widget selects the first stock entry by default")
	_expect(_control_has_label_text(widget, "Common Beans"), "shop widget shows the selected detail title")

	var soap_button = _find_button_with_text(widget, "Soap")
	_expect(soap_button != null, "shop widget exposes a selectable stock button")
	if soap_button != null:
		soap_button.emit_signal("pressed")
		await process_frame
		_expect(_selected_store == &"grocery" and _selected_index == 1, "shop widget emits selected stock index")
		_expect(_control_has_label_text(widget, "Good Soap"), "shop widget updates the detail pane after selection")

	var buy_button = _find_button_with_text(widget, "Buy Stock")
	_expect(buy_button != null and not buy_button.disabled, "shop widget exposes an enabled buy button for selected stock")
	if buy_button != null:
		buy_button.emit_signal("pressed")
		await process_frame
		_expect(_buy_store == &"grocery" and _buy_index == 1, "shop widget emits buy request for selected stock")

	widget.set_stock_items(&"hardware", [], 0)
	await process_frame
	_expect(widget.get_stock_count() == 0, "shop widget accepts empty stock")
	_expect(widget.get_selected_stock_index() == -1, "empty stock has no selected index")
	_expect(_control_has_label_text(widget, "No Stock Selected"), "empty stock shows a clear empty state")
	buy_button = _find_button_with_text(widget, "Buy Stock")
	_expect(buy_button != null and buy_button.disabled, "empty stock disables buy action")

	quit(1 if _failed else 0)


func _on_stock_selected(store_id: StringName, stock_index: int) -> void:
	_selected_store = store_id
	_selected_index = stock_index


func _on_buy_requested(store_id: StringName, stock_index: int) -> void:
	_buy_store = store_id
	_buy_index = stock_index


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed = true
	push_error("FAIL: %s" % message)
