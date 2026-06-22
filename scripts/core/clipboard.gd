##
## Clipboard — Stores copied tiles, objects, and walls in relative coordinates.
##
class_name Clipboard
extends RefCounted


var _data: ClipboardData = null


func has_content() -> bool:
	return _data != null and (not _data.tiles.is_empty() or not _data.objects.is_empty() or not _data.walls.is_empty())


func copy_tiles(cells: Array[Vector2i], layer: TerrainLayerData) -> void:
	if cells.is_empty() or layer == null:
		return

	_ensure_data()

	var x_min: int = 0x7fffffff
	var y_min: int = 0x7fffffff
	var x_max: int = -0x7fffffff
	var y_max: int = -0x7fffffff

	for cell in cells:
		x_min = mini(x_min, cell.x)
		y_min = mini(y_min, cell.y)
		x_max = maxi(x_max, cell.x)
		y_max = maxi(y_max, cell.y)

	_data.tiles.clear()
	for cell in cells:
		var relative_cell = Vector2i(cell.x - x_min, cell.y - y_min)
		var tile = layer.tiles.get(cell)
		if tile != null:
			_data.tiles[relative_cell] = tile.duplicate(true) if tile is Dictionary else tile

	_data.source_bounds = Rect2i(x_min, y_min, x_max - x_min + 1, y_max - y_min + 1)


func copy_objects(object_ids: Array[String], objects: Array) -> void:
	if object_ids.is_empty() or objects.is_empty():
		return

	_ensure_data()
	_data.objects.clear()

	var x_min: float = INF
	var y_min: float = INF

	for obj in objects:
		if obj is MapObjectData and obj.object_id in object_ids:
			x_min = minf(x_min, obj.position.x)
			y_min = minf(y_min, obj.position.y)

	for obj in objects:
		if obj is MapObjectData and obj.object_id in object_ids:
			var obj_copy = _copy_object(obj)
			obj_copy.position.x -= x_min
			obj_copy.position.y -= y_min
			obj_copy.grid_position.x -= int(x_min)
			obj_copy.grid_position.y -= int(y_min)
			_data.objects.append(obj_copy)


func copy_walls(wall_ids: Array[String], walls: Array) -> void:
	if wall_ids.is_empty() or walls.is_empty():
		return

	_ensure_data()
	_data.walls.clear()

	var x_min: float = INF
	var y_min: float = INF

	for wall in walls:
		if wall is WallSegmentData and wall.segment_id in wall_ids:
			x_min = minf(x_min, minf(wall.start_point.x, wall.end_point.x))
			y_min = minf(y_min, minf(wall.start_point.y, wall.end_point.y))

	for wall in walls:
		if wall is WallSegmentData and wall.segment_id in wall_ids:
			var wall_copy = _copy_wall(wall)
			wall_copy.start_point.x -= x_min
			wall_copy.start_point.y -= y_min
			wall_copy.end_point.x -= x_min
			wall_copy.end_point.y -= y_min
			_data.walls.append(wall_copy)


func get_content() -> ClipboardData:
	return _data


func get_paste_offset(cursor_cell: Vector2i) -> Vector2i:
	if _data == null:
		return Vector2i.ZERO
	return cursor_cell - _data.source_bounds.position


func clear() -> void:
	_data = null


func _ensure_data() -> void:
	if _data == null:
		_data = ClipboardData.new()


func _copy_object(src: MapObjectData) -> MapObjectData:
	var copy = MapObjectData.new()
	copy.object_id = src.object_id
	copy.object_type = src.object_type
	copy.display_name = src.display_name
	copy.position = src.position
	copy.grid_position = src.grid_position
	copy.rotation = src.rotation
	copy.scale = src.scale
	copy.sprite_path = src.sprite_path
	copy.z_index = src.z_index
	copy.collision_shape = src.collision_shape
	copy.custom_properties = src.custom_properties.duplicate(true)
	return copy


func _copy_wall(src: WallSegmentData) -> WallSegmentData:
	var copy = WallSegmentData.new()
	copy.segment_id = src.segment_id
	copy.start_point = src.start_point
	copy.end_point = src.end_point
	copy.wall_type = src.wall_type
	copy.height = src.height
	copy.thickness = src.thickness
	copy.block_flags = src.block_flags
	return copy
