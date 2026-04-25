class_name ConditionStatWidget
extends PanelContainer

signal selected(stat_id)

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var _stat_id: StringName = &""
var _interactive := false
var _selected := false
var _compact_mode := false
var _root: VBoxContainer = null
var _header: HBoxContainer = null
var _label: Label = null
var _value: Label = null
var _note: Label = null
var _bar: ProgressBar = null
var _bar_should_show := false
var _bar_mode: StringName = &"positive"


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 4)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_root)

	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 8)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_header)

	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_section_label(_label)
	_header.add_child(_label)

	_value = Label.new()
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	PageUIThemeScript.style_body_label(_value, true)
	_header.add_child(_value)

	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.visible = false
	PageUIThemeScript.style_small_label(_note)
	_root.add_child(_note)

	_bar = ProgressBar.new()
	_bar.name = "ConditionStatBar"
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.custom_minimum_size = Vector2(0.0, 10.0)
	_bar.min_value = 0.0
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.visible = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar)

	_apply_visual_state()


func set_stat_data(data: Dictionary) -> void:
	_stat_id = StringName(data.get("stat_id", data.get("field_id", &"")))
	_label.text = String(data.get("label", "Condition"))
	_value.text = String(data.get("value_text", data.get("value", "-")))

	var note_text = String(data.get("note", "")).strip_edges()
	_note.text = note_text
	_note.visible = note_text != "" and not _compact_mode

	var show_bar = bool(data.get("display_as_bar", false))
	var current_value = float(data.get("current", 0.0))
	var max_value = max(float(data.get("max", 100.0)), 1.0)
	_bar_should_show = show_bar
	_bar_mode = StringName(data.get("bar_mode", &"positive"))
	_bar.visible = _bar_should_show
	_bar.max_value = max_value
	_bar.value = clampf(current_value, 0.0, max_value)
	_bar.add_theme_stylebox_override("background", _make_panel_style(Color("2b241d"), Color("5f4e3c"), 1, 4))
	_bar.add_theme_stylebox_override("fill", _make_panel_style(_get_bar_color(_bar.value / _bar.max_value, _bar_mode), Color(0.0, 0.0, 0.0, 0.0), 0, 4))
	tooltip_text = String(data.get("tooltip_text", note_text))
	_apply_compact_mode()


func set_compact_mode(enabled: bool) -> void:
	_compact_mode = enabled
	_apply_compact_mode()


func set_interactive(interactive: bool) -> void:
	_interactive = interactive
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW


func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_visual_state()


func _gui_input(event: InputEvent) -> void:
	if not _interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		selected.emit(_stat_id)


func _apply_visual_state() -> void:
	PageUIThemeScript.apply_panel_variant(self, "highlight" if _selected else "alt")


func _apply_compact_mode() -> void:
	if _root == null:
		return
	custom_minimum_size = Vector2.ZERO
	_root.add_theme_constant_override("separation", 1 if _compact_mode else 4)
	_header.add_theme_constant_override("separation", 4 if _compact_mode else 8)
	_label.add_theme_font_size_override("font_size", 13 if _compact_mode else 18)
	_value.add_theme_font_size_override("font_size", 13 if _compact_mode else PageUIThemeScript.FONT_SIZE_BODY)
	_note.visible = false if _compact_mode else _note.text.strip_edges() != ""
	_bar.custom_minimum_size = Vector2(0.0, 6.0 if _compact_mode else 10.0)
	_bar.visible = _bar_should_show


func _get_bar_color(ratio: float, bar_mode: StringName = &"positive") -> Color:
	ratio = clampf(ratio, 0.0, 1.0)
	if bar_mode == &"burden":
		if ratio >= 0.75:
			return Color("9a4e3f")
		if ratio >= 0.50:
			return Color("a17b43")
		return Color("6f8857")
	if ratio <= 0.25:
		return Color("9a4e3f")
	if ratio <= 0.50:
		return Color("a17b43")
	return Color("6f8857")


func _make_panel_style(bg: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style
