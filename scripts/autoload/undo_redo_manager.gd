##
## UndoRedoManager — Command-pattern undo/redo autoload
## Manages a stack of Command objects with a configurable depth limit.
##
## NOTE: Command subclasses use untyped "var" for references to avoid
## cross-file parse-order issues with Resource classes.
##
extends Node


# =============================================================================
# Inner class: Command (base)
# =============================================================================

class Command:
	func execute() -> void:
		push_error("Command.execute() must be overridden")

	func undo() -> void:
		push_error("Command.undo() must be overridden")

	func get_description() -> String:
		return "Unknown command"


# =============================================================================
# Tile Commands
# =============================================================================

class PlaceTileCommand extends Command:
	var _layer  ## TerrainLayerData — untyped to avoid parse-order issues
	var _cell: Vector2i
	var _old_tile: Variant
	var _new_tile: Variant

	func _init(layer, cell: Vector2i, new_tile: Variant) -> void:
		_layer = layer
		_cell = cell
		_new_tile = new_tile
		_old_tile = _layer.tiles.get(_cell)

	func execute() -> void:
		_layer.tiles[_cell] = _new_tile
		EventBus.tile_placed.emit(_cell, _new_tile, _layer.layer_index)

	func undo() -> void:
		if _old_tile == null:
			_layer.tiles.erase(_cell)
			EventBus.tile_removed.emit(_cell, _layer.layer_index)
		else:
			_layer.tiles[_cell] = _old_tile
			EventBus.tile_placed.emit(_cell, _old_tile, _layer.layer_index)

	func get_description() -> String:
		return "Placed tile at (%d, %d)" % [_cell.x, _cell.y]


class RemoveTileCommand extends Command:
	var _layer  ## TerrainLayerData
	var _cell: Vector2i
	var _old_tile: Variant

	func _init(layer, cell: Vector2i) -> void:
		_layer = layer
		_cell = cell
		_old_tile = _layer.tiles.get(_cell)

	func execute() -> void:
		_layer.tiles.erase(_cell)
		EventBus.tile_removed.emit(_cell, _layer.layer_index)

	func undo() -> void:
		if _old_tile != null:
			_layer.tiles[_cell] = _old_tile
			EventBus.tile_placed.emit(_cell, _old_tile, _layer.layer_index)

	func get_description() -> String:
		return "Removed tile at (%d, %d)" % [_cell.x, _cell.y]


class LinePlaceCommand extends Command:
	var _layer  ## TerrainLayerData
	var _cells: Array[Vector2i] = []
	var _new_tile: Variant
	var _old_tiles: Array = []  ## Array of {cell: Vector2i, tile: Variant|null}

	func _init(layer, cells: Array[Vector2i], new_tile: Variant) -> void:
		_layer = layer
		_cells = cells
		_new_tile = new_tile
		for cell in _cells:
			_old_tiles.append({cell = cell, tile = _layer.tiles.get(cell)})

	func execute() -> void:
		for cell in _cells:
			_layer.tiles[cell] = _new_tile
		for i in range(_cells.size()):
			EventBus.tile_placed.emit(_cells[i], _new_tile, _layer.layer_index)

	func undo() -> void:
		for entry in _old_tiles:
			var cell = entry.cell
			var old = entry.tile
			if old == null:
				_layer.tiles.erase(cell)
				EventBus.tile_removed.emit(cell, _layer.layer_index)
			else:
				_layer.tiles[cell] = old
				EventBus.tile_placed.emit(cell, old, _layer.layer_index)

	func get_description() -> String:
		return "Drew line of %d tiles" % _cells.size()


