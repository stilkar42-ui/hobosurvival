class_name FeatureWindowWidget
extends PanelContainer

signal closed

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _root: VBoxContainer = null
var _title_bar: PanelContainer = null
var _title_label: Label = null
var _content_scroll: ScrollContainer = null
var _content_root: VBoxContainer = null
var _dragging := false
var _drag_offset := Vector2.ZERO


func _init() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	PageUIThemeScript.apply_panel_variant(self, "panel")

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_root)

	_title_bar = PanelContainer.new()
	_title_bar.name = "FeatureWindowTitleBar"
	_title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	PageUIThemeScript.apply_panel_variant(_title_bar, "dark")
	_title_bar.gui_input.connect(Callable(self, "_on_title_bar_gui_input"))
	_root.add_child(_title_bar)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_bar.add_child(title_row)

	_title_label = Label.new()
	_title_label.name = "FeatureWindowTitle"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	PageUIThemeScript.style_section_label(_title_label, true)
	title_row.add_child(_title_label)

	var close_button := Button.new()
	close_button.name = "FeatureWindowCloseButton"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(84.0, 36.0)
	PageUIThemeScript.style_button(close_button, false)
	close_button.pressed.connect(Callable(self, "_on_close_pressed"))
	title_row.add_child(close_button)

	_content_scroll = ScrollContainer.new()
	_content_scroll.name = "FeatureWindowContentScroll"
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.custom_minimum_size = Vector2.ZERO
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(_content_scroll)

	_content_root = VBoxContainer.new()
	_content_root.name = "FeatureWindowContent"
	_content_root.add_theme_constant_override("separation", 8)
	_content_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_root)


func set_window_title(title_text: String) -> void:
	_title_label.text = title_text


func set_window_size(window_size: Vector2) -> void:
	custom_minimum_size = window_size
	size = window_size
	clamp_to_parent()


func get_content_root() -> VBoxContainer:
	return _content_root


func clear_content() -> void:
	for child in _content_root.get_children():
		_content_root.remove_child(child)
		child.queue_free()


func _process(_delta: float) -> void:
	if visible:
		clamp_to_parent()


func center_in_parent() -> void:
	var parent_control = get_parent() as Control
	if parent_control == null:
		return
	var parent_size = parent_control.get_rect().size
	var window_size = size
	if window_size == Vector2.ZERO:
		window_size = custom_minimum_size
	position = (parent_size - window_size) * 0.5
	clamp_to_parent()


func clamp_to_parent() -> void:
	var parent_control = get_parent() as Control
	if parent_control == null:
		return
	var parent_size = parent_control.get_rect().size
	var window_size = size
	if window_size == Vector2.ZERO:
		window_size = custom_minimum_size
	if parent_size.x > 0.0 and parent_size.y > 0.0:
		window_size = Vector2(min(window_size.x, parent_size.x), min(window_size.y, parent_size.y))
		size = window_size
		custom_minimum_size = window_size
	var max_position = Vector2(
		max(parent_size.x - window_size.x, 0.0),
		max(parent_size.y - window_size.y, 0.0)
	)
	position = Vector2(
		clampf(position.x, 0.0, max_position.x),
		clampf(position.y, 0.0, max_position.y)
	)


func _on_title_bar_gui_input(event: InputEvent) -> void:
	var mouse_button = event as InputEventMouseButton
	if mouse_button != null and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		_dragging = mouse_button.pressed
		if _dragging:
			_drag_offset = mouse_button.global_position - global_position
		return
	var mouse_motion = event as InputEventMouseMotion
	if mouse_motion != null and _dragging:
		global_position = mouse_motion.global_position - _drag_offset
		clamp_to_parent()


func _on_close_pressed() -> void:
	closed.emit()
