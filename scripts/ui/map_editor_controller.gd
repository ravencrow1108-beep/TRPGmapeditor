##
## MapEditorController — Top-level controller for the map editor.
## Builds the entire editor UI programmatically, owns the current MapData,
## delegates input to ToolManager, coordinates via EventBus.
##
class_name MapEditorController
extends Control


# ---------- Node references (set during _build_ui) ----------
var menu_bar: MenuBar = null
var tool_bar: ToolBar = null
var grid_renderer: GridRenderer = null
var camera: Camera2D = null
var layer_panel: LayerPanel = null
var tile_palette: TilePalette = null
var status_bar: StatusBar = null
var floor_selector: FloorSelector = null
var property_inspector: ObjectPropertyInspector = null

# ---------- Subsystem references ----------
var floor_manager: FloorManager = null
var tool_manager: ToolManager = null
var wall_renderer: WallRenderer = null
var object_renderer: ObjectRenderer = null
var preview_overlay: PreviewOverlay = null

# ---------- Utilities ----------
var clipboard: Clipboard = null
var snap_to_grid: SnapToGrid = null

# ---------- Internal state ----------
var _current_map: MapData = null
var _active_tool: String = "brush"
var _active_layer_index: int = 0
var _file_path: String = ""


# ---------- Lifecycle ----------

