##
## ToolManager — Owns the tool lifecycle and forwards input to the active tool.
## Registered as a child of MapEditorController.
##
class_name ToolManager
extends Node


@warning_ignore("unused_signal")
signal tool_changed(old_tool: String, new_tool: String)


var _tools: Dictionary = {}
var _active_tool_name: String = ""
var _active_tool: BaseTool = null
var _grid_renderer: GridRenderer = null
var _floor_manager: FloorManager = null
var _current_map: MapData = null
var _object_renderer: ObjectRenderer = null
var _wall_renderer: WallRenderer = null
var _preview_overlay: PreviewOverlay = null
var _active_layer_index: int = 0


func register_tool(tool: BaseTool) -> void:
	_tools[tool.tool_name] = tool


func set_active_tool(tool_name: String) -> void:
	if not _tools.has(tool_name):
		return

	var old_name = _active_tool_name

	if _active_tool != null:
		_active_tool.on_deactivate()
		_active_tool.is_active = false

	_active_tool_name = tool_name
	_active_tool = _tools[tool_name]
	_active_tool.is_active = true
	_active_tool.on_activate()

	if _preview_overlay:
		_preview_overlay.clear()

	tool_changed.emit(old_name, tool_name)
	EventBus.selection_changed.emit("tool", tool_name)


func get_active_tool_name() -> String:
	return _active_tool_name


func get_active_tool() -> BaseTool:
	return _active_tool


func inject_dependencies(grid: GridRenderer, floor_mgr: FloorManager, map: MapData, obj_r: ObjectRenderer = null, wall_r: WallRenderer = null, preview: PreviewOverlay = null) -> void:
	_grid_renderer = grid
	_floor_manager = floor_mgr
	_current_map = map
	_object_renderer = obj_r
	_wall_renderer = wall_r
	_preview_overlay = preview


func set_active_layer_index(index: int) -> void:
	_active_layer_index = index


func get_active_layer_index() -> int:
	return _active_layer_index


# ---------- Input forwarding ----------

func handle_mouse_pressed(world_pos: Vector2, button: int) -> void:
	if _active_tool != null:
		_active_tool.on_mouse_pressed(world_pos, button)


func handle_mouse_moved(world_pos: Vector2) -> void:
	if _active_tool != null:
		_active_tool.on_mouse_moved(world_pos)
		if _preview_overlay:
			_preview_overlay.clear()
			_active_tool.on_draw_overlay(_preview_overlay)


func handle_mouse_released(world_pos: Vector2, button: int) -> void:
	if _active_tool != null:
		_active_tool.on_mouse_released(world_pos, button)


func handle_key_pressed(event: InputEventKey) -> void:
	if _active_tool != null:
		_active_tool.on_key_pressed(event)


# ---------- Utility accessors ----------

func get_active_layer() -> TerrainLayerData:
	if _current_map == null:
		return null
	var fd = _current_map.get_active_floor()
	if fd == null:
		return null
	if _active_layer_index < 0 or _active_layer_index >= fd.terrain_layers.size():
		return null
	return fd.terrain_layers[_active_layer_index]


func get_active_floor() -> FloorData:
	if _current_map == null:
		return null
	return _current_map.get_active_floor()


func world_to_grid(world_pos: Vector2) -> Vector2i:
	if _grid_renderer:
		return _grid_renderer.world_to_grid(world_pos)
	return Vector2i.ZERO


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if _grid_renderer:
		return _grid_renderer.grid_to_world(grid_pos)
	return Vector2.ZERO


func get_grid_renderer() -> GridRenderer:
	return _grid_renderer


func get_floor_manager() -> FloorManager:
	return _floor_manager


func get_current_map() -> MapData:
	return _current_map


func get_object_renderer() -> ObjectRenderer:
	return _object_renderer


func get_wall_renderer() -> WallRenderer:
	return _wall_renderer


func get_preview_overlay() -> PreviewOverlay:
	return _preview_overlay
