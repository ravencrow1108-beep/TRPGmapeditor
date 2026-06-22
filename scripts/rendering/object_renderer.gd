##
## ObjectRenderer — Draws placed MapObjectData instances as sprites/shapes.
## Attached as a child of MapRoot in the SubViewport.
##
class_name ObjectRenderer
extends Node2D


# ---------- Configurable ----------
@export var default_object_color: Color = Color(0.6, 0.4, 0.2, 0.9)
@export var selected_color: Color = Color(0.2, 0.6, 1.0, 0.8)
@export var handle_color: Color = Color(0.2, 0.8, 1.0, 0.9)


# ---------- Internal state ----------
var _objects: Array = []
var _selected_object_id: String = ""
var _map_dimensions: Vector2i = Vector2i(100, 100)
var _grid_size: Vector2i = Vector2i(32, 32)


# ---------- Public API ----------

func set_objects(objects: Array) -> void:
	_objects = objects
	queue_redraw()


func add_object(obj: MapObjectData) -> void:
	_objects.append(obj)
	queue_redraw()


func remove_object(object_id: String) -> void:
	for i in range(_objects.size()):
		var o = _objects[i]
		if o is MapObjectData and o.object_id == object_id:
			_objects.remove_at(i)
			queue_redraw()
			return


func update_object(object_id: String) -> void:
	queue_redraw()


func set_selected(object_id: String) -> void:
	_selected_object_id = object_id
	queue_redraw()


func clear_selection() -> void:
	_selected_object_id = ""
	queue_redraw()


func get_object_by_id(object_id: String) -> MapObjectData:
	for obj in _objects:
		if obj is MapObjectData and obj.object_id == object_id:
			return obj
	return null


func get_object_at_position(world_pos: Vector2, tolerance: float = 16.0) -> MapObjectData:
	var best: MapObjectData = null
	var best_dist: float = tolerance
	for obj in _objects:
		if obj is MapObjectData:
			var dist: float = obj.position.distance_to(world_pos)
			if dist < best_dist:
				best = obj
				best_dist = dist
	return best


func configure(map_dims: Vector2i, gs: Vector2i) -> void:
	_map_dimensions = map_dims
	_grid_size = gs
	queue_redraw()


# ---------- Drawing ----------

func _draw() -> void:
	for obj in _objects:
		if obj is MapObjectData:
			_draw_object(obj)


func _draw_object(obj: MapObjectData) -> void:
	var is_selected: bool = (obj.object_id == _selected_object_id and not _selected_object_id.is_empty())
	var base_color: Color = default_object_color
	var draw_pos: Vector2 = obj.position

	match obj.collision_shape:
		MapObjectData.CollisionShape.RECTANGLE:
			var size: Vector2 = Vector2(_grid_size) * obj.scale
			var rect: Rect2 = Rect2(draw_pos - size * 0.5, size)
			draw_rect(rect, base_color, true)
			draw_rect(rect, base_color.darkened(0.3), false)

		MapObjectData.CollisionShape.CIRCLE:
			var radius: float = float(_grid_size.x) * obj.scale.x * 0.5
			draw_circle(draw_pos, radius, base_color)

		MapObjectData.CollisionShape.GRID_FILL:
			var cell_rect: Rect2 = GridUtils.get_cell_rect(obj.grid_position, _grid_size)
			draw_rect(cell_rect, base_color, true)
			draw_rect(cell_rect, base_color.darkened(0.3), false)

		_:  # POLYGON / fallback
			var size: Vector2 = Vector2(float(_grid_size.x) * obj.scale.x, float(_grid_size.y) * obj.scale.y)
			var rect: Rect2 = Rect2(draw_pos - size * 0.5, size)
			draw_rect(rect, base_color, true)
			draw_rect(rect, Color.ORANGE, false)

	# Selection box + handles
	if is_selected:
		var sel_size: Vector2
		match obj.collision_shape:
			MapObjectData.CollisionShape.CIRCLE:
				var r: float = float(_grid_size.x) * obj.scale.x * 0.5
				sel_size = Vector2(r * 2.0, r * 2.0)
			_:
				sel_size = Vector2(float(_grid_size.x) * obj.scale.x, float(_grid_size.y) * obj.scale.y)

		var sel_rect: Rect2 = Rect2(draw_pos - sel_size * 0.5, sel_size)
		draw_rect(sel_rect, selected_color, false)

		var handle_size: float = 5.0
		for corner in [
			sel_rect.position,
			sel_rect.position + Vector2(sel_rect.size.x, 0),
			sel_rect.position + Vector2(0, sel_rect.size.y),
			sel_rect.position + sel_rect.size
		]:
			draw_rect(Rect2(corner - Vector2(handle_size, handle_size) * 0.5, Vector2(handle_size, handle_size)), handle_color, true)

		var rot_handle: Vector2 = sel_rect.position + Vector2(sel_rect.size.x * 0.5, -12.0)
		draw_circle(rot_handle, 4.0, handle_color)
		draw_line(sel_rect.position + Vector2(sel_rect.size.x * 0.5, 0), rot_handle, selected_color)

	# Draw label
	var label_pos: Vector2 = draw_pos + Vector2(0, -float(_grid_size.y) * obj.scale.y * 0.5 - 4)
	var label_text: String = obj.display_name
	if label_text.is_empty():
		label_text = obj.object_type
	if not label_text.is_empty():
		draw_string(ThemeDB.fallback_font, label_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