func _ready() -> void:
	clipboard = Clipboard.new()
	snap_to_grid = SnapToGrid.new()
	snap_to_grid.set_from_config()

	_build_ui()
	_create_subsystems()
	_register_tools()
	_connect_menu_signals()
	_connect_toolbar_signals()
	_connect_grid_signals()
	_connect_layer_panel_signals()
	_connect_floor_selector_signals()
	_connect_eventbus_signals()
	_connect_inspector_signals()
	_create_default_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z and event.ctrl_pressed and not event.shift_pressed:
			UndoRedoManager.undo()
			return
		elif event.keycode == KEY_Z and event.ctrl_pressed and event.shift_pressed:
			UndoRedoManager.redo()
			return
		elif event.keycode == KEY_Y and event.ctrl_pressed:
			UndoRedoManager.redo()
			return
		elif event.keycode == KEY_S and event.ctrl_pressed and event.shift_pressed:
			_on_save_as_map()
			return
		elif event.keycode == KEY_S and event.ctrl_pressed:
			_on_save_map()
			return
		elif event.keycode == KEY_N and event.ctrl_pressed:
			_on_new_map()
			return
		elif event.keycode == KEY_O and event.ctrl_pressed:
			_on_open_map()
			return
		elif event.keycode == KEY_C and event.ctrl_pressed:
			_on_copy()
			return
		elif event.keycode == KEY_V and event.ctrl_pressed:
			_on_paste()
			return
		elif event.keycode == KEY_X and event.ctrl_pressed:
			_on_cut()
			return
		elif event.keycode == KEY_B:
			tool_manager.set_active_tool("brush")
			var bt = tool_manager.get_active_tool()
			if bt is BrushTool:
				bt.set_brush_mode(BrushTool.BrushMode.SINGLE)
			return
		elif event.keycode == KEY_E:
			tool_manager.set_active_tool("eraser")
			return
		elif event.keycode == KEY_L:
			tool_manager.set_active_tool("brush")
			var bt = tool_manager.get_active_tool()
			if bt is BrushTool:
				bt.set_brush_mode(BrushTool.BrushMode.LINE)
			return
		elif event.keycode == KEY_R:
			tool_manager.set_active_tool("brush")
			var bt = tool_manager.get_active_tool()
			if bt is BrushTool:
				bt.set_brush_mode(BrushTool.BrushMode.RECT)
			return
		elif event.keycode == KEY_F:
			tool_manager.set_active_tool("brush")
			var bt = tool_manager.get_active_tool()
			if bt is BrushTool:
				bt.set_brush_mode(BrushTool.BrushMode.FILL)
			return

	if event is InputEventKey and tool_manager:
		tool_manager.handle_key_pressed(event)


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# --- MenuBar ---
	menu_bar = MenuBar.new()
	menu_bar.name = "MenuBar"

	var file_menu = PopupMenu.new()
	file_menu.name = "FileMenu"
	file_menu.add_item("新建地图 (New)", 0)
	file_menu.add_item("打开地图 (Open)", 1)
	file_menu.add_item("保存 (Save)", 2)
	file_menu.add_item("另存为 (Save As)", 3)
	file_menu.add_separator()
	file_menu.add_item("退出 (Exit)", 4)
	menu_bar.add_child(file_menu)

	var edit_menu = PopupMenu.new()
	edit_menu.name = "EditMenu"
	edit_menu.add_item("撤销 (Undo)", 0)
	edit_menu.add_item("重做 (Redo)", 1)
	edit_menu.add_separator()
	edit_menu.add_item("复制 (Copy)", 2)
	edit_menu.add_item("粘贴 (Paste)", 3)
	edit_menu.add_item("剪切 (Cut)", 4)
	menu_bar.add_child(edit_menu)

	var view_menu = PopupMenu.new()
	view_menu.name = "ViewMenu"
	view_menu.add_item("放大 (Zoom In)", 0)
	view_menu.add_item("缩小 (Zoom Out)", 1)
	view_menu.add_item("重置缩放 (Reset Zoom)", 2)
	menu_bar.add_child(view_menu)

	var help_menu = PopupMenu.new()
	help_menu.name = "HelpMenu"
	help_menu.add_item("关于 (About)", 0)
	menu_bar.add_child(help_menu)

	menu_bar.set_menu_title(0, "文件 (File)")
	menu_bar.set_menu_title(1, "编辑 (Edit)")
	menu_bar.set_menu_title(2, "视图 (View)")
	menu_bar.set_menu_title(3, "帮助 (Help)")

	add_child(menu_bar)

	# --- Main container ---
	var main_container = HSplitContainer.new()
	main_container.name = "MainContainer"
	main_container.anchor_left = 0.0
	main_container.anchor_top = 0.0
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.offset_top = 28
	main_container.offset_bottom = -28
	main_container.split_offset = -300
	main_container.size_flags_horizontal = SIZE_EXPAND_FILL
	main_container.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(main_container)

	# --- Left Panel (ToolBar + FloorSelector) ---
	var left_panel = VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.custom_minimum_size = Vector2(110, 0)
	left_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = SIZE_EXPAND_FILL

	tool_bar = ToolBar.new()
	tool_bar.name = "ToolBar"
	left_panel.add_child(tool_bar)

	floor_selector = FloorSelector.new()
	floor_selector.name = "FloorSelector"
	floor_selector.size_flags_vertical = SIZE_EXPAND_FILL
	left_panel.add_child(floor_selector)

	main_container.add_child(left_panel)

	# --- Center Panel (SubViewport map area) ---
	var center_panel = Panel.new()
	center_panel.name = "CenterPanel"
	center_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = SIZE_EXPAND_FILL
	center_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var svp_container = SubViewportContainer.new()
	svp_container.name = "SubViewportContainer"
	svp_container.anchor_left = 0.0
	svp_container.anchor_top = 0.0
	svp_container.anchor_right = 1.0
	svp_container.anchor_bottom = 1.0
	svp_container.stretch = true
	center_panel.add_child(svp_container)

	var sub_viewport = SubViewport.new()
	sub_viewport.name = "SubViewport"
	sub_viewport.handle_input_locally = true
	sub_viewport.gui_disable_input = false
	svp_container.add_child(sub_viewport)

	var map_root = Node2D.new()
	map_root.name = "MapRoot"
	sub_viewport.add_child(map_root)

	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	map_root.add_child(camera)
	call_deferred("_make_camera_current")

	grid_renderer = GridRenderer.new()
	grid_renderer.name = "GridRenderer"
	grid_renderer.grid_size = Vector2i(32, 32)
	grid_renderer.map_dimensions = Vector2i(100, 100)
	map_root.add_child(grid_renderer)

	wall_renderer = WallRenderer.new()
	wall_renderer.name = "WallRenderer"
	map_root.add_child(wall_renderer)

	object_renderer = ObjectRenderer.new()
	object_renderer.name = "ObjectRenderer"
	map_root.add_child(object_renderer)

	preview_overlay = PreviewOverlay.new()
	preview_overlay.name = "PreviewOverlay"
	map_root.add_child(preview_overlay)

	main_container.add_child(center_panel)

	# --- Right Panel (LayerPanel + PropertyInspector + TilePalette) ---
	var right_panel = VSplitContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(250, 0)
	right_panel.size_flags_horizontal = SIZE_EXPAND_FILL

	layer_panel = LayerPanel.new()
	layer_panel.name = "LayerPanel"
	layer_panel.size_flags_vertical = SIZE_EXPAND_FILL
	right_panel.add_child(layer_panel)

	property_inspector = ObjectPropertyInspector.new()
	property_inspector.name = "PropertyInspector"
	property_inspector.size_flags_vertical = SIZE_EXPAND_FILL
	right_panel.add_child(property_inspector)

	tile_palette = TilePalette.new()
	tile_palette.name = "TilePalette"
	tile_palette.size_flags_vertical = SIZE_EXPAND_FILL
	right_panel.add_child(tile_palette)

	main_container.add_child(right_panel)

	# --- StatusBar (bottom) ---
	status_bar = StatusBar.new()
	status_bar.name = "StatusBar"
	status_bar.anchor_left = 0.0
	status_bar.anchor_top = 1.0
	status_bar.anchor_right = 1.0
	status_bar.anchor_bottom = 1.0
	status_bar.offset_top = -28
	status_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(status_bar)


