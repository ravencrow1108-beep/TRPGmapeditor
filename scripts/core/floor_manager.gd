##
## FloorManager — Floor lifecycle manager.
## Handles floor CRUD, switching, thumbnails, and stair connections.
## Communicates via EventBus.
##
class_name FloorManager
extends Node


# ---------- Signals ----------

@warning_ignore("unused_signal")
signal floor_switch_start(from_index: int, to_index: int)
@warning_ignore("unused_signal")
signal floor_switch_complete(new_index: int)
@warning_ignore("unused_signal")
signal stairs_changed()


# ---------- Internal state ----------

var _map_data: MapData = null
var _display_adjacent: bool = false
var _adjacent_opacity: float = 0.25


# ---------- Public API ----------

func set_map_data(md: MapData) -> void:
	_map_data = md


func get_active_floor() -> FloorData:
	if _map_data == null:
		return null
	return _map_data.get_active_floor()


func get_floor_at(index: int) -> FloorData:
	if _map_data == null:
		return null
	if index < 0 or index >= _map_data.floors.size():
		return null
	return _map_data.floors[index]


func get_floor_count() -> int:
	if _map_data == null:
		return 0
	return _map_data.floors.size()


func get_current_floor_index() -> int:
	if _map_data == null:
		return 0
	return _map_data.current_floor


# ---------- Floor CRUD ----------

func add_floor(name: String = "") -> FloorData:
	if _map_data == null:
		return null

	var fd = FloorData.new()
	fd.floor_index = _map_data.floors.size()
	fd.floor_name = name if not name.is_empty() else "楼层 %d" % (fd.floor_index + 1)
	fd.floor_z = fd.floor_index

	var layer = TerrainLayerData.new()
	layer.layer_index = 0
	layer.layer_name = "图层 1"
	fd.terrain_layers.append(layer)

	var cmd = UndoRedoManager.AddFloorCommand.new(_map_data, fd)
	UndoRedoManager.execute_command(cmd)

	EventBus.floor_added.emit(fd.floor_index)
	return fd


func remove_floor(index: int) -> void:
	if _map_data == null or _map_data.floors.size() <= 1:
		return
	if index < 0 or index >= _map_data.floors.size():
		return

	var fd = _map_data.floors[index]
	var cmd = UndoRedoManager.RemoveFloorCommand.new(_map_data, fd)
	UndoRedoManager.execute_command(cmd)

	EventBus.floor_removed.emit(index)
	_reindex_floors()


func duplicate_floor(index: int) -> FloorData:
	if _map_data == null:
		return null
	if index < 0 or index >= _map_data.floors.size():
		return null

	var source = _map_data.floors[index]
	var copy = _deep_copy_floor(source)
	copy.floor_index = _map_data.floors.size()
	copy.floor_name = source.floor_name + " (副本)"
	copy.floor_z = copy.floor_index

	var cmd = UndoRedoManager.DuplicateFloorCommand.new(_map_data, index, copy)
	UndoRedoManager.execute_command(cmd)

	EventBus.floor_added.emit(copy.floor_index)
	return copy


func switch_to_floor(index: int, transition_type: String = "instant") -> void:
	if _map_data == null:
		return
	if index < 0 or index >= _map_data.floors.size():
		return
	if index == _map_data.current_floor:
		return

	var old_index = _map_data.current_floor
	floor_switch_start.emit(old_index, index)

	_map_data.current_floor = index
	EventBus.floor_changed.emit(old_index, index)

	if transition_type == "fade":
		_do_fade_transition()
	else:
		floor_switch_complete.emit(index)


func reorder_floors(from_index: int, to_index: int) -> void:
	if _map_data == null:
		return
	var count = _map_data.floors.size()
	if from_index < 0 or from_index >= count:
		return
	if to_index < 0 or to_index >= count:
		return
	if from_index == to_index:
		return

	var cmd = UndoRedoManager.ReorderFloorCommand.new(_map_data, from_index, to_index)
	UndoRedoManager.execute_command(cmd)
	_reindex_floors()


# ---------- Stair connections ----------

func get_stair_connections() -> Array[StairConnectionData]:
	if _map_data == null:
		return []
	return _map_data.stair_connections.duplicate()


func get_stairs_for_floor(floor_index: int) -> Array[StairConnectionData]:
	var result: Array[StairConnectionData] = []
	if _map_data == null:
		return result
	for stair in _map_data.stair_connections:
		if stair.from_floor == floor_index or stair.to_floor == floor_index:
			result.append(stair)
	return result


func add_stair_connection(stair: StairConnectionData) -> void:
	if _map_data == null:
		return
	var cmd = UndoRedoManager.AddStairCommand.new(_map_data, stair)
	UndoRedoManager.execute_command(cmd)
	stairs_changed.emit()


func remove_stair_connection(connection_id: String) -> void:
	if _map_data == null:
		return
	var stair = _find_stair_by_id(connection_id)
	if stair != null:
		var cmd = UndoRedoManager.RemoveStairCommand.new(_map_data, stair)
		UndoRedoManager.execute_command(cmd)
		stairs_changed.emit()


