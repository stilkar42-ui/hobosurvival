class_name TitleAtmosphere
extends Control

var _stars: Array[Vector2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_generate_stars()
	resized.connect(Callable(self, "_on_resized"))
	queue_redraw()


func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	if rect.size == Vector2.ZERO:
		return

	_draw_sky_gradient(rect)
	_draw_stars()
	_draw_moon(rect)
	_draw_skyline(rect)
	_draw_tracks(rect)
	_draw_campfire(rect)
	_draw_vignette(rect)


func _on_resized() -> void:
	_generate_stars()
	queue_redraw()


func _generate_stars() -> void:
	_stars.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 1932001
	var count = 44
	for index in range(count):
		_stars.append(Vector2(
			rng.randf_range(24.0, max(size.x - 24.0, 24.0)),
			rng.randf_range(20.0, max(size.y * 0.42, 20.0))
		))


func _draw_sky_gradient(rect: Rect2) -> void:
	var bands = [
		Color("132033"),
		Color("1b2c45"),
		Color("2d4050"),
		Color("473d32"),
		Color("221a17")
	]
	var band_height = rect.size.y / float(bands.size())
	for index in range(bands.size()):
		draw_rect(
			Rect2(0.0, band_height * index, rect.size.x, band_height + 2.0),
			bands[index]
		)


func _draw_stars() -> void:
	for star in _stars:
		draw_circle(star, 1.6, Color(1.0, 0.96, 0.82, 0.8))


func _draw_moon(rect: Rect2) -> void:
	var moon_center = Vector2(rect.size.x * 0.82, rect.size.y * 0.18)
	draw_circle(moon_center, 34.0, Color(0.9, 0.88, 0.75, 0.18))
	draw_circle(moon_center, 18.0, Color(0.92, 0.9, 0.8, 0.92))


func _draw_skyline(rect: Rect2) -> void:
	var base_y = rect.size.y * 0.64
	var silhouette = [
		Vector2(0.0, rect.size.y),
		Vector2(0.0, base_y),
		Vector2(rect.size.x * 0.07, base_y - 8.0),
		Vector2(rect.size.x * 0.11, base_y - 54.0),
		Vector2(rect.size.x * 0.16, base_y - 54.0),
		Vector2(rect.size.x * 0.16, base_y - 18.0),
		Vector2(rect.size.x * 0.24, base_y - 18.0),
		Vector2(rect.size.x * 0.24, base_y - 70.0),
		Vector2(rect.size.x * 0.31, base_y - 70.0),
		Vector2(rect.size.x * 0.31, base_y - 26.0),
		Vector2(rect.size.x * 0.38, base_y - 26.0),
		Vector2(rect.size.x * 0.44, base_y - 46.0),
		Vector2(rect.size.x * 0.48, base_y - 20.0),
		Vector2(rect.size.x * 0.55, base_y - 20.0),
		Vector2(rect.size.x * 0.6, base_y - 78.0),
		Vector2(rect.size.x * 0.65, base_y - 78.0),
		Vector2(rect.size.x * 0.65, base_y - 24.0),
		Vector2(rect.size.x * 0.72, base_y - 24.0),
		Vector2(rect.size.x * 0.72, base_y - 56.0),
		Vector2(rect.size.x * 0.77, base_y - 56.0),
		Vector2(rect.size.x * 0.77, base_y - 14.0),
		Vector2(rect.size.x * 0.86, base_y - 14.0),
		Vector2(rect.size.x * 0.91, base_y - 42.0),
		Vector2(rect.size.x * 0.95, base_y - 20.0),
		Vector2(rect.size.x, base_y - 20.0),
		Vector2(rect.size.x, rect.size.y)
	]
	draw_colored_polygon(silhouette, Color("13110f"))


func _draw_tracks(rect: Rect2) -> void:
	var horizon_y = rect.size.y * 0.67
	var bottom_y = rect.size.y
	var center_x = rect.size.x * 0.56
	var rail_color = Color(0.16, 0.14, 0.12, 0.9)
	var tie_color = Color(0.22, 0.16, 0.11, 0.85)

	draw_line(Vector2(center_x - 44.0, horizon_y), Vector2(rect.size.x * 0.34, bottom_y), rail_color, 4.0)
	draw_line(Vector2(center_x + 44.0, horizon_y), Vector2(rect.size.x * 0.76, bottom_y), rail_color, 4.0)

	for step in range(11):
		var t = float(step) / 10.0
		var y = lerpf(horizon_y + 20.0, bottom_y - 10.0, t)
		var left_x = lerpf(center_x - 32.0, rect.size.x * 0.34, t)
		var right_x = lerpf(center_x + 32.0, rect.size.x * 0.76, t)
		draw_line(Vector2(left_x, y), Vector2(right_x, y), tie_color, 2.0 + (t * 2.5))


func _draw_campfire(rect: Rect2) -> void:
	var center = Vector2(rect.size.x * 0.18, rect.size.y * 0.76)
	draw_circle(center, 76.0, Color(0.88, 0.38, 0.12, 0.08))
	draw_circle(center, 42.0, Color(0.94, 0.46, 0.1, 0.12))
	draw_circle(center, 18.0, Color(0.96, 0.64, 0.24, 0.18))

	var flame = [
		Vector2(center.x, center.y - 22.0),
		Vector2(center.x - 10.0, center.y + 4.0),
		Vector2(center.x, center.y + 14.0),
		Vector2(center.x + 10.0, center.y + 4.0)
	]
	draw_colored_polygon(flame, Color(0.98, 0.62, 0.24, 0.85))
	draw_line(Vector2(center.x - 16.0, center.y + 10.0), Vector2(center.x + 12.0, center.y + 18.0), Color("2c1c13"), 3.0)
	draw_line(Vector2(center.x + 16.0, center.y + 10.0), Vector2(center.x - 12.0, center.y + 18.0), Color("2c1c13"), 3.0)


func _draw_vignette(rect: Rect2) -> void:
	var overlays = [
		Rect2(0.0, 0.0, rect.size.x, 42.0),
		Rect2(0.0, rect.size.y - 52.0, rect.size.x, 52.0),
		Rect2(0.0, 0.0, 42.0, rect.size.y),
		Rect2(rect.size.x - 42.0, 0.0, 42.0, rect.size.y)
	]
	for overlay in overlays:
		draw_rect(overlay, Color(0.0, 0.0, 0.0, 0.22))
