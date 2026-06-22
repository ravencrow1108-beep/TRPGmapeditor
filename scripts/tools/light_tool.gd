##
## LightTool — Place light sources by clicking grid cells.
## Phase 1: default POINT light. Full light editing in Phase 4.
##
class_name LightTool
extends BaseTool


var _preview_cell: Vector2i = Vector2i(-1, -1)
var _id_counter: int = 0


func _init() -> void:
	tool_name = "light"


func on_activate() -> void:
	_preview_cell = Vector2i(-1, -1)


func on_deactivate() -> void:
	_preview_cell = Vector2i(-1, -1)


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var grid_cell = mgr.world_to_grid(world_pos)
	var fd = mgr.get_active_floor()
	if fd == null:
		return

	_place_light(mgr, fd, grid_cell)


func on_mouse_moved(world_pos: Vector2) -> void:
	var mgr = _tool_manager_ref
	if mgr == null:
		return
	_preview_cell = mgr.world_to_grid(world_pos)


func on_draw_overlay(canvas: Node2D) -> void:
	if _preview_cell == Vector2i(-1, -1):
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	var pos = GridUtils.grid_to_world(_preview_cell, gr.grid_size)
	var size = Vector2(gr.grid_size)
	var center = pos + size * 0.5
	var radius_px: float = 5.0 * float(gr.grid_size.x) * 0.5

	canvas.draw_arc(center, radius_px, 0, TAU, 48, Color(1.0, 0.95, 0.6, 0.25), 3.0)
	canvas.draw_circle(center, 4.0, Color(1.0, 0.95, 0.3, 0.9))


func _place_light(mgr: ToolManager, fd: FloorData, grid_cell: Vector2i) -> void:
	var gr = mgr.get_grid_renderer()
	if gr == null:
		return

	_id_counter += 1

	var light = LightData.new()
	light.light_id = "light_%d_%d" % [fd.floor_index, _id_counter]
	light.light_name = "光源 %d" % _id_counter
	light.floor_index = fd.floor_index
	light.grid_position = grid_cell
	light.position = GridUtils.grid_to_world(grid_cell, gr.grid_size) + Vector2(gr.grid_size) * 0.5
	light.light_type = LightData.LightType.POINT
	light.intensity = 1.0
	light.color = Color(1.0, 0.95, 0.8, 1.0)
	light.radius = 5.0
	light.falloff = 0.5
	light.is_static = true

	var cmd = UndoRedoManager.PlaceLightCommand.new(fd, light)
	UndoRedoManager.execute_command(cmd)


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
