class_name FrontEndPlaceholderPage
extends PanelContainer

@export var heading := "Placeholder"
@export_multiline var body_text := ""

var _title_label = null
var _body_label = null


func _ready() -> void:
	_build_layout()
	_refresh()


func configure(new_heading: String, new_body_text: String) -> void:
	heading = new_heading
	body_text = new_body_text
	_refresh()


func _build_layout() -> void:
	if get_child_count() > 0:
		return

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroller = ScrollContainer.new()
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroller)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.add_child(content)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	content.add_child(_title_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_body_label)


func _refresh() -> void:
	if _title_label == null or _body_label == null:
		return
	_title_label.text = heading
	_body_label.text = body_text
