##
## GridRenderer — Draws grid lines and tile placeholders.
## Supports square and hex grids. Handles camera pan/zoom input.
## Attached to MapRoot in the SubViewport.
##
## NOTE: Camera2D is a SIBLING of this node (both children of MapRoot),
## NOT a child. This ensures zoom-center calculations are correct.
##
class_name GridRenderer
extends Node2D


# ---------- Grid type enum ----------
enum GridType {
	SQUARE = 0,
	HEX_POINTY = 1,
	HEX_FLAT = 2
}

# ---------- Configurable properties ----------
@export var grid_size: Vector2i = Vector2i(32, 32)
@export var grid_color: Color = Color(0.35, 0.35, 0.35, 0.6)
@export var grid_line_width: float = 1.0
@export var map_dimensions: Vector2i = Vector2i(100, 100)
@export var minor_line_color: Color = Color(0.3, 0.3, 0.3, 0.3)
@export var major_line_every: int = 5   ## Draw a thicker line every N cells (square grids only)
@export var grid_type: int = GridType.SQUARE


# ---------- Signals ----------
signal tile_clicked(grid_pos)
signal tile_right_clicked(grid_pos)
signal mouse_moved(world_pos, grid_pos)


# ---------- Internal state ----------
var _camera: Camera2D = null
var _tiles_to_draw: Array = []
var _dirty: bool = true


# ---------- Lifecycle ----------

func _ready() -> void:
	_camera = _find_camera()
	queue_redraw()


func _find_camera() -> Camera2D:
	if get_parent():
		for child in get_parent().get_children():
			if child is Camera2D:
				return child
	for child in get_children():
		if child is Camera2D:
			return child
	return null


# ---------- Drawing ----------

func _draw() -> void:
	if grid_type == GridType.SQUARE:
		_draw_grid_lines()
	else:
		_draw_hex_grid()
	_draw_tiles()


func _draw_grid_lines() -> void:
	var total_width: float = float(map_dimensions.x) * grid_size.x
	var total_height: float = float(map_dimensions.y) * grid_size.y

	var major_col = Color(grid_color.r, grid_color.g, grid_color.b, grid_color.a * 1.5)
	var minor_col = minor_line_color

	for x in range(map_dimensions.x + 1):
		var line_x: float = float(x) * grid_size.x
		var col = major_col if x % major_line_every == 0 else minor_col
		draw_line(Vector2(line_x, 0), Vector2(line_x, total_height), col, grid_line_width)

	for y in range(map_dimensions.y + 1):
		var line_y: float = float(y) * grid_size.y
		var col = major_col if y % major_line_every == 0 else minor_col
		draw_line(Vector2(0, line_y), Vector2(total_width, line_y), col, grid_line_width)


func _draw_hex_grid() -> void:
	for x in range(map_dimensions.x):
		for y in range(map_dimensions.y):
			var vertices: PackedVector2Array = GridUtils.get_hex_vertices(Vector2i(x, y), grid_size, grid_type)
			draw_polyline(vertices, grid_color, grid_line_width)


func _draw_tiles() -> void:
	for entry in _tiles_to_draw:
		var cell: Vector2i = entry.cell
		var color: Color = entry.color
		var pos: Vector2
		var size: Vector2 = Vector2(grid_size)

		if grid_type == GridType.SQUARE:
			pos = GridUtils.grid_to_world(cell, grid_size)
		else:
			pos = GridUtils.hex_grid_to_world(cell, grid_size, grid_type)

		if grid_type == GridType.SQUARE:
			draw_rect(Rect2(pos, size), color, true)
			draw_rect(Rect2(pos, size), color.darkened(0.3), false)
		else:
			var vertices: PackedVector2Array = GridUtils.get_hex_vertices(cell, grid_size, grid_type)
			if vertices.size() >= 3:
				draw_colored_polygon(vertices, color)
				draw_polyline(vertices, color.darkened(0.3), 1.0)


# ---------- Public API ----------

func set_layer_data(layers: Array) -> void:
	_tiles_to_draw.clear()
	for layer in layers:
		if not layer.get("visible", true):
			continue
		var tiles: Dictionary = layer.get("tiles", {})
		var opacity: float = layer.get("opacity", 1.0)
		var tint: Color = layer.get("color", Color.WHITE)
		for cell in tiles.keys():
			if cell is Vector2i:
				var tile_data = tiles[cell]
				var tile_color = _tile_color(tile_data, tint)
				tile_color.a *= opacity
				_tiles_to_draw.append({ cell = cell, color = tile_color, opacity = opacity })
	queue_redraw()
	_dirty = false