class RectFillCommand extends Command:
	var _layer  ## TerrainLayerData
	var _cells: Array[Vector2i] = []
	var _new_tile: Variant
	var _old_tiles: Array = []

	func _init(layer, cells: Array[Vector2i], new_tile: Variant) -> void:
		_layer = layer
		_cells = cells
		_new_tile = new_tile
		for cell in _cells:
			_old_tiles.append({cell = cell, tile = _layer.tiles.get(cell)})

	func execute() -> void:
		for cell in _cells:
			_layer.tiles[cell] = _new_tile
		for i in range(_cells.size()):
			EventBus.tile_placed.emit(_cells[i], _new_tile, _layer.layer_index)

	func undo() -> void:
		for entry in _old_tiles:
			var cell = entry.cell
			var old = entry.tile
			if old == null:
				_layer.tiles.erase(cell)
				EventBus.tile_removed.emit(cell, _layer.layer_index)
			else:
				_layer.tiles[cell] = old
				EventBus.tile_placed.emit(cell, old, _layer.layer_index)

	func get_description() -> String:
		return "Filled rectangle of %d tiles" % _cells.size()


class FloodFillCommand extends Command:
	var _layer  ## TerrainLayerData
	var _cells: Array[Vector2i] = []
	var _new_tile: Variant
	var _old_tiles: Array = []

	func _init(layer, cells: Array[Vector2i], new_tile: Variant) -> void:
		_layer = layer
		_cells = cells
		_new_tile = new_tile
		for cell in _cells:
			_old_tiles.append({cell = cell, tile = _layer.tiles.get(cell)})

	func execute() -> void:
		for cell in _cells:
			_layer.tiles[cell] = _new_tile
		for i in range(_cells.size()):
			EventBus.tile_placed.emit(_cells[i], _new_tile, _layer.layer_index)

	func undo() -> void:
		for entry in _old_tiles:
			var cell = entry.cell
			var old = entry.tile
			if old == null:
				_layer.tiles.erase(cell)
				EventBus.tile_removed.emit(cell, _layer.layer_index)
			else:
				_layer.tiles[cell] = old
				EventBus.tile_placed.emit(cell, old, _layer.layer_index)

	func get_description() -> String:
		return "Flood-filled %d tiles" % _cells.size()


# =============================================================================
# Object Commands
# =============================================================================

class PlaceObjectCommand extends Command:
	var _floor  ## FloorData
	var _object: MapObjectData

	func _init(floor_data, object: MapObjectData) -> void:
		_floor = floor_data
		_object = object

	func execute() -> void:
		_floor.objects.append(_object)
		EventBus.object_placed.emit(_object.position, _object.object_type, {})

	func undo() -> void:
		_floor.objects.erase(_object)
		EventBus.object_removed.emit(_object.object_id)

	func get_description() -> String:
		return "Placed object '%s'" % _object.display_name


class RemoveObjectCommand extends Command:
	var _floor  ## FloorData
	var _object: MapObjectData
	var _index: int = -1

	func _init(floor_data, object: MapObjectData) -> void:
		_floor = floor_data
		_object = object
		_index = _floor.objects.find(_object)

	func execute() -> void:
		if _index >= 0 and _index < _floor.objects.size():
			_floor.objects.remove_at(_index)
		else:
			_floor.objects.erase(_object)
		EventBus.object_removed.emit(_object.object_id)

	func undo() -> void:
		if _index >= 0 and _index <= _floor.objects.size():
			_floor.objects.insert(_index, _object)
		else:
			_floor.objects.append(_object)
		EventBus.object_placed.emit(_object.position, _object.object_type, {})

	func get_description() -> String:
		return "Removed object '%s'" % _object.display_name


class MoveObjectCommand extends Command:
	var _object: MapObjectData
	var _old_position: Vector2
	var _new_position: Vector2
	var _old_grid_position: Vector2i
	var _new_grid_position: Vector2i

	func _init(object: MapObjectData, new_pos: Vector2, new_grid: Vector2i) -> void:
		_object = object
		_old_position = object.position
		_old_grid_position = object.grid_position
		_new_position = new_pos
		_new_grid_position = new_grid

	func execute() -> void:
		_object.position = _new_position
		_object.grid_position = _new_grid_position

	func undo() -> void:
		_object.position = _old_position
		_object.grid_position = _old_grid_position

	func get_description() -> String:
		return "Moved object '%s'" % _object.display_name


# =============================================================================
# Wall Commands
# =============================================================================