# ---------------------------------------------------------------------------
# Subsystem creation
# ---------------------------------------------------------------------------

func _create_subsystems() -> void:
	floor_manager = FloorManager.new()
	floor_manager.name = "FloorManager"
	add_child(floor_manager)

	tool_manager = ToolManager.new()
	tool_manager.name = "ToolManager"
	add_child(tool_manager)


# ---------------------------------------------------------------------------
# Tool registration
# ---------------------------------------------------------------------------

func _register_tools() -> void:
	tool_manager.inject_dependencies(grid_renderer, floor_manager, _current_map, object_renderer, wall_renderer, preview_overlay)

	var brush_tool = BrushTool.new()
	brush_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(brush_tool)

	var eraser_tool = EraserTool.new()
	eraser_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(eraser_tool)

	var select_tool = SelectTool.new()
	select_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(select_tool)

	var wall_tool = WallTool.new()
	wall_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(wall_tool)

	var portal_tool = PortalTool.new()
	portal_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(portal_tool)

	var light_tool = LightTool.new()
	light_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(light_tool)

	var stair_tool = StairTool.new()
	stair_tool.set_tool_manager(tool_manager)
	tool_manager.register_tool(stair_tool)

	tool_manager.set_active_tool("brush")


# ---------------------------------------------------------------------------
# Default map creation
# ---------------------------------------------------------------------------

func _create_default_map() -> void:
	_current_map = MapData.new()
	_current_map.map_name = "新建地图"
	_current_map.created_date = _iso_date_now()
	_current_map.modified_date = _current_map.created_date

	var floor_data = FloorData.new()
	floor_data.floor_index = 0
	floor_data.floor_name = "地面层"

	var layer = TerrainLayerData.new()
	layer.layer_index = 0
	layer.layer_name = "图层 1"
	floor_data.terrain_layers.append(layer)

	_current_map.floors.append(floor_data)
	_current_map.current_floor = 0

	_apply_map_to_ui(false)


# ---------------------------------------------------------------------------
# Menu connections
# ---------------------------------------------------------------------------

func _connect_menu_signals() -> void:
	var file_menu: PopupMenu = menu_bar.get_menu_popup(0)
	file_menu.id_pressed.connect(_on_file_menu)
	var edit_menu: PopupMenu = menu_bar.get_menu_popup(1)
	edit_menu.id_pressed.connect(_on_edit_menu)
	var view_menu: PopupMenu = menu_bar.get_menu_popup(2)
	view_menu.id_pressed.connect(_on_view_menu)


