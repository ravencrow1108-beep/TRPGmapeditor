##
## BrushTool — Tile placement tool with four modes: SINGLE, LINE, RECT, FILL.
## Shift+click to sample a tile under the cursor.
##
class_name BrushTool
extends BaseTool


enum BrushMode { SINGLE, LINE, RECT, FILL }

var mode: int = BrushMode.SINGLE
var _tile_data: Dictionary = {"id": 0}
var _drag_start_cell: Vector2i = Vector2i(-1, -1)
var _is_dragging: bool = false
var _preview_cells: Array[Vector2i] = []


func _init() -> void:
	tool_name = "brush"


func on_activate() -> void:
	_preview_cells.clear()
	_is_dragging = false
	_drag_start_cell = Vector2i(-1, -1)


func on_deactivate() -> void:
	_preview_cells.clear()
	_is_dragging = false


func set_tile_data(data: Dictionary) -> void:
	_tile_data = data


func get_tile_data() -> Dictionary:
	return _tile_data.duplicate()


func set_brush_mode(m: int) -> void:
	mode = m
	_is_dragging = false
	_preview_cells.clear()
	_drag_start_cell = Vector2i(-1, -1)


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var grid_cell = mgr.world_to_grid(world_pos)
	var layer = mgr.get_active_layer()
	if layer == null or layer.locked:
		return

	if Input.is_key_pressed(KEY_SHIFT):
		var existing = layer.tiles.get(grid_cell)
		if existing != null and existing is Dictionary:
			_tile_data = existing.duplicate()
		return

	match mode:
		BrushMode.SINGLE:
			_place_single(layer, grid_cell)
		BrushMode.LINE, BrushMode.RECT:
			_drag_start_cell = grid_cell
			_is_dragging = true
		BrushMode.FILL:
			_do_flood_fill(layer, grid_cell)


func on_mouse_moved(world_pos: Vector2) -> void:
	if not _is_dragging:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var grid_cell = mgr.world_to_grid(world_pos)

	match mode:
		BrushMode.LINE:
			_preview_cells = GridUtils.bresenham_line(_drag_start_cell, grid_cell)
		BrushMode.RECT:
			_preview_cells = GridUtils.rect_cells(_drag_start_cell, grid_cell)


func on_mouse_released(world_pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT or not _is_dragging:
		return

	_is_dragging = false

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var grid_cell = mgr.world_to_grid(world_pos)
	var layer = mgr.get_active_layer()
	if layer == null or layer.locked:
		return

	match mode:
		BrushMode.LINE:
			var cells = GridUtils.bresenham_line(_drag_start_cell, grid_cell)
			if not cells.is_empty():
				var cmd = UndoRedoManager.LinePlaceCommand.new(layer, cells, _tile_data.duplicate())
				UndoRedoManager.execute_command(cmd)
		BrushMode.RECT:
			var cells = GridUtils.rect_cells(_drag_start_cell, grid_cell)
			if not cells.is_empty():
				var cmd = UndoRedoManager.RectFillCommand.new(layer, cells, _tile_data.duplicate())
				UndoRedoManager.execute_command(cmd)

	_preview_cells.clear()


func on_draw_overlay(canvas: Node2D) -> void:
	if _preview_cells.is_empty():
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return
	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	var gs = gr.grid_size
	for cell in _preview_cells:
		var pos = GridUtils.grid_to_world(cell, gs)
		var rect = Rect2(pos, Vector2(gs))
		canvas.draw_rect(rect, Color(0.2, 0.9, 0.4, 0.35), true)
		canvas.draw_rect(rect, Color(0.2, 0.9, 0.4, 0.7), false, 1.0)


func _place_single(layer: TerrainLayerData, cell: Vector2i) -> void:
	var cmd = UndoRedoManager.PlaceTileCommand.new(layer, cell, _tile_data.duplicate())
	UndoRedoManager.execute_command(cmd)


func _do_flood_fill(layer: TerrainLayerData, start: Vector2i) -> void:
	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var target_tile = layer.tiles.get(start)

	var can_fill = func(cell: Vector2i) -> bool:
		if layer.tiles.has(cell):
			if target_tile == null:
				return false
			return layer.tiles[cell] == target_tile
		else:
			return target_tile == null

	var cells = GridUtils.flood_fill(start, can_fill)
	if not cells.is_empty():
		var cmd = UndoRedoManager.FloodFillCommand.new(layer, cells, _tile_data.duplicate())
		UndoRedoManager.execute_command(cmd)


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
