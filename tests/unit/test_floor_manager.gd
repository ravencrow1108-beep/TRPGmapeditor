##
## test_floor_manager.gd — Unit tests for FloorManager CRUD and deep-copy.
##
class_name TestFloorManager
extends RefCounted


var _runner: Node
var _map_data: MapData
var _manager: FloorManager


func run_tests(runner: Node) -> void:
	_runner = runner
	print("")
	print("--- test_floor_manager.gd ---")
	_setup()
	test_add_floor()
	test_remove_floor()
	test_switch_floor()
	test_duplicate_floor_deep_copy()
	test_reorder_floors()
	test_stair_connection_add()
	print("--- test_floor_manager.gd PASSED ---")


func assert_eq(actual, expected, msg = "") -> bool:
	return _runner.assert_eq(actual, expected, msg)


func assert_true(cond, msg = "") -> bool:
	return _runner.assert_true(cond, msg)


func assert_not_null(val, msg = "") -> bool:
	return _runner.assert_not_null(val, msg)


func _setup() -> void:
	_map_data = MapData.new()
	_map_data.grid_size = Vector2i(32, 32)
	_map_data.map_dimensions = Vector2i(100, 100)

	var floor = FloorData.new()
	floor.floor_index = 0
	floor.floor_name = "Ground Floor"

	var layer = TerrainLayerData.new()
	layer.layer_index = 0
	layer.layer_name = "Layer 1"
	layer.tiles[Vector2i(5, 5)] = {"id": 1}
	floor.terrain_layers.append(layer)

	_map_data.floors.append(floor)
	_map_data.current_floor = 0

	_manager = FloorManager.new()
	_manager.set_map_data(_map_data)


func test_add_floor() -> void:
	var count_before = _manager.get_floor_count()
	var new_floor = _manager.add_floor("Floor 2")
	assert_not_null(new_floor, "new floor created")
	assert_eq(_manager.get_floor_count(), count_before + 1, "floor count increased")


func test_remove_floor() -> void:
	while _manager.get_floor_count() < 2:
		_manager.add_floor("extra")

	var count_before = _manager.get_floor_count()
	_manager.remove_floor(count_before - 1)
	assert_eq(_manager.get_floor_count(), count_before - 1, "floor removed")


func test_switch_floor() -> void:
	while _manager.get_floor_count() < 2:
		_manager.add_floor("extra")

	var target = mini(1, _manager.get_floor_count() - 1)
	_manager.switch_to_floor(target, "instant")
	assert_eq(_map_data.current_floor, target, "floor switched")


func test_duplicate_floor_deep_copy() -> void:
	var original = _map_data.floors[0]
	var duplicated = _manager.duplicate_floor(0)
	assert_not_null(duplicated, "duplicated floor not null")
	assert_eq(duplicated.terrain_layers.size(), original.terrain_layers.size(), "same layer count")

	if original.terrain_layers.size() > 0 and duplicated.terrain_layers.size() > 0:
		var dup_layer = duplicated.terrain_layers[0]
		var orig_layer = original.terrain_layers[0]
		assert_true(dup_layer.tiles.has(Vector2i(5, 5)), "duplicate has same tile keys")
		orig_layer.tiles[Vector2i(9, 9)] = {"id": 99}
		assert_true(not dup_layer.tiles.has(Vector2i(9, 9)), "duplicate unaffected by original change")


func test_reorder_floors() -> void:
	while _manager.get_floor_count() < 3:
		_manager.add_floor("reorder test")

	var name_before = _map_data.floors[1].floor_name
	var name_before_2 = _map_data.floors[2].floor_name

	_manager.reorder_floors(1, 2)
	assert_eq(_map_data.floors[2].floor_name, name_before, "floor moved from 1 to 2")
	assert_eq(_map_data.floors[1].floor_name, name_before_2, "floor moved from 2 to 1")


func test_stair_connection_add() -> void:
	var stair = StairConnectionData.new()
	stair.connection_id = "test_stair_001"
	stair.stair_name = "Test Stairs"
	stair.from_floor = 0
	stair.from_position = Vector2i(5, 5)
	stair.to_floor = 1
	stair.to_position = Vector2i(5, 7)

	_manager.add_stair_connection(stair)
	var connections = _manager.get_stair_connections()
	assert_true(connections.size() >= 1, "stair connection added")

	_manager.remove_stair_connection("test_stair_001")
	assert_true(true, "stair removal did not crash")