func _on_file_menu(id: int) -> void:
	match id:
		0: _on_new_map()
		1: _on_open_map()
		2: _on_save_map()
		3: _on_save_as_map()
		4: get_tree().quit()


func _on_edit_menu(id: int) -> void:
	match id:
		0: UndoRedoManager.undo()
		1: UndoRedoManager.redo()
		2: _on_copy()
		3: _on_paste()
		4: _on_cut()


func _on_view_menu(id: int) -> void:
	if not is_instance_valid(grid_renderer) or not is_instance_valid(camera):
		return
	match id:
		0:
			camera.zoom = Vector2(clampf(camera.zoom.x * 1.25, 0.25, 4.0), clampf(camera.zoom.y * 1.25, 0.25, 4.0))
		1:
			camera.zoom = Vector2(clampf(camera.zoom.x * 0.8, 0.25, 4.0), clampf(camera.zoom.y * 0.8, 0.25, 4.0))
		2:
			camera.zoom = Vector2.ONE
			camera.position = Vector2.ZERO
	status_bar.update_zoom(camera.zoom.x)


# ---------------------------------------------------------------------------
# Toolbar connections
# ---------------------------------------------------------------------------

func _connect_toolbar_signals() -> void:
	tool_bar.tool_selected.connect(_on_tool_selected)
	tool_bar.brush_mode_requested.connect(_on_brush_mode_requested)


func _on_tool_selected(tool_name: String) -> void:
	_active_tool = tool_name
	tool_manager.set_active_tool(tool_name)
	status_bar.update_tool(tool_name)


func _on_brush_mode_requested(mode_name: String) -> void:
	var bt = tool_manager.get_active_tool()
	if bt is BrushTool:
		match mode_name:
			"single": bt.set_brush_mode(BrushTool.BrushMode.SINGLE)
			"line":   bt.set_brush_mode(BrushTool.BrushMode.LINE)
			"rect":   bt.set_brush_mode(BrushTool.BrushMode.RECT)
			"fill":   bt.set_brush_mode(BrushTool.BrushMode.FILL)


# ---------------------------------------------------------------------------
# Grid input
# ---------------------------------------------------------------------------

func _connect_grid_signals() -> void:
	grid_renderer.tile_clicked.connect(_on_grid_tile_clicked)
	grid_renderer.tile_right_clicked.connect(_on_grid_tile_right_clicked)
	grid_renderer.mouse_moved.connect(_on_grid_mouse_moved)


func _on_grid_tile_clicked(grid_pos: Vector2i) -> void:
	if _current_map == null:
		return

	tool_manager.inject_dependencies(grid_renderer, floor_manager, _current_map, object_renderer, wall_renderer, preview_overlay)

	var world_pos = grid_renderer.grid_to_world(grid_pos)
	if snap_to_grid.is_snap_active():
		world_pos = snap_to_grid.snap(world_pos, grid_renderer.grid_size)

	tool_manager.handle_mouse_pressed(world_pos, MOUSE_BUTTON_LEFT)


func _on_grid_tile_right_clicked(_grid_pos: Vector2i) -> void:
	if tool_manager:
		tool_manager.handle_mouse_pressed(Vector2.ZERO, MOUSE_BUTTON_RIGHT)


func _on_grid_mouse_moved(world_pos: Vector2, grid_pos: Vector2i) -> void:
	status_bar.update_position(grid_pos)
	if tool_manager:
		tool_manager.handle_mouse_moved(world_pos)


# ---------------------------------------------------------------------------
# Layer panel connections
# ---------------------------------------------------------------------------

func _connect_layer_panel_signals() -> void:
	layer_panel.layer_selected.connect(_on_layer_selected)
	layer_panel.layer_visibility_toggled.connect(_on_layer_visibility_toggled)
	layer_panel.layer_lock_toggled.connect(_on_layer_lock_toggled)
	layer_panel.layer_opacity_changed.connect(_on_layer_opacity_changed)
	layer_panel.layer_add_requested.connect(_on_add_layer)
	layer_panel.layer_remove_requested.connect(_on_remove_layer)
	layer_panel.layer_reorder_requested.connect(_on_reorder_layer)


