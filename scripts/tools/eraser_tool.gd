##
## EraserTool — Click or drag to erase tiles.
##
class_name EraserTool
extends BaseTool


var _is_erasing: bool = false
var _erased_cells: Array[Vector2i] = []
var _touched_layer: TerrainLayerData = null


func _init() -> void:
	tool_name = "eraser"


func on_activate() -> void:
	_is_erasing = false
	_erased_cells.clear()
	_touched_layer = null


func on_deactivate() -> void:
	_is_erasing = false
	_erased_cells.clear()


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

	_is_erasing = true
	_erased_cells.clear()
	_touched_layer = layer

	if layer.tiles.has(grid_cell):
		_erased_cells.append(grid_cell)


func on_mouse_moved(world_pos: Vector2) -> void:
	if not _is_erasing:
		return

	var mgr = _tool_manager_ref
	if mgr == null or _touched_layer == null:
		return

	var grid_cell = mgr.world_to_grid(world_pos)
	if _touched_layer.tiles.has(grid_cell) and not _erased_cells.has(grid_cell):
		_erased_cells.append(grid_cell)


func on_mouse_released(_world_pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT or not _is_erasing:
		return

	_is_erasing = false

	if _erased_cells.is_empty() or _touched_layer == null:
		return

	for cell in _erased_cells:
		var cmd = UndoRedoManager.RemoveTileCommand.new(_touched_layer, cell)
		UndoRedoManager.execute_command(cmd)

	_erased_cells.clear()


func on_draw_overlay(canvas: Node2D) -> void:
	if not _is_erasing:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	var gs = gr.grid_size
	for cell in _erased_cells:
		var pos = GridUtils.grid_to_world(cell, gs)
		var rect = Rect2(pos, Vector2(gs))
		canvas.draw_rect(rect, Color(0.9, 0.2, 0.2, 0.4), true)
		canvas.draw_rect(rect, Color(0.9, 0.2, 0.2, 0.8), false, 2.0)


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
