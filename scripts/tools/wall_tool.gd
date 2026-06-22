##
## WallTool — Place wall segments by clicking start and end points.
## Preview line shown during drag. Right-click cancels.
##
class_name WallTool
extends BaseTool


var _start_cell: Vector2i = Vector2i(-1, -1)
var _start_set: bool = false
var _selected_wall_type: int = WallSegmentData.WallType.SOLID
var _preview_end: Vector2 = Vector2.ZERO
var _id_counter: int = 0


func _init() -> void:
	tool_name = "wall"


func on_activate() -> void:
	_start_set = false
	_start_cell = Vector2i(-1, -1)


func on_deactivate() -> void:
	_start_set = false


func set_wall_type(wall_type: int) -> void:
	_selected_wall_type = wall_type


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	var mgr = _tool_manager_ref
	if mgr == null:
		return

	if button == MOUSE_BUTTON_RIGHT:
		_start_set = false
		_start_cell = Vector2i(-1, -1)
		return

	if button != MOUSE_BUTTON_LEFT:
		return

	var grid_cell = mgr.world_to_grid(world_pos)
	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	if not _start_set:
		_start_cell = grid_cell
		_start_set = true
	else:
		_commit_wall(mgr, grid_cell)
		_start_set = false
		_start_cell = Vector2i(-1, -1)


func on_mouse_moved(world_pos: Vector2) -> void:
	if _start_set:
		_preview_end = world_pos


func on_draw_overlay(canvas: Node2D) -> void:
	if not _start_set:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	var start_pos = GridUtils.grid_to_world(_start_cell, gr.grid_size) + Vector2(gr.grid_size) * 0.5

	canvas.draw_line(start_pos, _preview_end, Color(0.6, 0.6, 0.6, 0.8), 3.0)
	canvas.draw_circle(start_pos, 5.0, Color(0.2, 1.0, 0.3, 0.8))
	canvas.draw_circle(_preview_end, 5.0, Color(0.2, 0.6, 1.0, 0.8))


func _commit_wall(mgr: ToolManager, end_cell: Vector2i) -> void:
	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	var fd = mgr.get_active_floor()
	if fd == null:
		return

	var start_pos = GridUtils.grid_to_world(_start_cell, gr.grid_size) + Vector2(gr.grid_size) * 0.5
	var end_pos = GridUtils.grid_to_world(end_cell, gr.grid_size) + Vector2(gr.grid_size) * 0.5

	_id_counter += 1
	var wall = WallSegmentData.new()
	wall.segment_id = "wall_%d_%d" % [fd.floor_index, _id_counter]
	wall.start_point = start_pos
	wall.end_point = end_pos
	wall.wall_type = _selected_wall_type
	wall.block_flags = WallSegmentData.BLOCK_MOVEMENT
	if _selected_wall_type == WallSegmentData.WallType.SOLID:
		wall.block_flags = WallSegmentData.BLOCK_VISION | WallSegmentData.BLOCK_LIGHT | WallSegmentData.BLOCK_PROJECTILE | WallSegmentData.BLOCK_MOVEMENT

	var cmd = UndoRedoManager.PlaceWallCommand.new(fd, wall)
	UndoRedoManager.execute_command(cmd)


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