func _on_layer_selected(index: int) -> void:
	_active_layer_index = index
	tool_manager.set_active_layer_index(index)


func _on_layer_visibility_toggled(index: int, p_visible: bool) -> void:
	var fd = _current_map.get_active_floor()
	if fd and index < fd.terrain_layers.size():
		fd.terrain_layers[index].visible = p_visible
		_refresh_grid_display()


func _on_layer_lock_toggled(index: int, locked: bool) -> void:
	var fd = _current_map.get_active_floor()
	if fd and index < fd.terrain_layers.size():
		fd.terrain_layers[index].locked = locked


func _on_layer_opacity_changed(index: int, opacity: float) -> void:
	var fd = _current_map.get_active_floor()
	if fd and index < fd.terrain_layers.size():
		fd.terrain_layers[index].opacity = opacity
		_refresh_grid_display()


func _on_add_layer() -> void:
	var fd = _current_map.get_active_floor()
	if fd == null:
		return
	var layer = TerrainLayerData.new()
	layer.layer_index = fd.terrain_layers.size()
	layer.layer_name = "图层 %d" % (layer.layer_index + 1)
	var cmd = UndoRedoManager.AddLayerCommand.new(fd, layer)
	UndoRedoManager.execute_command(cmd)
	_refresh_layer_panel()
	_refresh_grid_display()


func _on_remove_layer(index: int) -> void:
	var fd = _current_map.get_active_floor()
	if fd == null or fd.terrain_layers.size() <= 1:
		return
	if index < 0 or index >= fd.terrain_layers.size():
		return
	var layer = fd.terrain_layers[index]
	var cmd = UndoRedoManager.RemoveLayerCommand.new(fd, layer)
	UndoRedoManager.execute_command(cmd)
	for i in range(fd.terrain_layers.size()):
		fd.terrain_layers[i].layer_index = i
	if _active_layer_index >= fd.terrain_layers.size():
		_active_layer_index = fd.terrain_layers.size() - 1
		tool_manager.set_active_layer_index(_active_layer_index)
	_refresh_layer_panel()
	_refresh_grid_display()


func _on_reorder_layer(from_index: int, to_index: int) -> void:
	var fd = _current_map.get_active_floor()
	if fd == null:
		return
	var count = fd.terrain_layers.size()
	if from_index < 0 or from_index >= count or to_index < 0 or to_index >= count:
		return
	var cmd = UndoRedoManager.ReorderLayerCommand.new(fd, from_index, to_index)
	UndoRedoManager.execute_command(cmd)
	for i in count:
		fd.terrain_layers[i].layer_index = i
	_active_layer_index = to_index
	tool_manager.set_active_layer_index(_active_layer_index)
	_refresh_layer_panel()
	_refresh_grid_display()


# ---------------------------------------------------------------------------
# Floor selector connections
# ---------------------------------------------------------------------------

func _connect_floor_selector_signals() -> void:
	floor_selector.floor_clicked.connect(_on_floor_clicked)
	floor_selector.floor_double_clicked.connect(_on_floor_double_clicked)
	floor_selector.floor_add_requested.connect(_on_floor_add)
	floor_selector.floor_duplicate_requested.connect(_on_floor_duplicate)
	floor_selector.floor_delete_requested.connect(_on_floor_delete)
	floor_selector.floor_move_up_requested.connect(_on_floor_move_up)
	floor_selector.floor_move_down_requested.connect(_on_floor_move_down)
	floor_selector.show_adjacent_floors_changed.connect(_on_show_adjacent_changed)


func _on_floor_clicked(index: int) -> void:
	floor_manager.switch_to_floor(index, "instant")
	_refresh_all_views()


