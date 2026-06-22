##
## test_grid_utils.gd — Unit tests for GridUtils coordinate math and algorithms.
##
class_name TestGridUtils
extends RefCounted


var _runner: Node


func run_tests(runner: Node) -> void:
	_runner = runner
	print("")
	print("--- test_grid_utils.gd ---")
	test_grid_to_world()
	test_world_to_grid()
	test_bresenham_horizontal()
	test_bresenham_diagonal()
	test_rect_cells()
	test_flood_fill_bounded()
	test_hex_offset_to_axial_pointy()
	test_hex_offset_to_axial_flat()
	test_hex_axial_to_offset()
	test_square_neighbors()
	test_hex_neighbors()
	test_snap_cell_center()
	test_snap_cell_intersection()
	print("--- test_grid_utils.gd PASSED ---")


func assert_eq(actual, expected, msg = "") -> bool:
	return _runner.assert_eq(actual, expected, msg)


func assert_true(cond, msg = "") -> bool:
	return _runner.assert_true(cond, msg)


func assert_not_null(val, msg = "") -> bool:
	return _runner.assert_not_null(val, msg)


func test_grid_to_world() -> void:
	var result = GridUtils.grid_to_world(Vector2i(3, 4), Vector2i(32, 32))
	assert_eq(result, Vector2(96.0, 128.0), "grid_to_world (3,4) with 32px")


func test_world_to_grid() -> void:
	var result = GridUtils.world_to_grid(Vector2(100.0, 120.0), Vector2i(32, 32), Vector2i(100, 100))
	assert_eq(result, Vector2i(3, 3), "world_to_grid (100,120)")


func test_bresenham_horizontal() -> void:
	var cells = GridUtils.bresenham_line(Vector2i(0, 2), Vector2i(4, 2))
	assert_eq(cells.size(), 5, "horizontal line 5 cells")
	assert_eq(cells[0], Vector2i(0, 2), "first cell")
	assert_eq(cells[4], Vector2i(4, 2), "last cell")


func test_bresenham_diagonal() -> void:
	var cells = GridUtils.bresenham_line(Vector2i(0, 0), Vector2i(3, 3))
	assert_eq(cells.size(), 4, "diagonal line 4 cells")
	assert_eq(cells[0], Vector2i(0, 0), "first")
	assert_eq(cells[3], Vector2i(3, 3), "last")


func test_rect_cells() -> void:
	var cells = GridUtils.rect_cells(Vector2i(0, 0), Vector2i(2, 1))
	assert_eq(cells.size(), 6, "3x2 rect = 6 cells")


func test_flood_fill_bounded() -> void:
	var can_fill = func(cell: Vector2i) -> bool:
		if cell.x < 0 or cell.x > 5 or cell.y < 0 or cell.y > 5:
			return false
		return true

	var cells = GridUtils.flood_fill(Vector2i(2, 2), can_fill, Rect2i(), 1000)
	assert_eq(cells.size(), 36, "flood fill 6x6 = 36 cells")


func test_hex_offset_to_axial_pointy() -> void:
	var axial = GridUtils.hex_offset_to_axial(Vector2i(3, 2), 1)
	assert_not_null(axial, "axial result not null")


func test_hex_offset_to_axial_flat() -> void:
	var axial = GridUtils.hex_offset_to_axial(Vector2i(2, 3), 2)
	assert_not_null(axial, "axial flat result not null")


func test_hex_axial_to_offset() -> void:
	var offset = Vector2i(4, 3)
	var axial = GridUtils.hex_offset_to_axial(offset, 1)
	var back = GridUtils.hex_axial_to_offset(axial, 1)
	assert_eq(back, offset, "hex offset-axial roundtrip pointy")

	var axial2 = GridUtils.hex_offset_to_axial(offset, 2)
	var back2 = GridUtils.hex_axial_to_offset(axial2, 2)
	assert_eq(back2, offset, "hex offset-axial roundtrip flat")


func test_square_neighbors() -> void:
	var neighbors = GridUtils.get_square_neighbors(Vector2i(5, 5), Vector2i(10, 10), true)
	assert_eq(neighbors.size(), 8, "8-connected neighbors at center")


func test_hex_neighbors() -> void:
	var neighbors = GridUtils.get_hex_neighbors(Vector2i(5, 5), 1)
	assert_eq(neighbors.size(), 6, "hex has 6 neighbors")


func test_snap_cell_center() -> void:
	var world = Vector2(75.0, 85.0)
	var snapped = GridUtils.snap_to_grid(world, Vector2i(32, 32), GridUtils.SnapMode.CELL_CENTER)
	assert_eq(snapped.x, 80.0, "snap to cell center x (cell 2)")
	assert_eq(snapped.y, 80.0, "snap to cell center y (cell 2)")


func test_snap_cell_intersection() -> void:
	var world = Vector2(51.0, 53.0)
	var snapped = GridUtils.snap_to_grid(world, Vector2i(32, 32), GridUtils.SnapMode.CELL_INTERSECTION)
	assert_true(absf(snapped.x - 64.0) < 1.0 or absf(snapped.x - 32.0) < 1.0, "snap intersection x")