func add_tile_to_queue(cell: Vector2i, tile_data: Variant, layer_opacity: float = 1.0, tint: Color = Color.WHITE) -> void:
	for i in range(_tiles_to_draw.size()):
		if _tiles_to_draw[i].cell == cell:
			_tiles_to_draw.remove_at(i)
			break
	var color = _tile_color(tile_data, tint)
	color.a *= layer_opacity
	_tiles_to_draw.append({ cell = cell, color = color, opacity = layer_opacity })
	queue_redraw()


func remove_tile_from_queue(cell: Vector2i) -> void:
	for i in range(_tiles_to_draw.size()):
		if _tiles_to_draw[i].cell == cell:
			_tiles_to_draw.remove_at(i)
			queue_redraw()
			return


func mark_dirty() -> void:
	_dirty = true
	queue_redraw()


# ---------- Coordinate conversion (delegates to GridUtils) ----------

func world_to_grid(world_pos: Vector2) -> Vector2i:
	if grid_type == GridType.SQUARE:
		return GridUtils.world_to_grid(world_pos, grid_size, map_dimensions)
	else:
		return GridUtils.hex_world_to_grid(world_pos, grid_size, grid_type, map_dimensions)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if grid_type == GridType.SQUARE:
		return GridUtils.grid_to_world(grid_pos, grid_size)
	else:
		return GridUtils.hex_grid_to_world(grid_pos, grid_size, grid_type)


func get_cell_rect(grid_pos: Vector2i) -> Rect2:
	if grid_type == GridType.SQUARE:
		return GridUtils.get_cell_rect(grid_pos, grid_size)
	else:
		var center: Vector2 = GridUtils.hex_grid_to_world(grid_pos, grid_size, grid_type)
		return Rect2(center - Vector2(grid_size) * 0.5, Vector2(grid_size))


# ---------- Input handling ----------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		if _camera:
			_camera.position -= event.relative / _camera.zoom

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(get_global_mouse_position(), 1.0 / 1.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(get_global_mouse_position(), 1.15)

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos = get_global_mouse_position()
			var grid_pos = world_to_grid(world_pos)
			tile_clicked.emit(grid_pos)
			mouse_moved.emit(world_pos, grid_pos)

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var grid_pos = world_to_grid(get_global_mouse_position())
			tile_right_clicked.emit(grid_pos)

	if event is InputEventMouseMotion:
		var world_pos = get_global_mouse_position()
		var grid_pos = world_to_grid(world_pos)
		mouse_moved.emit(world_pos, grid_pos)


# ---------- Arrow key pan ----------

func _process(delta: float) -> void:
	if _camera == null:
		return
	var move_speed: float = 600.0 / maxf(_camera.zoom.x, 0.25)
	var move = Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		move.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		move.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		move.y += 1
	if move != Vector2.ZERO:
		_camera.position += move.normalized() * move_speed * delta


# ---------- Private helpers ----------

func _zoom_at_mouse(_mouse_world: Vector2, factor: float) -> void:
	if _camera == null:
		return
	var new_zoom: Vector2 = _camera.zoom * factor
	if new_zoom.x < 0.25 or new_zoom.x > 4.0:
		return
	var pre_zoom = get_global_mouse_position()
	_camera.zoom = new_zoom
	var post_zoom = get_global_mouse_position()
	_camera.position += pre_zoom - post_zoom


func _tile_color(tile_data, _tint: Color) -> Color:
	if tile_data is Dictionary:
		var tile_id: int = tile_data.get("id", 0)
		match tile_id:
			0:  return Color(0.45, 0.60, 0.35, 0.9)
			1:  return Color(0.55, 0.45, 0.30, 0.95)
			2:  return Color(0.35, 0.40, 0.55, 0.9)
			3:  return Color(0.60, 0.55, 0.40, 0.9)
			4:  return Color(0.30, 0.45, 0.65, 0.9)
			_:  return Color(0.40, 0.40, 0.40, 0.9)
	else:
		return Color(0.45, 0.60, 0.35, 0.9)