# ---------- Adjacent floors ----------

func set_display_adjacent(show: bool, opacity: float = 0.25) -> void:
	_display_adjacent = show
	_adjacent_opacity = clampf(opacity, 0.1, 0.5)


func get_display_adjacent() -> bool:
	return _display_adjacent


func get_adjacent_opacity() -> float:
	return _adjacent_opacity


# ---------- Thumbnails ----------

func get_floor_thumbnail(floor_index: int, thumb_size: Vector2i = Vector2i(128, 72)) -> Image:
	var fd = get_floor_at(floor_index)
	if fd == null or _map_data == null:
		return null

	var img = Image.create(thumb_size.x, thumb_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.15, 0.15, 0.15, 1.0))

	var scale_x: float = float(thumb_size.x) / float(_map_data.map_dimensions.x)
	var scale_y: float = float(thumb_size.y) / float(_map_data.map_dimensions.y)

	var palette = [
		Color(0.45, 0.60, 0.35, 0.9),
		Color(0.55, 0.45, 0.30, 0.95),
		Color(0.35, 0.40, 0.55, 0.9),
		Color(0.60, 0.55, 0.40, 0.9),
		Color(0.30, 0.45, 0.65, 0.9),
	]

	for layer in fd.terrain_layers:
		if not layer.visible:
			continue
		for cell in layer.tiles.keys():
			var tile_data = layer.tiles[cell]
			var tile_id: int = 0
			if tile_data is Dictionary:
				tile_id = tile_data.get("id", 0)
			var color: Color = palette[mini(tile_id, palette.size() - 1)]
			var tx: int = int(float(cell.x) * scale_x)
			var ty: int = int(float(cell.y) * scale_y)
			if tx >= 0 and tx < thumb_size.x and ty >= 0 and ty < thumb_size.y:
				img.set_pixel(tx, ty, color)

	return img


# ---------- Private helpers ----------

func _deep_copy_floor(source: FloorData) -> FloorData:
	var copy = FloorData.new()
	copy.floor_name = source.floor_name + " (副本)"
	copy.floor_z = source.floor_z + 1
	copy.elevation = source.elevation
	copy.visible = source.visible
	copy.locked = source.locked
	copy.opacity = source.opacity
	copy.tint_color = source.tint_color

	for src_layer in source.terrain_layers:
		var layer_copy = TerrainLayerData.new()
		layer_copy.layer_name = src_layer.layer_name
		layer_copy.layer_index = src_layer.layer_index
		layer_copy.visible = src_layer.visible
		layer_copy.locked = src_layer.locked
		layer_copy.opacity = src_layer.opacity
		layer_copy.tileset_ref = src_layer.tileset_ref
		layer_copy.tiles = src_layer.tiles.duplicate(true)
		copy.terrain_layers.append(layer_copy)

	for src_obj in source.objects:
		var obj_copy = MapObjectData.new()
		obj_copy.object_id = src_obj.object_id
		obj_copy.object_type = src_obj.object_type
		obj_copy.display_name = src_obj.display_name
		obj_copy.position = src_obj.position
		obj_copy.grid_position = src_obj.grid_position
		obj_copy.rotation = src_obj.rotation
		obj_copy.scale = src_obj.scale
		obj_copy.sprite_path = src_obj.sprite_path
		obj_copy.z_index = src_obj.z_index
		obj_copy.collision_shape = src_obj.collision_shape
		obj_copy.custom_properties = src_obj.custom_properties.duplicate(true)
		copy.objects.append(obj_copy)

	for src_wall in source.walls:
		var wall_copy = WallSegmentData.new()
		wall_copy.segment_id = src_wall.segment_id
		wall_copy.start_point = src_wall.start_point
		wall_copy.end_point = src_wall.end_point
		wall_copy.wall_type = src_wall.wall_type
		wall_copy.height = src_wall.height
		wall_copy.thickness = src_wall.thickness
		wall_copy.block_flags = src_wall.block_flags
		copy.walls.append(wall_copy)

	if source.fog_data:
		copy.fog_data.enabled = source.fog_data.enabled
		copy.fog_data.fog_type = source.fog_data.fog_type
		copy.fog_data.fog_color = source.fog_data.fog_color
		copy.fog_data.unexplored_color = source.fog_data.unexplored_color
		copy.fog_data.explored_color = source.fog_data.explored_color
		copy.fog_data.fog_transition_speed = source.fog_data.fog_transition_speed
		copy.fog_data.fog_grid = source.fog_data.fog_grid.duplicate(true)
		copy.fog_data.token_revealed = source.fog_data.token_revealed.duplicate(true)

	return copy


func _find_stair_by_id(connection_id: String) -> StairConnectionData:
	if _map_data == null:
		return null
	for stair in _map_data.stair_connections:
		if stair.connection_id == connection_id:
			return stair
	return null


func _reindex_floors() -> void:
	if _map_data == null:
		return
	for i in range(_map_data.floors.size()):
		var fd = _map_data.floors[i] as FloorData
		fd.floor_index = i


func _do_fade_transition() -> void:
	floor_switch_complete.emit(_map_data.current_floor if _map_data else 0)
