class_name PageUITheme
extends RefCounted

const COLOR_BACKGROUND := Color("14110f")
const COLOR_PANEL := Color("241d18")
const COLOR_PANEL_ALT := Color("2d231b")
const COLOR_PANEL_HIGHLIGHT := Color("5a4834")
const COLOR_TEXT := Color("eadfcf")
const COLOR_TEXT_MUTED := Color("c0b29b")
const COLOR_TEXT_DISABLED := Color("7b6d5d")
const COLOR_ACCENT := Color("b48a4c")
const COLOR_BORDER := Color("5a4733")
const COLOR_BORDER_SOFT := Color("3a2e23")
const COLOR_OVERLAY := Color(0.04, 0.035, 0.03, 0.88)

const FONT_SIZE_HEADER := 24
const FONT_SIZE_BODY := 16
const FONT_SIZE_SMALL := 13


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.0))
	theme.set_font_size("font_size", "Label", FONT_SIZE_BODY)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_focus_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_TEXT)
	theme.set_color("font_pressed_color", "Button", COLOR_TEXT)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DISABLED)
	theme.set_font_size("font_size", "Button", FONT_SIZE_BODY)
	theme.set_color("font_color", "CheckBox", COLOR_TEXT)
	theme.set_color("font_hover_color", "CheckBox", COLOR_TEXT)
	theme.set_color("font_pressed_color", "CheckBox", COLOR_TEXT)
	theme.set_color("font_disabled_color", "CheckBox", COLOR_TEXT_DISABLED)
	theme.set_color("caret_color", "LineEdit", COLOR_TEXT)
	theme.set_color("font_color", "LineEdit", COLOR_TEXT)
	theme.set_color("font_color", "SpinBox", COLOR_TEXT)
	theme.set_color("font_color", "TextEdit", COLOR_TEXT)
	theme.set_stylebox("panel", "PanelContainer", _make_panel_style(COLOR_PANEL, COLOR_BORDER, 10))
	theme.set_stylebox("panel", "ScrollContainer", _make_panel_style(COLOR_PANEL_ALT, COLOR_BORDER_SOFT, 8))
	theme.set_stylebox("normal", "Button", _make_button_style(COLOR_PANEL_ALT, COLOR_BORDER))
	theme.set_stylebox("hover", "Button", _make_button_style(COLOR_PANEL_HIGHLIGHT.lightened(0.08), COLOR_ACCENT))
	theme.set_stylebox("pressed", "Button", _make_button_style(COLOR_PANEL_HIGHLIGHT, COLOR_ACCENT))
	theme.set_stylebox("disabled", "Button", _make_button_style(COLOR_PANEL.darkened(0.08), COLOR_BORDER_SOFT))
	theme.set_stylebox("focus", "Button", _make_button_style(COLOR_PANEL_HIGHLIGHT, COLOR_ACCENT))
	theme.set_stylebox("normal", "LineEdit", _make_panel_style(COLOR_PANEL_ALT, COLOR_BORDER_SOFT, 6, 10))
	theme.set_stylebox("focus", "LineEdit", _make_panel_style(COLOR_PANEL_ALT, COLOR_ACCENT, 6, 10))
	theme.set_stylebox("read_only", "LineEdit", _make_panel_style(COLOR_PANEL, COLOR_BORDER_SOFT, 6, 10))
	return theme


static func ensure_background(root: Control) -> void:
	if root == null or root.get_node_or_null("UIBackground") != null:
		return
	var background := ColorRect.new()
	background.name = "UIBackground"
	background.color = COLOR_BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0
	root.add_child(background)
	root.move_child(background, 0)


static func apply_panel_variant(panel: Control, variant: String = "panel") -> void:
	if panel == null:
		return
	match variant:
		"highlight":
			panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_HIGHLIGHT, COLOR_ACCENT, 12, 12))
		"alt":
			panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_ALT, COLOR_BORDER_SOFT, 10, 12))
		"dark":
			panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_BACKGROUND.lightened(0.03), COLOR_BORDER_SOFT, 10, 12))
		_:
			panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL, COLOR_BORDER, 10, 12))


static func style_header_label(label: Label, accent: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", FONT_SIZE_HEADER)
	label.modulate = COLOR_ACCENT if accent else COLOR_TEXT


static func style_section_label(label: Label, accent: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = COLOR_ACCENT if accent else COLOR_TEXT


static func style_small_label(label: Label) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", FONT_SIZE_SMALL)
	label.modulate = COLOR_TEXT_MUTED


static func style_body_label(label: Label, muted: bool = false) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	label.modulate = COLOR_TEXT_MUTED if muted else COLOR_TEXT


static func style_button(button: Button, accent: bool = false) -> void:
	if button == null:
		return
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 42.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = false
	if accent:
		button.add_theme_stylebox_override("normal", _make_button_style(COLOR_PANEL_HIGHLIGHT, COLOR_ACCENT))
		button.add_theme_stylebox_override("hover", _make_button_style(COLOR_PANEL_HIGHLIGHT.lightened(0.08), COLOR_ACCENT))
		button.add_theme_stylebox_override("pressed", _make_button_style(COLOR_PANEL_HIGHLIGHT.darkened(0.04), COLOR_ACCENT))


static func style_overlay_backdrop(backdrop: ColorRect) -> void:
	if backdrop == null:
		return
	backdrop.color = COLOR_OVERLAY


static func create_section_panel(title_text: String, variant: String = "panel") -> Dictionary:
	var panel := PanelContainer.new()
	apply_panel_variant(panel, variant)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)
	var title := Label.new()
	title.text = title_text
	style_section_label(title, variant == "highlight")
	root.add_child(title)
	return {"panel": panel, "root": root, "title": title}


static func _make_panel_style(bg: Color, border: Color, radius: int, margin: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


static func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style