class PlaceWallCommand extends Command:
	var _floor  ## FloorData
	var _wall: WallSegmentData

	func _init(floor_data, wall: WallSegmentData) -> void:
		_floor = floor_data
		_wall = wall

	func execute() -> void:
		_floor.walls.append(_wall)
		EventBus.obstacle_placed.emit(_wall.segment_id, _wall.block_flags)

	func undo() -> void:
		_floor.walls.erase(_wall)
		EventBus.obstacle_removed.emit(_wall.segment_id)

	func get_description() -> String:
		return "Placed wall segment '%s'" % _wall.segment_id


class RemoveWallCommand extends Command:
	var _floor  ## FloorData
	var _wall: WallSegmentData
	var _index: int = -1

	func _init(floor_data, wall: WallSegmentData) -> void:
		_floor = floor_data
		_wall = wall
		_index = _floor.walls.find(_wall)

	func execute() -> void:
		if _index >= 0 and _index < _floor.walls.size():
			_floor.walls.remove_at(_index)
		else:
			_floor.walls.erase(_wall)
		EventBus.obstacle_removed.emit(_wall.segment_id)

	func undo() -> void:
		if _index >= 0 and _index <= _floor.walls.size():
			_floor.walls.insert(_index, _wall)
		else:
			_floor.walls.append(_wall)
		EventBus.obstacle_placed.emit(_wall.segment_id, _wall.block_flags)

	func get_description() -> String:
		return "Removed wall segment '%s'" % _wall.segment_id


class MoveWallEndpointCommand extends Command:
	var _wall: WallSegmentData
	var _which: String  ## "start" or "end"
	var _old_point: Vector2
	var _new_point: Vector2

	func _init(wall: WallSegmentData, which: String, new_point: Vector2) -> void:
		_wall = wall
		_which = which
		if _which == "start":
			_old_point = wall.start_point
		else:
			_old_point = wall.end_point
		_new_point = new_point

	func execute() -> void:
		if _which == "start":
			_wall.start_point = _new_point
		else:
			_wall.end_point = _new_point
		EventBus.obstacle_updated.emit(_wall.segment_id, _wall.block_flags)

	func undo() -> void:
		if _which == "start":
			_wall.start_point = _old_point
		else:
			_wall.end_point = _old_point
		EventBus.obstacle_updated.emit(_wall.segment_id, _wall.block_flags)

	func get_description() -> String:
		return "Moved wall endpoint"


# =============================================================================
# Floor Commands
# =============================================================================

class AddFloorCommand extends Command:
	var _map  ## MapData
	var _floor: FloorData
	var _index: int

	func _init(map_data, floor_data: FloorData) -> void:
		_map = map_data
		_floor = floor_data
		_index = _map.floors.size()

	func execute() -> void:
		_map.floors.append(_floor)
		_map.current_floor = _index
		EventBus.floor_added.emit(_index)

	func undo() -> void:
		_map.floors.remove_at(_index)
		if _map.floors.is_empty():
			_map.current_floor = 0
		elif _map.current_floor >= _map.floors.size():
			_map.current_floor = _map.floors.size() - 1
		EventBus.floor_removed.emit(_index)

	func get_description() -> String:
		return "Added floor '%s'" % _floor.floor_name


class RemoveFloorCommand extends Command:
	var _map  ## MapData
	var _floor: FloorData
	var _index: int
	var _old_current: int

	func _init(map_data, floor_data: FloorData) -> void:
		_map = map_data
		_floor = floor_data
		_index = _map.floors.find(floor_data)
		_old_current = _map.current_floor

	func execute() -> void:
		_map.floors.remove_at(_index)
		if _map.floors.is_empty():
			_map.current_floor = 0
		elif _map.current_floor >= _map.floors.size():
			_map.current_floor = _map.floors.size() - 1
		EventBus.floor_removed.emit(_index)

	func undo() -> void:
		_map.floors.insert(_index, _floor)
		_map.current_floor = _old_current
		EventBus.floor_added.emit(_index)

	func get_description() -> String:
		return "Removed floor '%s'" % _floor.floor_name


