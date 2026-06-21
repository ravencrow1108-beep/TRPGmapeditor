##
## test_map_data.gd — Unit tests for MapData, TerrainLayerData, and serialization.
##
class_name TestMapData
extends RefCounted


var _runner: Node


func run_tests(runner: Node) -> void:
	_runner = runner
	print("")
	print("--- test_map_data.gd ---")
	test_map_data_defaults()
	test_add_floor()
	test_tile_placement()
	test_serialization_round_trip()
	print("--- test_map_data.gd PASSED ---")


func assert_eq(actual, expected, msg = "") -> bool:
	return _runner.assert_eq(actual, expected, msg)


func assert_true(cond, msg = "") -> bool:
	return _runner.assert_true(cond, msg)


func assert_not_null(val, msg = "") -> bool:
	return _runner.assert_not_null(val, msg)


# ---------- Tests ----------

func test_map_data_defaults() -> void:
	var md = MapData.new()
	assert_eq(md.map_name, "未命名地图", "map_name default")
	assert_eq(md.grid_size, Vector2i(32, 32), "grid_size default")
	assert_eq(md.map_dimensions, Vector2i(100, 100), "map_dimensions default")
	assert_eq(md.current_floor, 0, "current_floor default")
	assert_eq(md.grid_type, MapData.GridType.SQUARE, "grid_type default")
	assert_eq(md.floors.size(), 0, "floors empty by default")


func test_add_floor() -> void:
	var md = MapData.new()
	var floor = FloorData.new()
	floor.floor_index = 0
	floor.floor_name = "Test Floor"
	md.floors.append(floor)
	assert_eq(md.floors.size(), 1, "floor added")
	assert_eq(md.floors[0].floor_name, "Test Floor", "floor name correct")


func test_tile_placement() -> void:
	var layer = TerrainLayerData.new()
	var cell = Vector2i(5, 10)
	layer.tiles[cell] = {"id": 1}
	assert_true(layer.tiles.has(cell), "tile exists at (5,10)")
	assert_eq(layer.tiles[cell]["id"], 1, "tile id correct")
	layer.tiles[Vector2i(3, 4)] = {"id": 2}
	assert_eq(layer.tiles.size(), 2, "two tiles placed")
	layer.tiles.erase(cell)
	assert_eq(layer.tiles.has(cell), false, "tile removed")


func test_serialization_round_trip() -> void:
	var md = MapData.new()
	md.map_name = "Test Roundtrip Map"
	md.author = "Test Author"
	md.grid_size = Vector2i(32, 32)
	md.map_dimensions = Vector2i(50, 50)
	md.grid_type = MapData.GridType.SQUARE
	md.created_date = "2025-01-01T00:00:00"
	md.modified_date = "2025-01-01T00:00:00"
	md.description = "A test map for round-trip serialization"

	var floor = FloorData.new()
	floor.floor_index = 0
	floor.floor_name = "Ground Floor"

	var layer = TerrainLayerData.new()
	layer.layer_index = 0
	layer.layer_name = "Ground Layer"
	layer.tileset_ref = "default"
	layer.tiles[Vector2i(3, 4)] = {"id": 5}
	layer.tiles[Vector2i(7, 2)] = {"id": 3}
	floor.terrain_layers.append(layer)
	md.floors.append(floor)

	var path = "user://test_roundtrip.trpgmap"
	var saved_ok = SerializationManager.save_map(md, path)
	assert_true(saved_ok, "save_map succeeded")

	var loaded = SerializationManager.load_map(path)
	assert_not_null(loaded, "loaded map is not null")
	if loaded == null:
		return

	assert_eq(loaded.map_name, "Test Roundtrip Map", "map_name round-trip")
	assert_eq(loaded.author, "Test Author", "author round-trip")
	assert_eq(loaded.grid_size, Vector2i(32, 32), "grid_size round-trip")
	assert_eq(loaded.map_dimensions, Vector2i(50, 50), "map_dimensions round-trip")
	assert_eq(loaded.description, "A test map for round-trip serialization", "description round-trip")
	assert_eq(loaded.grid_type, MapData.GridType.SQUARE, "grid_type round-trip")
	assert_eq(loaded.floors.size(), 1, "floor count round-trip")

	var loaded_floor = loaded.floors[0]
	assert_not_null(loaded_floor, "floor not null")
	if loaded_floor == null:
		return
	assert_eq(loaded_floor.floor_name, "Ground Floor", "floor_name round-trip")
	assert_eq(loaded_floor.terrain_layers.size(), 1, "layer count round-trip")

	var loaded_layer = loaded_floor.terrain_layers[0]
	assert_not_null(loaded_layer, "layer not null")
	if loaded_layer == null:
		return
	assert_eq(loaded_layer.layer_name, "Ground Layer", "layer_name round-trip")
	assert_eq(loaded_layer.tileset_ref, "default", "tileset_ref round-trip")
	assert_eq(loaded_layer.tiles.size(), 2, "tile count round-trip")

	var tile_1 = loaded_layer.tiles.get(Vector2i(3, 4))
	assert_not_null(tile_1, "tile at (3,4) exists")
	if tile_1 != null:
		assert_eq(tile_1["id"], 5, "tile id at (3,4)")

	var tile_2 = loaded_layer.tiles.get(Vector2i(7, 2))
	assert_not_null(tile_2, "tile at (7,2) exists")
	if tile_2 != null:
		assert_eq(tile_2["id"], 3, "tile id at (7,2)")

	var key_exists = false
	for key in loaded_layer.tiles.keys():
		if key is Vector2i and key == Vector2i(3, 4):
			key_exists = true
			break
	assert_true(key_exists, "Vector2i key (3,4) survived serialization round-trip")
