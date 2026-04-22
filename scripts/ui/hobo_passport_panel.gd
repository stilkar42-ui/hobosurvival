class_name HoboPassportPanel
extends PanelContainer

const PageUIThemeScript := preload("res://scripts/ui/page_ui_theme.gd")

var passport_data: PlayerPassportData = null
var _selected_section_id: StringName = &""
var _selected_field_id: StringName = &""

var _root = null
var _summary_label = null
var _section_list = null
var _section_title_label = null
var _section_summary_label = null
var _field_list = null
var _section_scroll = null
var _field_scroll = null
var _detail_scroll = null
var _section_scroll_content = null
var _field_scroll_content = null
var _detail_scroll_content = null
var _detail_section_label = null
var _detail_field_label = null
var _detail_value_label = null
var _detail_notes_label = null


func _ready() -> void:
	_build_static_layout()
	resized.connect(Callable(self, "_sync_scroll_content_widths"))
	_sync_scroll_content_widths()
	_render()


func set_passport_data(new_passport_data: PlayerPassportData) -> void:
	passport_data = new_passport_data
	_sync_selection()
	_render()


func _build_static_layout() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(self, "alt")

	_root = VBoxContainer.new()
	_root.name = "PassportRoot"
	_root.add_theme_constant_override("separation", 12)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_root)

	var title = Label.new()
	title.text = "Hobo Passport"
	PageUIThemeScript.style_header_label(title, true)
	_root.add_child(title)

	var subtitle = Label.new()
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.text = "Debug rig character page. Identity, condition, skill, and standing live here for later dialogue, work, survival, and reputation systems."
	PageUIThemeScript.style_body_label(subtitle, true)
	_root.add_child(subtitle)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PageUIThemeScript.style_body_label(_summary_label)
	_root.add_child(_summary_label)

	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(columns)

	var sections_panel = _build_sections_panel()
	sections_panel.custom_minimum_size = Vector2(220.0, 0.0)
	columns.add_child(sections_panel)
	columns.add_child(_build_fields_panel())
	columns.add_child(_build_detail_panel())


func _build_sections_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(panel, "panel")

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)

	var title = Label.new()
	title.text = "Sections"
	PageUIThemeScript.style_section_label(title)
	content.add_child(title)

	_section_list = VBoxContainer.new()
	_section_list.add_theme_constant_override("separation", 6)
	_section_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_section_scroll = ScrollContainer.new()
	_section_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_section_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_section_scroll)

	_section_scroll_content = MarginContainer.new()
	_section_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_scroll_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_section_scroll.add_child(_section_scroll_content)
	_section_scroll_content.add_child(_section_list)

	return panel


func _build_fields_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(panel, "highlight")

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)

	_section_title_label = Label.new()
	PageUIThemeScript.style_header_label(_section_title_label, true)
	_section_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_section_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_section_title_label)

	_section_summary_label = Label.new()
	_section_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_section_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_body_label(_section_summary_label)
	content.add_child(_section_summary_label)

	content.add_child(HSeparator.new())

	_field_list = VBoxContainer.new()
	_field_list.add_theme_constant_override("separation", 6)
	_field_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_list.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_field_scroll = ScrollContainer.new()
	_field_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_field_scroll)
	_field_scroll_content = MarginContainer.new()
	_field_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_scroll_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_scroll.add_child(_field_scroll_content)
	_field_scroll_content.add_child(_field_list)

	return panel


