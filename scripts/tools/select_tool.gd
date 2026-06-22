##
## SelectTool — Select, move, resize, and rotate objects and walls.
## Single click to select. Drag to move. Area-select by dragging.
##
class_name SelectTool
extends BaseTool


enum SelectMode { IDLE, MOVING, AREA_SELECT }

var _mode: int = SelectMode.IDLE
var _drag_start: Vector2 = Vector2.ZERO
var _selected_object_id: String = ""
var _selected_wall_id: String = ""
var _object_start_pos: Vector2 = Vector2.ZERO
var _object_start_grid: Vector2i = Vector2i.ZERO


func _init() -> void:
	tool_name = "select"


func on_activate() -> void:
	_mode = SelectMode.IDLE
	clear_selection()


func on_deactivate() -> void:
	clear_selection()
	_mode = SelectMode.IDLE


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	var obj_r = mgr.get_object_renderer()
	var wall_r = mgr.get_wall_renderer()

	if obj_r:
		var obj = obj_r.get_object_at_position(world_pos)
		if obj != null:
			select_object(obj.object_id, obj)
			_mode = SelectMode.MOVING
			_drag_start = world_pos
			_object_start_pos = obj.position
			_object_start_grid = obj.grid_position
			return

	if wall_r:
		var wall = _find_wall_at_position(wall_r, world_pos)
		if wall != null:
			select_wall(wall.segment_id)
			return

	if not Input.is_key_pressed(KEY_CTRL):
		clear_selection()
	_mode = SelectMode.AREA_SELECT
	_drag_start = world_pos


func on_mouse_moved(world_pos: Vector2) -> void:
	if _mode == SelectMode.MOVING and not _selected_object_id.is_empty():
		var mgr = _tool_manager_ref
		if mgr == null:
			return

		var gr = mgr.get_grid_renderer()
		var obj_r = mgr.get_object_renderer()
		if gr == null or obj_r == null:
			return

		var obj = obj_r.get_object_by_id(_selected_object_id)
		if obj == null:
			return

		var delta = world_pos - _drag_start
		obj.position = _object_start_pos + delta
		obj.grid_position = gr.world_to_grid(obj.position)
		obj_r.update_object(_selected_object_id)


func on_mouse_released(_world_pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return

	if _mode == SelectMode.MOVING and not _selected_object_id.is_empty():
		var mgr = _tool_manager_ref
		if mgr == null:
			return

		var obj_r = mgr.get_object_renderer()
		if obj_r == null:
			return

		var obj = obj_r.get_object_by_id(_selected_object_id)
		if obj != null:
			var cmd = UndoRedoManager.MoveObjectCommand.new(obj, obj.position, obj.grid_position)
			UndoRedoManager.execute_command(cmd)

	_mode = SelectMode.IDLE


func on_draw_overlay(canvas: Node2D) -> void:
	if _mode == SelectMode.AREA_SELECT:
		var current = canvas.get_global_mouse_position()
		var rect = Rect2(
			minf(_drag_start.x, current.x),
			minf(_drag_start.y, current.y),
			absf(_drag_start.x - current.x),
			absf(_drag_start.y - current.y)
		)
		canvas.draw_rect(rect, Color(0.2, 0.6, 1.0, 0.2), true)
		canvas.draw_rect(rect, Color(0.2, 0.6, 1.0, 0.7), false, 1.5)


func select_object(object_id: String, obj: MapObjectData = null) -> void:
	clear_selection()
	_selected_object_id = object_id

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	if obj == null and mgr.get_object_renderer():
		obj = mgr.get_object_renderer().get_object_by_id(object_id)

	if mgr.get_object_renderer():
		mgr.get_object_renderer().set_selected(object_id)

	EventBus.selection_changed.emit("object", obj.object_id if obj else object_id)


func select_wall(wall_id: String) -> void:
	clear_selection()
	_selected_wall_id = wall_id

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	if mgr.get_wall_renderer():
		mgr.get_wall_renderer().set_selected(wall_id)

	EventBus.selection_changed.emit("wall", wall_id)


func clear_selection() -> void:
	_selected_object_id = ""
	_selected_wall_id = ""

	var mgr = _tool_manager_ref
	if mgr == null:
		return

	if mgr.get_object_renderer():
		mgr.get_object_renderer().clear_selection()
	if mgr.get_wall_renderer():
		mgr.get_wall_renderer().clear_selection()


func get_selected_object_id() -> String:
	return _selected_object_id


func get_selected_wall_id() -> String:
	return _selected_wall_id


func _find_wall_at_position(renderer: WallRenderer, world_pos: Vector2, tolerance: float = 12.0) -> WallSegmentData:
	for wall in renderer._walls:
		if wall is WallSegmentData:
			var closest = _closest_point_on_segment(world_pos, wall.start_point, wall.end_point)
			var dist = world_pos.distance_to(closest)
			if dist < tolerance:
				return wall
	return null


func _closest_point_on_segment(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var len_sq = ab.length_squared()
	if len_sq < 0.0001:
		return a
	var t = clampf((point - a).dot(ab) / len_sq, 0.0, 1.0)
	return a + ab * t


var _tool_manager_ref: ToolManager = null


func set_tool_manager(mgr: ToolManager) -> void:
	_tool_manager_ref = mgr