class DuplicateFloorCommand extends Command:
	var _map  ## MapData
	var _source_index: int
	var _new_floor: FloorData
	var _new_index: int

	func _init(map_data, source_index: int, new_floor: FloorData) -> void:
		_map = map_data
		_source_index = source_index
		_new_floor = new_floor
		_new_index = _map.floors.size()

	func execute() -> void:
		_map.floors.append(_new_floor)
		_map.current_floor = _new_index
		EventBus.floor_added.emit(_new_index)

	func undo() -> void:
		_map.floors.remove_at(_new_index)
		_map.current_floor = _source_index
		EventBus.floor_removed.emit(_new_index)

	func get_description() -> String:
		return "Duplicated floor to '%s'" % _new_floor.floor_name


class ReorderFloorCommand extends Command:
	var _map  ## MapData
	var _from_index: int
	var _to_index: int
	var _old_current: int

	func _init(map_data, from_index: int, to_index: int) -> void:
		_map = map_data
		_from_index = from_index
		_to_index = to_index
		_old_current = map_data.current_floor

	func execute() -> void:
		var f = _map.floors.pop_at(_from_index)
		_map.floors.insert(_to_index, f)
		_map.current_floor = _to_index
		EventBus.floor_changed.emit(_old_current, _to_index)

	func undo() -> void:
		var f = _map.floors.pop_at(_to_index)
		_map.floors.insert(_from_index, f)
		_map.current_floor = _old_current
		EventBus.floor_changed.emit(_to_index, _old_current)

	func get_description() -> String:
		return "Reordered floors"


# =============================================================================
# Layer Commands
# =============================================================================

class AddLayerCommand extends Command:
	var _floor  ## FloorData
	var _layer: TerrainLayerData
	var _index: int

	func _init(floor_data, layer: TerrainLayerData) -> void:
		_floor = floor_data
		_layer = layer
		_index = floor_data.terrain_layers.size()

	func execute() -> void:
		_floor.terrain_layers.append(_layer)

	func undo() -> void:
		_floor.terrain_layers.remove_at(_index)

	func get_description() -> String:
		return "Added layer '%s'" % _layer.layer_name


class RemoveLayerCommand extends Command:
	var _floor  ## FloorData
	var _layer: TerrainLayerData
	var _index: int

	func _init(floor_data, layer: TerrainLayerData) -> void:
		_floor = floor_data
		_layer = layer
		_index = floor_data.terrain_layers.find(layer)

	func execute() -> void:
		_floor.terrain_layers.remove_at(_index)

	func undo() -> void:
		_floor.terrain_layers.insert(_index, _layer)

	func get_description() -> String:
		return "Removed layer '%s'" % _layer.layer_name


class ReorderLayerCommand extends Command:
	var _floor  ## FloorData
	var _from_index: int
	var _to_index: int

	func _init(floor_data, from_index: int, to_index: int) -> void:
		_floor = floor_data
		_from_index = from_index
		_to_index = to_index

	func execute() -> void:
		var layer = _floor.terrain_layers.pop_at(_from_index)
		_floor.terrain_layers.insert(_to_index, layer)

	func undo() -> void:
		var layer = _floor.terrain_layers.pop_at(_to_index)
		_floor.terrain_layers.insert(_from_index, layer)

	func get_description() -> String:
		return "Reordered layers"


# =============================================================================
# Portal Commands
# =============================================================================

class CreatePortalCommand extends Command:
	var _map  ## MapData
	var _portal: PortalData

	func _init(map_data, portal: PortalData) -> void:
		_map = map_data
		_portal = portal

	func execute() -> void:
		_map.portals.append(_portal)
		EventBus.portal_created.emit(_portal)

	func undo() -> void:
		_map.portals.erase(_portal)

	func get_description() -> String:
		return "Created portal '%s'" % _portal.portal_name


class RemovePortalCommand extends Command:
	var _map  ## MapData
	var _portal: PortalData
	var _index: int = -1

	func _init(map_data, portal: PortalData) -> void:
		_map = map_data
		_portal = portal
		_index = _map.portals.find(portal)

	func execute() -> void:
		if _index >= 0 and _index < _map.portals.size():
			_map.portals.remove_at(_index)
		else:
			_map.portals.erase(_portal)

	func undo() -> void:
		if _index >= 0 and _index <= _map.portals.size():
			_map.portals.insert(_index, _portal)
		else:
			_map.portals.append(_portal)
		EventBus.portal_created.emit(_portal)

	func get_description() -> String:
		return "Removed portal '%s'" % _portal.portal_name