func _build_detail_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320.0, 0.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.apply_panel_variant(panel, "panel")

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(content)

	var title = Label.new()
	title.text = "Field Detail"
	PageUIThemeScript.style_section_label(title)
	content.add_child(title)

	_detail_section_label = Label.new()
	_detail_section_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_small_label(_detail_section_label)
	content.add_child(_detail_section_label)

	_detail_field_label = Label.new()
	PageUIThemeScript.style_header_label(_detail_field_label)
	_detail_field_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_field_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_detail_field_label)

	_detail_value_label = Label.new()
	_detail_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_body_label(_detail_value_label)
	content.add_child(_detail_value_label)

	content.add_child(HSeparator.new())

	_detail_notes_label = Label.new()
	_detail_notes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_notes_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	PageUIThemeScript.style_body_label(_detail_notes_label, true)

	_detail_scroll = ScrollContainer.new()
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_detail_scroll)
	_detail_scroll_content = MarginContainer.new()
	_detail_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail_scroll_content)
	_detail_scroll_content.add_child(_detail_notes_label)

	return panel


func _render() -> void:
	if _summary_label == null or _section_list == null or _field_list == null or _detail_notes_label == null:
		return

	_clear_children(_section_list)
	_clear_children(_field_list)

	if passport_data == null:
		_summary_label.text = "No passport data assigned."
		_section_title_label.text = "No Section"
		_section_summary_label.text = "Assign a PlayerPassportData resource to display this panel."
		_set_detail_state("No Field Selected", "-", "This panel will show field notes and later mechanical explanation.")
		return

	_sync_selection()

	_summary_label.text = "%s    Goal: %s" % [
		passport_data.get_identity_summary(),
		passport_data.current_goal
	]

	var sections = passport_data.get_sections()
	for section in sections:
		_section_list.add_child(_build_section_button(section))

	var selected_section = passport_data.get_section_by_id(_selected_section_id)
	_section_title_label.text = String(selected_section.get("title", "No Section"))
	_section_summary_label.text = String(selected_section.get("summary", ""))

	var fields: Array = selected_section.get("fields", [])
	for field in fields:
		if bool(field.get("display_as_bar", false)):
			_field_list.add_child(_build_condition_field_control(field))
		else:
			_field_list.add_child(_build_field_button(field))

	var selected_field = _get_selected_field(selected_section)
	_set_detail_state(
		String(selected_field.get("label", "No Field Selected")),
		String(selected_field.get("value", "-")),
		String(selected_field.get("notes", "This field does not yet have descriptive notes."))
	)


func _sync_selection() -> void:
	if passport_data == null:
		_selected_section_id = &""
		_selected_field_id = &""
		return

	var sections = passport_data.get_sections()
	if sections.is_empty():
		_selected_section_id = &""
		_selected_field_id = &""
		return

	if passport_data.get_section_by_id(_selected_section_id).is_empty():
		_selected_section_id = StringName(sections[0].get("id", &""))

	var selected_section = passport_data.get_section_by_id(_selected_section_id)
	var fields: Array = selected_section.get("fields", [])
	if fields.is_empty():
		_selected_field_id = &""
		return

	var has_selected_field := false
	for field in fields:
		if StringName(field.get("id", &"")) == _selected_field_id:
			has_selected_field = true
			break
	if not has_selected_field:
		_selected_field_id = StringName(fields[0].get("id", &""))


func _build_section_button(section: Dictionary) -> Button:
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = String(section.get("title", "Section"))
	_apply_button_style(button, StringName(section.get("id", &"")) == _selected_section_id, false)
	button.pressed.connect(Callable(self, "_on_section_pressed").bind(StringName(section.get("id", &""))))
	return button


func _build_field_button(field: Dictionary) -> Button:
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = _format_field_button_text(field)
	_apply_button_style(button, StringName(field.get("id", &"")) == _selected_field_id, true)
	button.pressed.connect(Callable(self, "_on_field_pressed").bind(StringName(field.get("id", &""))))
	return button


func _build_condition_field_control(field: Dictionary) -> Control:
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_build_field_button(field))

	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	bar.min_value = 0
	bar.max_value = max(int(field.get("max", 100)), 1)
	bar.value = clampi(int(field.get("current", 0)), 0, int(bar.max_value))
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _make_panel_style(Color("2b241d"), Color("5f4e3c"), 1, 4))
	bar.add_theme_stylebox_override("fill", _make_panel_style(_get_condition_bar_color(float(bar.value) / float(bar.max_value)), Color(0.0, 0.0, 0.0, 0.0), 0, 4))
	root.add_child(bar)
	return root


