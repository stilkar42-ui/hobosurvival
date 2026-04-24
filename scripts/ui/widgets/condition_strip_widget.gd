class_name ConditionStripWidget
extends "res://scripts/ui/widgets/base_panel_widget.gd"

const ConditionStatWidgetScript := preload("res://scripts/ui/widgets/condition_stat_widget.gd")

var _grid: GridContainer = null
var _columns := 2


func _init() -> void:
	super._init()
	_grid = GridContainer.new()
	_grid.columns = _columns
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_content_root().add_child(_grid)


func set_columns(columns: int) -> void:
	_columns = max(columns, 1)
	if _grid != null:
		_grid.columns = _columns


func set_conditions(conditions: Array) -> void:
	clear_conditions()
	for entry in conditions:
		if not (entry is Dictionary):
			continue
		var widget = ConditionStatWidgetScript.new()
		widget.set_stat_data(entry)
		_grid.add_child(widget)


func clear_conditions() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
