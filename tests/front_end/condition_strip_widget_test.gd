extends SceneTree

const ConditionStripWidgetScript := preload("res://scripts/ui/widgets/condition_strip_widget.gd")

var _failed := false


func _init() -> void:
	var root = Window.new()
	root.name = "ConditionStripWidgetTestRoot"
	root.size = Vector2i(1280, 240)
	get_root().add_child(root)

	var strip = ConditionStripWidgetScript.new()
	strip.name = "PersistentConditionStrip"
	strip.set_title("Road Condition")
	strip.set_columns(9)
	strip.set_compact_mode(true)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(strip)

	strip.set_conditions([
		_make_entry(&"warmth", "Warmth", "63", 63, 100, &"positive"),
		_make_entry(&"stamina", "Stamina", "42", 42, 100, &"positive"),
		_make_entry(&"nutrition", "Nutrition", "58", 58, 100, &"positive"),
		_make_entry(&"water", "Water", "1/2", 3, 4, &"positive"),
		_make_entry(&"morale", "Morale", "47", 47, 100, &"positive"),
		_make_entry(&"hygiene", "Hygiene", "36", 36, 100, &"positive"),
		_make_entry(&"presentability", "Presentability", "32", 32, 100, &"positive"),
		_make_entry(&"weight", "Weight", "14.0/28kg", 14, 28, &"burden"),
		_make_entry(&"dampness", "Dampness", "80", 80, 100, &"burden")
	])

	call_deferred("_run_checks", strip)


func _run_checks(strip: Control) -> void:
	await process_frame
	await process_frame

	_expect(strip.is_visible_in_tree(), "condition strip is visible")
	_expect(_count_visible_bars(strip) == 9, "compact condition strip renders one visible bar per stat")

	_expect(_get_stat_bar(strip, "Warmth").value == 63.0, "positive warmth bar uses supplied value")
	_expect(_get_stat_bar(strip, "Stamina").value == 42.0, "positive stamina bar uses supplied value")
	_expect(_get_stat_bar(strip, "Water").value == 3.0, "water bar uses supplied stock indicator value")
	_expect(_get_stat_bar(strip, "Weight").value == 14.0, "weight burden bar uses carried load value")
	_expect(_get_stat_bar(strip, "Weight").max_value == 28.0, "weight burden bar uses max carry load")
	_expect(_get_stat_bar(strip, "Dampness").value == 80.0, "dampness burden bar uses dampness value")

	if _failed:
		quit(1)
		return
	quit()


func _make_entry(stat_id: StringName, label: String, value_text: String, current: float, max_value: float, bar_mode: StringName) -> Dictionary:
	return {
		"stat_id": stat_id,
		"label": label,
		"value_text": value_text,
		"current": current,
		"max": max_value,
		"display_as_bar": true,
		"bar_mode": bar_mode
	}


func _count_visible_bars(root: Node) -> int:
	var count := 0
	for child in root.find_children("ConditionStatBar", "ProgressBar", true, false):
		var bar = child as ProgressBar
		if bar != null and bar.is_visible_in_tree():
			count += 1
	return count


func _get_stat_bar(root: Node, label_text: String) -> ProgressBar:
	var label = _find_label(root, label_text)
	_expect(label != null, "%s label exists" % label_text)
	if label == null:
		return ProgressBar.new()
	var current: Node = label
	while current != null:
		var bar = current.find_child("ConditionStatBar", true, false) as ProgressBar
		if bar != null:
			_expect(bar.is_visible_in_tree(), "%s bar is visible" % label_text)
			return bar
		current = current.get_parent()
	return ProgressBar.new()


func _find_label(root: Node, expected_text: String) -> Label:
	for child in root.find_children("*", "Label", true, false):
		var label = child as Label
		if label != null and label.text == expected_text:
			return label
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	push_error("FAIL: %s" % message)
	_failed = true