# =============================================================================
# Light Commands
# =============================================================================

class PlaceLightCommand extends Command:
	var _floor  ## FloorData
	var _light: LightData

	func _init(floor_data, light: LightData) -> void:
		_floor = floor_data
		_light = light

	func execute() -> void:
		_floor.floor_lights.append(_light)
		EventBus.light_source_updated.emit(_light.light_id)

	func undo() -> void:
		_floor.floor_lights.erase(_light)

	func get_description() -> String:
		return "Placed light '%s'" % _light.light_name


class RemoveLightCommand extends Command:
	var _floor  ## FloorData
	var _light: LightData
	var _index: int = -1

	func _init(floor_data, light: LightData) -> void:
		_floor = floor_data
		_light = light
		_index = floor_data.floor_lights.find(light)

	func execute() -> void:
		if _index >= 0 and _index < _floor.floor_lights.size():
			_floor.floor_lights.remove_at(_index)
		else:
			_floor.floor_lights.erase(_light)

	func undo() -> void:
		if _index >= 0 and _index <= _floor.floor_lights.size():
			_floor.floor_lights.insert(_index, _light)
		else:
			_floor.floor_lights.append(_light)
		EventBus.light_source_updated.emit(_light.light_id)

	func get_description() -> String:
		return "Removed light '%s'" % _light.light_name


# =============================================================================
# Stair Commands
# =============================================================================

class AddStairCommand extends Command:
	var _map  ## MapData
	var _stair: StairConnectionData

	func _init(map_data, stair: StairConnectionData) -> void:
		_map = map_data
		_stair = stair

	func execute() -> void:
		_map.stair_connections.append(_stair)

	func undo() -> void:
		_map.stair_connections.erase(_stair)

	func get_description() -> String:
		return "Added stair connection '%s'" % _stair.stair_name


class RemoveStairCommand extends Command:
	var _map  ## MapData
	var _stair: StairConnectionData
	var _index: int = -1

	func _init(map_data, stair: StairConnectionData) -> void:
		_map = map_data
		_stair = stair
		_index = _map.stair_connections.find(stair)

	func execute() -> void:
		if _index >= 0 and _index < _map.stair_connections.size():
			_map.stair_connections.remove_at(_index)
		else:
			_map.stair_connections.erase(_stair)

	func undo() -> void:
		if _index >= 0 and _index <= _map.stair_connections.size():
			_map.stair_connections.insert(_index, _stair)
		else:
			_map.stair_connections.append(_stair)

	func get_description() -> String:
		return "Removed stair connection '%s'" % _stair.stair_name


# =============================================================================
# UndoRedoManager
# =============================================================================

const MAX_DEPTH = 100

var _undo_stack: Array = []   ## Array[Command]
var _redo_stack: Array = []   ## Array[Command]

@warning_ignore("unused_signal")
signal stack_changed(can_undo, can_redo, undo_desc, redo_desc)


func execute_command(cmd: Command) -> void:
	cmd.execute()
	_undo_stack.push_back(cmd)
	_redo_stack.clear()

	while _undo_stack.size() > MAX_DEPTH:
		_undo_stack.pop_front()

	_emit_stack_changed()


func undo() -> void:
	if _undo_stack.is_empty():
		return

	var cmd: Command = _undo_stack.pop_back()
	cmd.undo()
	_redo_stack.push_back(cmd)
	_emit_stack_changed()


func redo() -> void:
	if _redo_stack.is_empty():
		return

	var cmd: Command = _redo_stack.pop_back()
	cmd.execute()
	_undo_stack.push_back(cmd)
	_emit_stack_changed()


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


func get_undo_description() -> String:
	if _undo_stack.is_empty():
		return ""
	return (_undo_stack[_undo_stack.size() - 1] as Command).get_description()


func get_redo_description() -> String:
	if _redo_stack.is_empty():
		return ""
	return (_redo_stack[_redo_stack.size() - 1] as Command).get_description()


func _emit_stack_changed() -> void:
	stack_changed.emit(can_undo(), can_redo(), get_undo_description(), get_redo_description())
