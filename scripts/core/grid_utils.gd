##
## GridUtils — Static coordinate conversion and algorithm utilities.
## Single source of truth for all grid math — square and hex.
##
class_name GridUtils
extends RefCounted


# =============================================================================
# Square grid: world <-> grid
# =============================================================================

## Convert a grid cell coordinate to a world-space pixel position (top-left corner of cell).
static func grid_to_world(grid_pos: Vector2i, grid_size: Vector2i) -> Vector2:
	return Vector2(float(grid_pos.x) * grid_size.x, float(grid_pos.y) * grid_size.y)


## Convert a world-space pixel position to a grid cell coordinate.
## Clamps the result to [0, map_dims-1] if map_dims is provided and non-zero.
static func world_to_grid(world_pos: Vector2, grid_size: Vector2i, map_dims: Vector2i = Vector2i.ZERO) -> Vector2i:
	var gx: int = int(world_pos.x / float(grid_size.x))
	var gy: int = int(world_pos.y / float(grid_size.y))
	if world_pos.x < 0:
		gx -= 1
	if world_pos.y < 0:
		gy -= 1
	if map_dims.x > 0 and map_dims.y > 0:
		gx = clampi(gx, 0, map_dims.x - 1)
		gy = clampi(gy, 0, map_dims.y - 1)
	return Vector2i(gx, gy)


## Return the world-space Rect2 for a single grid cell.
static func get_cell_rect(grid_pos: Vector2i, grid_size: Vector2i) -> Rect2:
	return Rect2(grid_to_world(grid_pos, grid_size), Vector2(grid_size))


# =============================================================================
# Hex grid: offset <-> axial conversion
#   Reference: https://www.redblobgames.com/grids/hexagons/
#   HEX_POINTY = 1 (odd-r offset)
#   HEX_FLAT   = 2 (odd-q offset)
# =============================================================================

## Convert offset coordinates to axial coordinates.
static func hex_offset_to_axial(offset: Vector2i, grid_type: int) -> Vector2i:
	if grid_type == 1:  # HEX_POINTY — odd-r offset
		var q: int = offset.x - (offset.y - (offset.y & 1)) / 2
		var r: int = offset.y
		return Vector2i(q, r)
	else:  # HEX_FLAT — odd-q offset
		var q: int = offset.x
		var r: int = offset.y - (offset.x - (offset.x & 1)) / 2
		return Vector2i(q, r)


## Convert axial coordinates back to offset coordinates.
static func hex_axial_to_offset(axial: Vector2i, grid_type: int) -> Vector2i:
	if grid_type == 1:  # HEX_POINTY
		var col: int = axial.x + (axial.y - (axial.y & 1)) / 2
		var row: int = axial.y
		return Vector2i(col, row)
	else:  # HEX_FLAT
		var col: int = axial.x
		var row: int = axial.y + (axial.x - (axial.x & 1)) / 2
		return Vector2i(col, row)


# =============================================================================
# Hex grid: world <-> grid
# =============================================================================

## Convert a hex grid cell (offset coords) to a world-space pixel position.
static func hex_grid_to_world(grid_pos: Vector2i, grid_size: Vector2i, grid_type: int) -> Vector2:
	var w: float = float(grid_size.x)
	var h: float = float(grid_size.y)

	if grid_type == 1:  # HEX_POINTY — pointy-top
		var x: float = float(grid_pos.x) * w
		if grid_pos.y & 1:
			x += w * 0.5
		var y: float = float(grid_pos.y) * h * 0.75
		return Vector2(x, y)
	else:  # HEX_FLAT — flat-top
		var y: float = float(grid_pos.y) * h
		if grid_pos.x & 1:
			y += h * 0.5
		var x: float = float(grid_pos.x) * w * 0.75
		return Vector2(x, y)


## Convert a world-space pixel position to a hex grid cell (offset coords).
static func hex_world_to_grid(world_pos: Vector2, grid_size: Vector2i, grid_type: int, map_dims: Vector2i = Vector2i.ZERO) -> Vector2i:
	var w: float = float(grid_size.x)
	var h: float = float(grid_size.y)

	var col: int
	var row: int

	if grid_type == 1:  # HEX_POINTY
		row = int(round(world_pos.y / (h * 0.75)))
		if row & 1:
			col = int(round((world_pos.x - w * 0.5) / w))
		else:
			col = int(round(world_pos.x / w))
	else:  # HEX_FLAT
		col = int(round(world_pos.x / (w * 0.75)))
		if col & 1:
			row = int(round((world_pos.y - h * 0.5) / h))
		else:
			row = int(round(world_pos.y / h))

	if map_dims.x > 0 and map_dims.y > 0:
		col = clampi(col, 0, map_dims.x - 1)
		row = clampi(row, 0, map_dims.y - 1)

	return Vector2i(col, row)


## Return the vertices of a hex cell as a PackedVector2Array for draw_polyline().
static func get_hex_vertices(grid_pos: Vector2i, grid_size: Vector2i, grid_type: int) -> PackedVector2Array:
	var center: Vector2 = hex_grid_to_world(grid_pos, grid_size, grid_type)
	var w: float = float(grid_size.x)
	var h: float = float(grid_size.y)
	var vertices: PackedVector2Array = PackedVector2Array()

	if grid_type == 1:  # HEX_POINTY — pointy-top
		var rx: float = w * 0.5
		var ry: float = h * 0.5
		for i in range(6):
			var angle: float = deg_to_rad(60.0 * float(i) - 30.0)
			vertices.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	else:  # HEX_FLAT — flat-top
		var rx: float = w * 0.5
		var ry: float = h * 0.5
		for i in range(6):
			var angle: float = deg_to_rad(60.0 * float(i))
			vertices.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))

	return vertices


