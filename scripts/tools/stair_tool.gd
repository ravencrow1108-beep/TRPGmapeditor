##
## StairTool — Create stair connections between two floors.
## First click on current floor, then click target cell.
##
class_name StairTool
extends BaseTool


var _source_cell: Vector2i = Vector2i(-1, -1)
var _source_set: bool = false
var _target_floor: int = -1
var _id_counter: int = 0


func _init() -> void:
	tool_name = "stair"


func on_activate() -> void:
	_source_set = false
	_source_cell = Vector2i(-1, -1)
	_target_floor = -1


func on_deactivate() -> void:
	_source_set = false


func set_target_floor(floor_index: int) -> void:
	_target_floor = floor_index


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		_source_set = false
		_source_cell = Vector2i(-1, -1)
		_target_floor = -1
		return

	if button != MOUSE_BUTTON_LEFT:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var grid_cell = mgr.world_to_grid(world_pos)

	if not _source_set:
		_source_cell = grid_cell
		_source_set = true
		var cmap = mgr.get_current_map()
		if cmap:
			_target_floor = mini(cmap.current_floor + 1, cmap.floors.size() - 1)
	else:
		if _target_floor < 0:
			var cmap = mgr.get_current_map()
			if cmap:
				_target_floor = mini(cmap.current_floor + 1, cmap.floors.size() - 1)
		_commit_stair(mgr, grid_cell)
		_source_set = false
		_source_cell = Vector2i(-1, -1)
		_target_floor = -1


func on_draw_overlay(canvas: Node2D) -> void:
	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	if _source_set:
		var pos = GridUtils.grid_to_world(_source_cell, gr.grid_size)
		var size = Vector2(gr.grid_size)
		var rect = Rect2(pos, size)
		canvas.draw_rect(rect, Color(0.6, 0.4, 0.2, 0.4), true)
		canvas.draw_rect(rect, Color(0.6, 0.4, 0.2, 0.8), false, 2.0)

		var center = pos + size * 0.5
		canvas.draw_line(center + Vector2(-6, -4), center + Vector2(6, 4), Color(0.6, 0.4, 0.2, 0.8), 2.0)
		canvas.draw_line(center + Vector2(-6, 0), center + Vector2(6, 0), Color(0.6, 0.4, 0.2, 0.8), 2.0)
		canvas.draw_line(center + Vector2(-6, 4), center + Vector2(6, -4), Color(0.6, 0.4, 0.2, 0.8), 2.0)


func _commit_stair(mgr: ToolManager, target_cell: Vector2i) -> void:
	var cmap = mgr.get_current_map()
	if cmap == null:
		return

	var cfi = cmap.current_floor
	if _target_floor == cfi:
		return

	_id_counter += 1

	var stair = StairConnectionData.new()
	stair.connection_id = "stair_%d_%d" % [_id_counter, Time.get_ticks_msec()]
	stair.stair_name = "楼梯 %d" % _id_counter
	stair.from_floor = cfi
	stair.from_position = _source_cell
	stair.to_floor = _target_floor
	stair.to_position = target_cell
	stair.stair_type = StairConnectionData.StairType.STAIRS
	stair.is_bidirectional = true

	var cmd = UndoRedoManager.AddStairCommand.new(cmap, stair)
	UndoRedoManager.execute_command(cmd)


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
