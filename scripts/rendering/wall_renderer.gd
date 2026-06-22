##
## WallRenderer — Draws wall segments with distinct visual styles per WallType.
## Attached as a child of MapRoot in the SubViewport.
##
class_name WallRenderer
extends Node2D


# ---------- Configurable ----------
@export var solid_color: Color = Color(0.2, 0.2, 0.22, 1.0)
@export var window_color: Color = Color(0.5, 0.7, 0.85, 0.9)
@export var bars_color: Color = Color(0.35, 0.35, 0.35, 1.0)
@export var illusion_color: Color = Color(0.5, 0.3, 0.8, 0.35)
@export var half_height_color: Color = Color(0.4, 0.4, 0.45, 0.9)
@export var transparent_color: Color = Color(0.6, 0.6, 0.6, 0.2)
@export var selected_color: Color = Color(0.2, 0.6, 1.0, 0.8)


# ---------- Internal state ----------
var _walls: Array = []
var _selected_wall_id: String = ""


# ---------- Public API ----------

func set_walls(walls: Array) -> void:
	_walls = walls
	queue_redraw()


func add_wall(wall: WallSegmentData) -> void:
	_walls.append(wall)
	queue_redraw()


func remove_wall(segment_id: String) -> void:
	for i in range(_walls.size()):
		var w = _walls[i]
		if w is WallSegmentData and w.segment_id == segment_id:
			_walls.remove_at(i)
			queue_redraw()
			return


func update_wall(segment_id: String) -> void:
	queue_redraw()


func set_selected(segment_id: String) -> void:
	_selected_wall_id = segment_id
	queue_redraw()


func clear_selection() -> void:
	_selected_wall_id = ""
	queue_redraw()


func configure(_map_dims: Vector2i, _gs: Vector2i) -> void:
	queue_redraw()


# ---------- Drawing ----------

func _draw() -> void:
	for wall in _walls:
		if wall is WallSegmentData:
			_draw_wall(wall)


func _draw_wall(wall: WallSegmentData) -> void:
	var line_color: Color
	var line_width: float
	var is_selected: bool = (wall.segment_id == _selected_wall_id and not _selected_wall_id.is_empty())

	match wall.wall_type:
		WallSegmentData.WallType.SOLID:
			line_color = solid_color
			line_width = 4.0
		WallSegmentData.WallType.WINDOW:
			line_color = window_color
			line_width = 3.0
		WallSegmentData.WallType.BARS:
			line_color = bars_color
			line_width = 2.0
		WallSegmentData.WallType.ILLUSION:
			line_color = illusion_color
			line_width = 2.5
		WallSegmentData.WallType.HALF_HEIGHT:
			line_color = half_height_color
			line_width = 3.0
		WallSegmentData.WallType.TRANSPARENT:
			line_color = transparent_color
			line_width = 2.0
		_:
			line_color = solid_color
			line_width = 4.0

	if is_selected:
		line_color = selected_color
		line_width += 1.0

	# Obstacle flag tints
	if wall.has_flag(WallSegmentData.BLOCK_VISION):
		line_color = line_color.blend(Color(0.8, 0.2, 0.2, 0.3))
	if wall.has_flag(WallSegmentData.BLOCK_LIGHT):
		line_color = line_color.blend(Color(1.0, 0.9, 0.2, 0.3))

	var from_pos: Vector2 = wall.start_point
	var to_pos: Vector2 = wall.end_point

	match wall.wall_type:
		WallSegmentData.WallType.WINDOW:
			_draw_dashed_line(from_pos, to_pos, line_color, line_width, 8.0, 4.0)
		WallSegmentData.WallType.BARS:
			_draw_bars(from_pos, to_pos, line_color, line_width)
		WallSegmentData.WallType.ILLUSION:
			_draw_dotted_line(from_pos, to_pos, line_color, line_width, 6.0)
		WallSegmentData.WallType.HALF_HEIGHT:
			draw_line(from_pos, to_pos, line_color, line_width)
			_draw_height_label(from_pos, to_pos, wall.height, line_color)
		_:  # SOLID, TRANSPARENT
			draw_line(from_pos, to_pos, line_color, line_width)

	if is_selected:
		var handle_size: float = 6.0
		draw_circle(from_pos, handle_size, Color(0.2, 0.8, 1.0, 0.8))
		draw_circle(to_pos, handle_size, Color(0.2, 0.8, 1.0, 0.8))


# ---------- Private line styles ----------

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float, dash_len: float, gap_len: float) -> void:
	var dir: Vector2 = to - from
	var total_len: float = dir.length()
	if total_len < 0.1:
		return
	dir = dir.normalized()
	var drawn: float = 0.0
	var dash: bool = true
	while drawn < total_len:
		if dash:
			var seg_end: float = minf(drawn + dash_len, total_len)
			draw_line(from + dir * drawn, from + dir * seg_end, color, width)
			drawn = seg_end
		else:
			drawn = minf(drawn + gap_len, total_len)
		dash = not dash


func _draw_dotted_line(from: Vector2, to: Vector2, color: Color, width: float, spacing: float) -> void:
	var dir: Vector2 = to - from
	var total_len: float = dir.length()
	if total_len < 0.1:
		return
	dir = dir.normalized()
	var pos: float = 0.0
	while pos < total_len:
		draw_circle(from + dir * pos, width * 0.7, color)
		pos += spacing


func _draw_bars(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, color, width)
	var dir: Vector2 = to - from
	var total_len: float = dir.length()
	if total_len < 0.1:
		return
	dir = dir.normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var spacing: float = 10.0
	var pos: float = spacing
	while pos < total_len:
		var pt: Vector2 = from + dir * pos
		draw_line(pt - perp * 4.0, pt + perp * 4.0, color, width * 0.7)
		pos += spacing


func _draw_height_label(from: Vector2, to: Vector2, height: float, _color: Color) -> void:
	var mid: Vector2 = (from + to) * 0.5
	var label_text: String = "%.1fm" % height
	draw_string(ThemeDB.fallback_font, mid + Vector2(0, -8), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