# =============================================================================
# Neighbors
# =============================================================================

## Return the 8-connected neighbors of a square cell.
## Set include_diagonals=false for 4-connected.
static func get_square_neighbors(cell: Vector2i, map_dims: Vector2i = Vector2i.ZERO, include_diagonals: bool = true) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
	]
	if include_diagonals:
		dirs.append_array([
			Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)
		])
	var result: Array[Vector2i] = []
	for d in dirs:
		var n: Vector2i = cell + d
		if map_dims.x <= 0 or map_dims.y <= 0:
			result.append(n)
		elif n.x >= 0 and n.x < map_dims.x and n.y >= 0 and n.y < map_dims.y:
			result.append(n)
	return result


## Return the 6 hex neighbor cells (offset coords).
## Works for both HEX_POINTY and HEX_FLAT.
static func get_hex_neighbors(cell: Vector2i, grid_type: int, map_dims: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	var axial: Vector2i = hex_offset_to_axial(cell, grid_type)
	var axial_neighbors: Array[Vector2i] = _get_hex_neighbors_axial(axial)
	var result: Array[Vector2i] = []
	for an in axial_neighbors:
		var offset: Vector2i = hex_axial_to_offset(an, grid_type)
		if map_dims.x <= 0 or map_dims.y <= 0:
			result.append(offset)
		elif offset.x >= 0 and offset.x < map_dims.x and offset.y >= 0 and offset.y < map_dims.y:
			result.append(offset)
	return result


## Return the 6 axial neighbors of an axial hex coordinate.
static func _get_hex_neighbors_axial(axial: Vector2i) -> Array[Vector2i]:
	var directions: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	var result: Array[Vector2i] = []
	for d in directions:
		result.append(axial + d)
	return result


# =============================================================================
# Algorithms
# =============================================================================

## Bresenham's line algorithm. Returns all cells along the line (inclusive).
static func bresenham_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = end.x
	var y1: int = end.y

	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = err * 2
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return cells


## Return all cells in the rectangle between two corner cells (inclusive).
static func rect_cells(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var x_min: int = mini(start.x, end.x)
	var x_max: int = maxi(start.x, end.x)
	var y_min: int = mini(start.y, end.y)
	var y_max: int = maxi(start.y, end.y)
	for x in range(x_min, x_max + 1):
		for y in range(y_min, y_max + 1):
			cells.append(Vector2i(x, y))
	return cells


## Flood-fill from start cell. Calls can_fill(cell) for each candidate;
## fills cells where the callback returns true.
## Optional bounds restricts the fill area.
## Optional max_cells caps the result to prevent runaway fills.
static func flood_fill(start: Vector2i, can_fill: Callable, bounds: Rect2i = Rect2i(), max_cells: int = 10000) -> Array[Vector2i]:
	var filled: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	var dirs: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
	]

	while not queue.is_empty() and filled.size() < max_cells:
		var cell: Vector2i = queue.pop_front()
		if bounds.has_area() and not bounds.has_point(cell):
			continue
		if not can_fill.call(cell):
			continue
		filled.append(cell)
		for d in dirs:
			var neighbor: Vector2i = cell + d
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	return filled


# =============================================================================
# Distance
# =============================================================================

## Manhattan distance on a square grid.
static func distance_grid(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Hex distance using axial coordinates. Works for both hex grid types.
static func distance_hex(a: Vector2i, b: Vector2i, grid_type: int) -> int:
	var aa: Vector2i = hex_offset_to_axial(a, grid_type)
	var ba: Vector2i = hex_offset_to_axial(b, grid_type)
	var dq: int = absi(aa.x - ba.x)
	var dr: int = absi(aa.y - ba.y)
	var ds: int = absi(-aa.x - aa.y + ba.x + ba.y)
	return maxi(dq, maxi(dr, ds))


# =============================================================================
# Snap-to-grid helpers
# =============================================================================

enum SnapMode {
	CELL_CENTER,         ## Snap to center of the cell
	CELL_INTERSECTION,   ## Snap to nearest grid-line intersection
	CELL_CORNER          ## Snap to top-left corner of the cell
}

## Snap a world position to the nearest grid point based on the snap mode.
static func snap_to_grid(world_pos: Vector2, grid_size: Vector2i, mode: int = SnapMode.CELL_CENTER) -> Vector2:
	var gx: float = float(grid_size.x)
	var gy: float = float(grid_size.y)

	match mode:
		SnapMode.CELL_CENTER:
			var col: int = int(world_pos.x / gx)
			var row: int = int(world_pos.y / gy)
			if world_pos.x < 0:
				col -= 1
			if world_pos.y < 0:
				row -= 1
			return Vector2((float(col) + 0.5) * gx, (float(row) + 0.5) * gy)

		SnapMode.CELL_INTERSECTION:
			return Vector2(round(world_pos.x / gx) * gx, round(world_pos.y / gy) * gy)

		SnapMode.CELL_CORNER:
			var col: int = int(world_pos.x / gx)
			var row: int = int(world_pos.y / gy)
			if world_pos.x < 0:
				col -= 1
			if world_pos.y < 0:
				row -= 1
			return Vector2(float(col) * gx, float(row) * gy)

		_:
			return world_pos