func _set_detail_state(field_name: String, value_text: String, notes_text: String) -> void:
	var section = passport_data.get_section_by_id(_selected_section_id) if passport_data != null else {}
	_detail_section_label.text = String(section.get("title", ""))
	_detail_field_label.text = field_name
	_detail_value_label.text = "Current Value: %s" % (value_text if value_text != "" else "-")
	_detail_notes_label.text = notes_text
	_sync_scroll_content_widths()


func _get_selected_field(selected_section: Dictionary) -> Dictionary:
	var fields: Array = selected_section.get("fields", [])
	for field in fields:
		if StringName(field.get("id", &"")) == _selected_field_id:
			return field
	if fields.is_empty():
		return {}
	return fields[0]


func _on_section_pressed(section_id: StringName) -> void:
	_selected_section_id = section_id
	_selected_field_id = &""
	_sync_selection()
	_render()


func _on_field_pressed(field_id: StringName) -> void:
	_selected_field_id = field_id
	_render()


func _apply_button_style(button: Button, selected: bool, compact: bool) -> void:
	button.add_theme_color_override("font_color", Color("201710"))
	button.add_theme_color_override("font_pressed_color", Color("201710"))
	button.add_theme_color_override("font_hover_color", Color("201710"))
	button.add_theme_color_override("font_disabled_color", Color("6c5d49"))
	button.add_theme_stylebox_override("normal", _make_panel_style(
		Color("f0e4ca") if selected else Color("d9c8a7"),
		Color("886c47") if selected else Color("9b8058"),
		1,
		4
	))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color("e6d7b8"), Color("a38458"), 1, 4))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color("f2e8d0"), Color("705435"), 1, 4))
	button.add_theme_stylebox_override("disabled", _make_panel_style(Color("c5b699"), Color("8b7753"), 1, 4))
	button.custom_minimum_size = Vector2(0.0, 34.0 if compact else 38.0)


func _format_field_preview(value_text: String) -> String:
	var single_line = value_text.replace("\n", " ").strip_edges()
	if single_line.length() <= 26:
		return single_line
	return "%s..." % single_line.substr(0, 23)


func _format_field_button_text(field: Dictionary) -> String:
	var label_text = _truncate_single_line(String(field.get("label", "Field")), 34)
	var value_text = _format_field_preview(String(field.get("value", "-")))
	if value_text == "" or value_text == "-" or value_text == "Recorded":
		return label_text
	return "%s    %s" % [label_text, value_text]


func _truncate_single_line(text: String, limit: int) -> String:
	var single_line = text.replace("\n", " ").strip_edges()
	if single_line.length() <= limit:
		return single_line
	return "%s..." % single_line.substr(0, max(limit - 3, 0))


func _get_condition_bar_color(ratio: float) -> Color:
	if ratio <= 0.25:
		return Color("9a4e3f")
	if ratio <= 0.50:
		return Color("a17b43")
	return Color("6f8857")


func _sync_scroll_content_widths() -> void:
	_sync_scroll_width(_section_scroll, _section_scroll_content, 18.0)
	_sync_scroll_width(_field_scroll, _field_scroll_content, 18.0)
	_sync_scroll_width(_detail_scroll, _detail_scroll_content, 24.0)
	if _detail_notes_label != null and _detail_scroll_content != null:
		_detail_notes_label.custom_minimum_size.x = max(_detail_scroll_content.custom_minimum_size.x - 8.0, 0.0)


func _sync_scroll_width(scroll: ScrollContainer, content: Control, padding: float) -> void:
	if scroll == null or content == null:
		return
	content.custom_minimum_size.x = max(scroll.size.x - padding, 0.0)


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
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	style.shadow_size = 6
	style.content_margin_left = 10.0
	style.content_margin_top = 10.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 10.0
	return style


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
