class_name ShopStockWidget
extends "res://scripts/ui/widgets/base_panel_widget.gd"

signal stock_selected(store_id, stock_index)
signal buy_requested(store_id, stock_index)

const DetailPanelWidgetScript := preload("res://scripts/ui/widgets/detail_panel_widget.gd")
const BasePanelWidgetScript := preload("res://scripts/ui/widgets/base_panel_widget.gd")

var _store_id: StringName = &""
var _entries: Array = []
var _selected_index := -1
var _summary_label: Label = null
var _stock_root: GridContainer = null
var _detail_widget = null


func _init() -> void:
	super._init()
	set_variant("dark")
	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_summary_label)
	get_content_root().add_child(_summary_label)

	var layout := HBoxContainer.new()
	layout.name = "ShopStockLayout"
	layout.add_theme_constant_override("separation", 12)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_content_root().add_child(layout)

	var stock_panel = BasePanelWidgetScript.new()
	stock_panel.name = "ShopStockList"
	stock_panel.set_title("Stock")
	stock_panel.set_variant("panel")
	stock_panel.custom_minimum_size = Vector2(360.0, 0.0)
	layout.add_child(stock_panel)

	_stock_root = GridContainer.new()
	_stock_root.columns = 2
	_stock_root.add_theme_constant_override("h_separation", 8)
	_stock_root.add_theme_constant_override("v_separation", 8)
	_stock_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stock_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stock_panel.get_content_root().add_child(_stock_root)

	_detail_widget = DetailPanelWidgetScript.new()
	_detail_widget.name = "ShopStockDetail"
	_detail_widget.set_title("Selected Stock", true)
	_detail_widget.set_variant("highlight")
	layout.add_child(_detail_widget)

	_detail_widget.set_detail_content(_make_buy_button(true))


func set_store_title(title: String, summary: String) -> void:
	set_title(title, true)
	_summary_label.text = summary


func set_stock_items(store_id: StringName, entries: Array, selected_index := 0) -> void:
	_store_id = store_id
	_entries = entries.duplicate(true)
	if _entries.is_empty():
		_selected_index = -1
	else:
		_selected_index = clampi(selected_index, 0, _entries.size() - 1)
	_rebuild_stock_buttons()
	_refresh_detail()


func get_stock_count() -> int:
	return _entries.size()


func get_selected_stock_index() -> int:
	if _selected_index < 0 or _selected_index >= _entries.size():
		return -1
	var entry = _entries[_selected_index]
	return int(entry.get("stock_index", _selected_index)) if entry is Dictionary else _selected_index


func _rebuild_stock_buttons() -> void:
	for child in _stock_root.get_children():
		_stock_root.remove_child(child)
		child.queue_free()
	if _entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No stock available."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		PageUIThemeScript.style_body_label(empty_label, true)
		_stock_root.add_child(empty_label)
		return
	for index in range(_entries.size()):
		var entry = _entries[index]
		if not (entry is Dictionary):
			continue
		var button := Button.new()
		button.text = String(entry.get("button_text", entry.get("title", "Stock")))
		button.tooltip_text = String(entry.get("tooltip_text", entry.get("description", "")))
		button.disabled = not bool(entry.get("enabled", true))
		button.custom_minimum_size = Vector2(0.0, 58.0)
		PageUIThemeScript.style_button(button, index == _selected_index)
		button.pressed.connect(Callable(self, "_on_stock_button_pressed").bind(index))
		_stock_root.add_child(button)


func _refresh_detail() -> void:
	_detail_widget.clear_detail_content()
	if _selected_index < 0 or _selected_index >= _entries.size():
		_detail_widget.set_detail({
			"title": "No Stock Selected",
			"summary": "No usable stock came in this week.",
			"blocks": []
		})
		_detail_widget.set_detail_content(_make_buy_button(true))
		return
	var entry = _entries[_selected_index]
	if not (entry is Dictionary):
		return
	_detail_widget.set_detail({
		"title": String(entry.get("title", "Stock")),
		"summary": String(entry.get("description", "")),
		"blocks": entry.get("detail_lines", [])
	})
	_detail_widget.set_detail_content(_make_buy_button(not bool(entry.get("enabled", true))))


func _make_buy_button(disabled: bool) -> Button:
	var buy_button := Button.new()
	buy_button.text = "Buy Stock"
	buy_button.custom_minimum_size = Vector2(0.0, 48.0)
	buy_button.disabled = disabled
	PageUIThemeScript.style_button(buy_button, true)
	buy_button.pressed.connect(Callable(self, "_on_buy_pressed"))
	return buy_button


func _on_stock_button_pressed(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_selected_index = index
	_rebuild_stock_buttons()
	_refresh_detail()
	stock_selected.emit(_store_id, get_selected_stock_index())


func _on_buy_pressed() -> void:
	var stock_index = get_selected_stock_index()
	if stock_index < 0:
		return
	buy_requested.emit(_store_id, stock_index)
