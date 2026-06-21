##
## UndoRedoManager — Command-pattern undo/redo autoload
## Manages a stack of Command objects with a configurable depth limit.
##
## NOTE: PlaceTileCommand and RemoveTileCommand use untyped "var" for
## _layer to avoid cross-file parse-order issues with TerrainLayerData.
##
extends Node


# ---------- Inner class: Command ----------
class Command:
	func execute() -> void:
		push_error("Command.execute() must be overridden")

	func undo() -> void:
		push_error("Command.undo() must be overridden")

	func get_description() -> String:
		return "Unknown command"


# ---------- Inner class: PlaceTileCommand ----------
class PlaceTileCommand extends Command:
	var _layer  ## TerrainLayerData — use untyped to avoid cross-file parse issues
	var _cell: Vector2i
	var _old_tile: Variant   ## null or Dictionary if cell was occupied
	var _new_tile: Variant   ## Dictionary with tile data

	func _init(layer, cell: Vector2i, new_tile: Variant) -> void:
		_layer = layer
		_cell = cell
		_new_tile = new_tile
		_old_tile = _layer.tiles.get(_cell)  # null if empty

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


# ---------- Inner class: RemoveTileCommand ----------
class RemoveTileCommand extends Command:
	var _layer  ## TerrainLayerData — use untyped to avoid cross-file parse issues
	var _cell: Vector2i
	var _old_tile: Variant   ## null or Dictionary — the tile that was there before removal

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


# ---------- UndoRedoManager ----------
const MAX_DEPTH = 100

var _undo_stack: Array = []   ## Array[Command]
var _redo_stack: Array = []   ## Array[Command]

## Signals for UI to observe stack state
@warning_ignore("unused_signal")
signal stack_changed(can_undo, can_redo, undo_desc, redo_desc)


## Execute a command, push it onto the undo stack, and clear the redo stack.
func execute_command(cmd: Command) -> void:
	cmd.execute()
	_undo_stack.push_back(cmd)
	_redo_stack.clear()

	# Enforce depth limit
	while _undo_stack.size() > MAX_DEPTH:
		_undo_stack.pop_front()

	_emit_stack_changed()


## Undo the most recent command.
func undo() -> void:
	if _undo_stack.is_empty():
		return

	var cmd: Command = _undo_stack.pop_back()
	cmd.undo()
	_redo_stack.push_back(cmd)
	_emit_stack_changed()


## Redo the most recently undone command.
func redo() -> void:
	if _redo_stack.is_empty():
		return

	var cmd: Command = _redo_stack.pop_back()
	cmd.execute()
	_undo_stack.push_back(cmd)
	_emit_stack_changed()


## Returns true if there is at least one undoable command.
func can_undo() -> bool:
	return not _undo_stack.is_empty()


## Returns true if there is at least one redoable command.
func can_redo() -> bool:
	return not _redo_stack.is_empty()


## Returns the description of the next undo command, or empty string.
func get_undo_description() -> String:
	if _undo_stack.is_empty():
		return ""
	return (_undo_stack[_undo_stack.size() - 1] as Command).get_description()


## Returns the description of the next redo command, or empty string.
func get_redo_description() -> String:
	if _redo_stack.is_empty():
		return ""
	return (_redo_stack[_redo_stack.size() - 1] as Command).get_description()


## Emit stack_changed signal with current state.
func _emit_stack_changed() -> void:
	stack_changed.emit(can_undo(), can_redo(), get_undo_description(), get_redo_description())
