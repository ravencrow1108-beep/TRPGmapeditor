##
## PortalTool — Place a portal by clicking source and destination cells.
## Phase 1: same-floor portal stub. Full cross-floor/cross-map in Phase 2.
##
class_name PortalTool
extends BaseTool


var _source_cell: Vector2i = Vector2i(-1, -1)
var _source_set: bool = false


func _init() -> void:
	tool_name = "portal"


func on_activate() -> void:
	_source_set = false
	_source_cell = Vector2i(-1, -1)


func on_deactivate() -> void:
	_source_set = false


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		_source_set = false
		_source_cell = Vector2i(-1, -1)
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
	else:
		_commit_portal(mgr, grid_cell)
		_source_set = false
		_source_cell = Vector2i(-1, -1)


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
		canvas.draw_rect(rect, Color(0.5, 0.3, 1.0, 0.4), true)
		canvas.draw_rect(rect, Color(0.5, 0.3, 1.0, 0.8), false, 2.0)

	var cursor_cell = mgr.world_to_grid(canvas.get_global_mouse_position())
	var cpos = GridUtils.grid_to_world(cursor_cell, gr.grid_size)
	var csize = Vector2(gr.grid_size)
	canvas.draw_rect(Rect2(cpos, csize), Color(0.5, 0.3, 1.0, 0.25), false, 1.5)


func _commit_portal(mgr: ToolManager, target_cell: Vector2i) -> void:
	var current_map = mgr.get_current_map()
	if current_map == null:
		return

	var fi = current_map.current_floor

	var portal = PortalData.new()
	portal.portal_id = "portal_%d_%d_%d" % [fi, _source_cell.x, _source_cell.y]
	portal.portal_name = "传送门"
	portal.source_floor = fi
	portal.source_position = _source_cell
	portal.target_floor = fi
	portal.target_position = target_cell
	portal.is_bidirectional = true
	portal.is_active = true
	portal.visual_color = Color(0.5, 0.3, 1.0, 0.7)
	portal.label_text = "传送门"

	var cmd = UndoRedoManager.CreatePortalCommand.new(current_map, portal)
	UndoRedoManager.execute_command(cmd)


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