func _on_floor_double_clicked(index: int) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "重命名楼层"
	var le = LineEdit.new()
	var fd = floor_manager.get_floor_at(index)
	if fd:
		le.text = fd.floor_name
	dialog.add_child(le)
	add_child(dialog)
	dialog.confirmed.connect(func():
		if fd:
			fd.floor_name = le.text
		dialog.queue_free()
		_refresh_floor_selector()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()


func _on_floor_add() -> void:
	floor_manager.add_floor()
	_refresh_all_views()


func _on_floor_duplicate(index: int) -> void:
	floor_manager.duplicate_floor(index)
	_refresh_all_views()


func _on_floor_delete(index: int) -> void:
	floor_manager.remove_floor(index)
	_refresh_all_views()


func _on_floor_move_up(index: int) -> void:
	if index > 0:
		floor_manager.reorder_floors(index, index - 1)
		_refresh_all_views()


func _on_floor_move_down(index: int) -> void:
	if index < floor_manager.get_floor_count() - 1:
		floor_manager.reorder_floors(index, index + 1)
		_refresh_all_views()


func _on_show_adjacent_changed(p_show: bool, opacity: float) -> void:
	floor_manager.set_display_adjacent(p_show, opacity)


# ---------------------------------------------------------------------------
# Inspector connections
# ---------------------------------------------------------------------------

func _connect_inspector_signals() -> void:
	property_inspector.property_changed.connect(_on_inspector_property_changed)


func _on_inspector_property_changed(object_id: String, _property: String, _value: Variant) -> void:
	if object_renderer:
		object_renderer.update_object(object_id)
	if wall_renderer:
		wall_renderer.update_wall(object_id)


# ---------------------------------------------------------------------------
# EventBus connections
# ---------------------------------------------------------------------------

func _connect_eventbus_signals() -> void:
	EventBus.tile_placed.connect(_on_tile_placed)
	EventBus.tile_removed.connect(_on_tile_removed)
	EventBus.object_placed.connect(_on_object_changed)
	EventBus.object_removed.connect(_on_object_changed)
	EventBus.obstacle_placed.connect(_on_wall_changed)
	EventBus.obstacle_removed.connect(_on_wall_changed)
	EventBus.floor_changed.connect(_on_floor_changed)
	EventBus.floor_added.connect(_on_floor_list_changed)
	EventBus.floor_removed.connect(_on_floor_list_changed)
	EventBus.selection_changed.connect(_on_selection_changed)
	UndoRedoManager.stack_changed.connect(_on_undo_stack_changed)


func _on_tile_placed(cell: Vector2i, tile_data, layer_index: int) -> void:
	var fd = _current_map.get_active_floor()
	if fd == null or layer_index >= fd.terrain_layers.size():
		return
	var layer = fd.terrain_layers[layer_index]
	grid_renderer.add_tile_to_queue(cell, tile_data, layer.opacity, Color.WHITE)


func _on_tile_removed(cell: Vector2i, _layer_index: int) -> void:
	grid_renderer.remove_tile_from_queue(cell)


func _on_object_changed(_a = null, _b = null, _c = null) -> void:
	var fd = _current_map.get_active_floor()
	if object_renderer and fd:
		object_renderer.set_objects(fd.objects)


func _on_wall_changed(_a = null, _b = null) -> void:
	var fd = _current_map.get_active_floor()
	if wall_renderer and fd:
		wall_renderer.set_walls(fd.walls)


func _on_floor_changed(_old_floor, _new_floor) -> void:
	_refresh_all_views()


func _on_floor_list_changed(_index = null) -> void:
	_refresh_floor_selector()


func _on_selection_changed(selected_type: String, selected_data) -> void:
	if selected_type == "object" and selected_data is String:
		var fd = _current_map.get_active_floor()
		if fd:
			for obj in fd.objects:
				if obj is MapObjectData and obj.object_id == selected_data:
					property_inspector.inspect_object(obj)
					return
		property_inspector.clear_inspection()
	elif selected_type == "wall" and selected_data is String:
		var fd = _current_map.get_active_floor()
		if fd:
			for wall in fd.walls:
				if wall is WallSegmentData and wall.segment_id == selected_data:
					property_inspector.inspect_wall(wall)
					return
		property_inspector.clear_inspection()
	else:
		property_inspector.clear_inspection()


func _on_undo_stack_changed(_ca: bool, _cr: bool, _ud: String, _rd: String) -> void:
	pass


# ---------------------------------------------------------------------------
# Clipboard
# ---------------------------------------------------------------------------

func _on_copy() -> void:
	if _current_map == null:
		return

	if tool_manager.get_active_tool_name() == "select":
		var st = tool_manager.get_active_tool()
		if st is SelectTool:
			var fd = _current_map.get_active_floor()
			if fd:
				var oid = st.get_selected_object_id()
				if not oid.is_empty():
					clipboard.copy_objects([oid], fd.objects)
					status_bar.show_message("已复制")
					return
				var wid = st.get_selected_wall_id()
				if not wid.is_empty():
					clipboard.copy_walls([wid], fd.walls)
					status_bar.show_message("已复制")
					return
	else:
		var mouse_pos = grid_renderer.get_global_mouse_position()
		var cell = grid_renderer.world_to_grid(mouse_pos)
		var layer = tool_manager.get_active_layer()
		if layer and layer.tiles.has(cell):
			clipboard.copy_tiles([cell], layer)
			status_bar.show_message("已复制")


func _on_paste() -> void:
	if not clipboard.has_content() or _current_map == null:
		return

	var mouse_pos = grid_renderer.get_global_mouse_position()
	var cursor_cell = grid_renderer.world_to_grid(mouse_pos)
	var content = clipboard.get_content()
	var offset = clipboard.get_paste_offset(cursor_cell)

	var layer = tool_manager.get_active_layer()
	if layer and not content.tiles.is_empty():
		var cells_to_paste: Array[Vector2i] = []
		for rel_cell in content.tiles.keys():
			if rel_cell is Vector2i:
				var tc = rel_cell + offset
				if tc.x >= 0 and tc.x < _current_map.map_dimensions.x and tc.y >= 0 and tc.y < _current_map.map_dimensions.y:
					cells_to_paste.append(tc)
		if not cells_to_paste.is_empty():
			var td = content.tiles.values()[0] if not content.tiles.is_empty() else {"id": 0}
			var cmd = UndoRedoManager.RectFillCommand.new(layer, cells_to_paste, td.duplicate() if td is Dictionary else td)
			UndoRedoManager.execute_command(cmd)

	var fd = _current_map.get_active_floor()
	if fd and not content.objects.is_empty():
		for od in content.objects:
			if od is MapObjectData:
				var oc = MapObjectData.new()
				oc.object_type = od.object_type
				oc.display_name = od.display_name
				oc.position = od.position + Vector2(float(offset.x) * float(grid_renderer.grid_size.x), float(offset.y) * float(grid_renderer.grid_size.y))
				oc.grid_position = od.grid_position + offset
				oc.rotation = od.rotation
				oc.scale = od.scale
				oc.collision_shape = od.collision_shape
				oc.custom_properties = od.custom_properties.duplicate(true)
				oc.object_id = "obj_paste_%d" % Time.get_ticks_msec()
				var cmd = UndoRedoManager.PlaceObjectCommand.new(fd, oc)
				UndoRedoManager.execute_command(cmd)

	status_bar.show_message("已粘贴")


func _on_cut() -> void:
	_on_copy()
	var mouse_pos = grid_renderer.get_global_mouse_position()
	var cell = grid_renderer.world_to_grid(mouse_pos)
	var layer = tool_manager.get_active_layer()
	if layer and layer.tiles.has(cell):
		var cmd = UndoRedoManager.RemoveTileCommand.new(layer, cell)
		UndoRedoManager.execute_command(cmd)


# ---------------------------------------------------------------------------
# Save / Open
# ---------------------------------------------------------------------------

func _on_save_map() -> void:
	if _current_map == null:
		return
	if _file_path.is_empty():
		_on_save_as_map()
		return
	_current_map.modified_date = _iso_date_now()
	if SerializationManager.save_map(_current_map, _file_path):
		status_bar.show_message("已保存: %s" % _file_path.get_slice("/", -1))


func _on_save_as_map() -> void:
	if _current_map == null:
		return
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.trpgmap", "TRPG Map")
	dialog.title = "另存为"
	dialog.current_file = _current_map.map_name + ".trpgmap"
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		_file_path = path
		if not _file_path.ends_with(".trpgmap"):
			_file_path += ".trpgmap"
		dialog.queue_free()
		_current_map.modified_date = _iso_date_now()
		if SerializationManager.save_map(_current_map, _file_path):
			status_bar.show_message("已保存: %s" % _file_path.get_slice("/", -1))
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered(Vector2(800, 600))


func _on_open_map() -> void:
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.trpgmap", "TRPG Map")
	dialog.title = "打开地图"
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		var loaded = SerializationManager.load_map(path)
		if loaded:
			_current_map = loaded
			_file_path = path
			_active_layer_index = 0
			_apply_map_to_ui(true)
			status_bar.show_message("已加载: %s" % path.get_slice("/", -1))
		else:
			status_bar.show_message("加载失败")
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered(Vector2(800, 600))


func _on_new_map() -> void:
	var dialog = NewMapDialog.new()
	add_child(dialog)
	dialog.map_created.connect(func(map_data: MapData):
		dialog.queue_free()
		_current_map = map_data
		_file_path = ""
		_active_layer_index = 0
		_apply_map_to_ui(true)
		status_bar.show_message("已创建新地图: %s" % map_data.map_name)
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered(Vector2(500, 450))


# ---------------------------------------------------------------------------
# UI refresh helpers
# ---------------------------------------------------------------------------

func _apply_map_to_ui(full_rebuild: bool) -> void:
	if _current_map == null:
		return

	grid_renderer.map_dimensions = _current_map.map_dimensions
	grid_renderer.grid_size = _current_map.grid_size
	grid_renderer.grid_type = _current_map.grid_type

	floor_manager.set_map_data(_current_map)
	tool_manager.inject_dependencies(grid_renderer, floor_manager, _current_map, object_renderer, wall_renderer, preview_overlay)

	wall_renderer.configure(_current_map.map_dimensions, _current_map.grid_size)
	object_renderer.configure(_current_map.map_dimensions, _current_map.grid_size)

	_refresh_all_views()

	if full_rebuild:
		grid_renderer.queue_redraw()

	status_bar.show_message("地图: %s" % _current_map.map_name)


func _refresh_all_views() -> void:
	_refresh_layer_panel()
	_refresh_grid_display()
	_refresh_floor_selector()
	_refresh_wall_display()
	_refresh_object_display()
	if _current_map:
		var af = _current_map.get_active_floor()
		if af:
			status_bar.update_floor(af.floor_name, af.floor_index)


func _refresh_layer_panel() -> void:
	var fd = _current_map.get_active_floor()
	if fd == null:
		return
	var data: Array = []
	for layer in fd.terrain_layers:
		data.append({name = layer.layer_name, index = layer.layer_index, visible = layer.visible, locked = layer.locked, opacity = layer.opacity})
	layer_panel.set_layers(data, _active_layer_index)


func _refresh_grid_display() -> void:
	var fd = _current_map.get_active_floor()
	if fd == null:
		return
	var info: Array = []
	for layer in fd.terrain_layers:
		info.append({tiles = layer.tiles, visible = layer.visible, opacity = layer.opacity, color = Color.WHITE})
	grid_renderer.set_layer_data(info)


func _refresh_floor_selector() -> void:
	if _current_map == null:
		return
	var list: Array = []
	for i in range(_current_map.floors.size()):
		var fd = _current_map.floors[i] as FloorData
		var thumb = floor_manager.get_floor_thumbnail(i)
		list.append({index = i, name = fd.floor_name, thumbnail = thumb, is_active = (i == _current_map.current_floor)})
	floor_selector.set_floors(list, _current_map.current_floor)


func _refresh_wall_display() -> void:
	var fd = _current_map.get_active_floor()
	if fd:
		wall_renderer.set_walls(fd.walls)


func _refresh_object_display() -> void:
	var fd = _current_map.get_active_floor()
	if fd:
		object_renderer.set_objects(fd.objects)


func _make_camera_current() -> void:
	if is_instance_valid(camera):
		camera.enabled = true
		camera.make_current()


func _iso_date_now() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
