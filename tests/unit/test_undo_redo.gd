##
## test_undo_redo.gd — Unit tests for UndoRedoManager and command subclasses.
##
class_name TestUndoRedo
extends RefCounted


var _runner: Node


func run_tests(runner: Node) -> void:
	_runner = runner
	print("")
	print("--- test_undo_redo.gd ---")
	test_place_tile_undo()
	test_place_tile_redo()
	test_multiple_commands_undo()
	test_redo_cleared_on_new_command()
	print("--- test_undo_redo.gd PASSED ---")


func assert_eq(actual, expected, msg = "") -> bool:
	return _runner.assert_eq(actual, expected, msg)


func assert_true(cond, msg = "") -> bool:
	return _runner.assert_true(cond, msg)


func test_place_tile_undo() -> void:
	var layer = TerrainLayerData.new()
	var cell = Vector2i(3, 3)
	var tile_data = {"id": 1}

	var cmd = UndoRedoManager.PlaceTileCommand.new(layer, cell, tile_data)
	UndoRedoManager.execute_command(cmd)
	assert_true(layer.tiles.has(cell), "tile placed")
	assert_eq(layer.tiles[cell]["id"], 1, "tile id correct")

	UndoRedoManager.undo()
	assert_eq(layer.tiles.has(cell), false, "tile removed after undo")


func test_place_tile_redo() -> void:
	var layer = TerrainLayerData.new()
	var cell = Vector2i(7, 2)
	var tile_data = {"id": 2}

	var cmd = UndoRedoManager.PlaceTileCommand.new(layer, cell, tile_data)
	UndoRedoManager.execute_command(cmd)
	UndoRedoManager.undo()
	UndoRedoManager.redo()
	assert_true(layer.tiles.has(cell), "tile re-placed after redo")
	assert_eq(layer.tiles[cell]["id"], 2, "tile id after redo")


func test_multiple_commands_undo() -> void:
	var layer = TerrainLayerData.new()

	var cmd1 = UndoRedoManager.PlaceTileCommand.new(layer, Vector2i(0, 0), {"id": 1})
	var cmd2 = UndoRedoManager.PlaceTileCommand.new(layer, Vector2i(1, 0), {"id": 2})
	var cmd3 = UndoRedoManager.PlaceTileCommand.new(layer, Vector2i(2, 0), {"id": 3})

	UndoRedoManager.execute_command(cmd1)
	UndoRedoManager.execute_command(cmd2)
	UndoRedoManager.execute_command(cmd3)

	assert_eq(layer.tiles.size(), 3, "three tiles placed")

	UndoRedoManager.undo()
	assert_eq(layer.tiles.size(), 2, "two tiles after one undo")

	UndoRedoManager.undo()
	assert_eq(layer.tiles.size(), 1, "one tile after two undos")

	UndoRedoManager.undo()
	assert_eq(layer.tiles.is_empty(), true, "no tiles after three undos")


func test_redo_cleared_on_new_command() -> void:
	var layer = TerrainLayerData.new()

	var cmd1 = UndoRedoManager.PlaceTileCommand.new(layer, Vector2i(0, 0), {"id": 1})
	UndoRedoManager.execute_command(cmd1)
	UndoRedoManager.undo()

	var cmd2 = UndoRedoManager.PlaceTileCommand.new(layer, Vector2i(5, 5), {"id": 4})
	UndoRedoManager.execute_command(cmd2)

	assert_eq(layer.tiles.size(), 2, "two tiles after new command (undo was wiped)")
