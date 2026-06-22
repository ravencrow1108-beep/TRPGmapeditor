##
## MapEditorController — Top-level controller for the map editor.
## Builds the entire editor UI programmatically, owns the current MapData,
## coordinates tool dispatch, save/open, and wires UI events to data model.
##
## IMPORTANT: Controller only forwards events and coordinates — specific
## logic is delegated to the respective managers (UndoRedoManager,
## SerializationManager, GridRenderer).
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


# ---------- Internal state ----------
var _current_map: MapData = null
var _active_tool: String = "select"
var _active_layer_index: int = 0
var _file_path: String = ""


# ---------- Lifecycle ----------

func _ready() -> void:
	_build_ui()
	_connect_menu_signals()
	_connect_toolbar_signals()
	_connect_grid_signals()
	_connect_layer_panel_signals()
	_connect_eventbus_signals()
	_create_default_map()


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-rect anchors on self
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# --- MenuBar ---
	menu_bar = MenuBar.new()
	menu_bar.name = "MenuBar"

	var file_menu= PopupMenu.new()
	file_menu.name = "FileMenu"
	file_menu.add_item("新建地图 (New)", 0)
	file_menu.add_item("打开地图 (Open)", 1)
	file_menu.add_item("保存 (Save)", 2)
	file_menu.add_item("另存为 (Save As)", 3)
	file_menu.add_separator()
	file_menu.add_item("退出 (Exit)", 4)
	menu_bar.add_child(file_menu)

	var edit_menu= PopupMenu.new()
	edit_menu.name = "EditMenu"
	edit_menu.add_item("撤销 (Undo)", 0)
	edit_menu.add_item("重做 (Redo)", 1)
	menu_bar.add_child(edit_menu)

	var view_menu= PopupMenu.new()
	view_menu.name = "ViewMenu"
	view_menu.add_item("放大 (Zoom In)", 0)
	view_menu.add_item("缩小 (Zoom Out)", 1)
	view_menu.add_item("重置缩放 (Reset Zoom)", 2)
	menu_bar.add_child(view_menu)

	var help_menu= PopupMenu.new()
	help_menu.name = "HelpMenu"
	help_menu.add_item("关于 (About)", 0)
	menu_bar.add_child(help_menu)

	menu_bar.set_menu_title(0, "文件 (File)")
	menu_bar.set_menu_title(1, "编辑 (Edit)")
	menu_bar.set_menu_title(2, "视图 (View)")
	menu_bar.set_menu_title(3, "帮助 (Help)")

	add_child(menu_bar)

	# --- Main container ---
	var main_container= HSplitContainer.new()
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

	# --- Left Panel (ToolBar) ---
	var left_panel= VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.custom_minimum_size = Vector2(110, 0)
	left_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = SIZE_EXPAND_FILL

	tool_bar = ToolBar.new()
	tool_bar.name = "ToolBar"
	left_panel.add_child(tool_bar)

	var floor_placeholder= Label.new()
	floor_placeholder.text = "楼层选择 (Phase 1)"
	floor_placeholder.add_theme_font_size_override("font_size", 12)
	floor_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(floor_placeholder)

	main_container.add_child(left_panel)

	# --- Center Panel (SubViewport map area) ---
	var center_panel= Panel.new()
	center_panel.name = "CenterPanel"
	center_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = SIZE_EXPAND_FILL

	var svp_container= SubViewportContainer.new()
	svp_container.name = "SubViewportContainer"
	svp_container.anchor_left = 0.0
	svp_container.anchor_top = 0.0
	svp_container.anchor_right = 1.0
	svp_container.anchor_bottom = 1.0
	svp_container.stretch = true
	center_panel.add_child(svp_container)

	var sub_viewport= SubViewport.new()
	sub_viewport.name = "SubViewport"
	sub_viewport.handle_input_locally = true
	sub_viewport.gui_embed_subwindows = false
	svp_container.add_child(sub_viewport)

	var map_root= Node2D.new()
	map_root.name = "MapRoot"
	sub_viewport.add_child(map_root)

	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.make_current()
	map_root.add_child(camera)

	grid_renderer = GridRenderer.new()
	grid_renderer.name = "GridRenderer"
	grid_renderer.grid_size = Vector2i(32, 32)
	grid_renderer.map_dimensions = Vector2i(100, 100)
	map_root.add_child(grid_renderer)

	var editor_overlay= Node2D.new()
	editor_overlay.name = "EditorOverlay"
	map_root.add_child(editor_overlay)

	main_container.add_child(center_panel)

	# --- Right Panel (LayerPanel + TilePalette) ---
	var right_panel= VSplitContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(250, 0)
	right_panel.size_flags_horizontal = SIZE_EXPAND_FILL

	layer_panel = LayerPanel.new()
	layer_panel.name = "LayerPanel"
	layer_panel.size_flags_vertical = SIZE_EXPAND_FILL
	right_panel.add_child(layer_panel)

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
# Default map creation (New Map entry point)
# ---------------------------------------------------------------------------

func _create_default_map() -> void:
	_current_map = MapData.new()
	_current_map.map_name = "新建地图"
	_current_map.created_date = _iso_date_now()
	_current_map.modified_date = _current_map.created_date

	var floor= FloorData.new()
	floor.floor_index = 0
	floor.floor_name = "地面层"

	var layer= TerrainLayerData.new()
	layer.layer_index = 0
	layer.layer_name = "图层 1"
	floor.terrain_layers.append(layer)

	_current_map.floors.append(floor)
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


func _on_view_menu(id: int) -> void:
	if not is_instance_valid(grid_renderer) or not is_instance_valid(camera):
		return
	match id:
		0:  # Zoom In
			var zx= camera.zoom.x * (1.0 / 0.8)
			var zy= camera.zoom.y * (1.0 / 0.8)
			camera.zoom = Vector2(clampf(zx, 0.25, 4.0), clampf(zy, 0.25, 4.0))
		1:  # Zoom Out
			var zx= camera.zoom.x * 0.8
			var zy= camera.zoom.y * 0.8
			camera.zoom = Vector2(clampf(zx, 0.25, 4.0), clampf(zy, 0.25, 4.0))
		2:  # Reset Zoom
			camera.zoom = Vector2.ONE
			camera.position = Vector2.ZERO
	status_bar.update_zoom(camera.zoom.x)


# ---------------------------------------------------------------------------
# Toolbar connections
# ---------------------------------------------------------------------------

func _connect_toolbar_signals() -> void:
	tool_bar.tool_selected.connect(_on_tool_selected)


func _on_tool_selected(tool_name: String) -> void:
	_active_tool = tool_name
	status_bar.update_tool(tool_name)
	EventBus.selection_changed.emit("tool", tool_name)


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
	var floor= _current_map.get_active_floor()
	if floor == null:
		return
	if _active_layer_index < 0 or _active_layer_index >= floor.terrain_layers.size():
		return

	var layer = floor.terrain_layers[_active_layer_index]
		if not layer is TerrainLayerData: return
	return

	match _active_tool:
		"brush":
			var tile_data= {"id": 0}
			var cmd= UndoRedoManager.PlaceTileCommand.new(layer, grid_pos, tile_data)
			UndoRedoManager.execute_command(cmd)
			_refresh_grid_display()

		"eraser":
			if layer.tiles.has(grid_pos):
				var cmd= UndoRedoManager.RemoveTileCommand.new(layer, grid_pos)
				UndoRedoManager.execute_command(cmd)
				_refresh_grid_display()


func _on_grid_tile_right_clicked(grid_pos: Vector2i) -> void:
	pass


func _on_grid_mouse_moved(world_pos: Vector2, grid_pos: Vector2i) -> void:
	status_bar.update_position(grid_pos)


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


func _on_layer_visibility_toggled(index: int, visible: bool) -> void:
	var floor= _current_map.get_active_floor()
	if floor and index < floor.terrain_layers.size():
		floor.terrain_layers[index].visible = visible
		_refresh_grid_display()


func _on_layer_lock_toggled(index: int, locked: bool) -> void:
	var floor= _current_map.get_active_floor()
	if floor and index < floor.terrain_layers.size():
		floor.terrain_layers[index].locked = locked


func _on_layer_opacity_changed(index: int, opacity: float) -> void:
	var floor= _current_map.get_active_floor()
	if floor and index < floor.terrain_layers.size():
		floor.terrain_layers[index].opacity = opacity
		_refresh_grid_display()


func _on_add_layer() -> void:
	var floor= _current_map.get_active_floor()
	if floor == null:
		return
	var layer= TerrainLayerData.new()
	layer.layer_index = floor.terrain_layers.size()
	layer.layer_name = "图层 %d" % (layer.layer_index + 1)
	floor.terrain_layers.append(layer)
	_refresh_layer_panel()
	_refresh_grid_display()


func _on_remove_layer(index: int) -> void:
	var floor= _current_map.get_active_floor()
	if floor == null or floor.terrain_layers.size() <= 1:
		return
	if index < 0 or index >= floor.terrain_layers.size():
		return
	floor.terrain_layers.remove_at(index)
	for i in range(floor.terrain_layers.size()):
		(floor.terrain_layers[i] as TerrainLayerData).layer_index = i
	if _active_layer_index >= floor.terrain_layers.size():
		_active_layer_index = floor.terrain_layers.size() - 1
	_refresh_layer_panel()
	_refresh_grid_display()


func _on_reorder_layer(from_index: int, to_index: int) -> void:
	var floor= _current_map.get_active_floor()
	if floor == null:
		return
	var size= floor.terrain_layers.size()
	if from_index < 0 or from_index >= size or to_index < 0 or to_index >= size:
		return
	var moved= floor.terrain_layers.pop_at(from_index)
	floor.terrain_layers.insert(to_index, moved)
	for i in size:
		(floor.terrain_layers[i] as TerrainLayerData).layer_index = i
	_active_layer_index = to_index
	_refresh_layer_panel()
	_refresh_grid_display()


# ---------------------------------------------------------------------------
# EventBus connections
# ---------------------------------------------------------------------------

func _connect_eventbus_signals() -> void:
	EventBus.tile_placed.connect(_on_tile_placed)
	EventBus.tile_removed.connect(_on_tile_removed)
	UndoRedoManager.stack_changed.connect(_on_undo_stack_changed)


func _on_tile_placed(cell: Vector2i, tile_data, layer_index: int) -> void:
	var floor= _current_map.get_active_floor()
	if floor == null or layer_index >= floor.terrain_layers.size():
		return
	var layer: TerrainLayerData = floor.terrain_layers[layer_index]
	grid_renderer.add_tile_to_queue(cell, tile_data, layer.opacity, Color.WHITE)


func _on_tile_removed(cell: Vector2i, layer_index: int) -> void:
	grid_renderer.remove_tile_from_queue(cell)


func _on_undo_stack_changed(can_undo: bool, can_redo: bool, undo_desc: String, redo_desc: String) -> void:
	pass


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
		status_bar.show_message("已保存: %s" % _file_path.get_file())


func _on_save_as_map() -> void:
	if _current_map == null:
		return
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.trpgmap", "TRPG Map")
	dialog.title = "另存为"
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var final_path = path; if not final_path.ends_with(".trpgmap"): final_path = final_path + ".trpgmap"; _file_path = final_path
		dialog.queue_free()
		_current_map.modified_date = _iso_date_now()
		if SerializationManager.save_map(_current_map, _file_path):
			status_bar.show_message("已保存: %s" % _file_path.get_file())
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
		var loaded= SerializationManager.load_map(path)
		if loaded:
			_current_map = loaded
			var final_path = path; if not final_path.ends_with(".trpgmap"): final_path = final_path + ".trpgmap"; _file_path = final_path
			_active_layer_index = 0
			_apply_map_to_ui(true)
			status_bar.show_message("已加载: %s" % path.get_file())
		else:
			status_bar.show_message("加载失败: %s" % path.get_file())
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered(Vector2(800, 600))


func _on_new_map() -> void:
	var dialog= AcceptDialog.new()
	dialog.title = "新建地图"
	dialog.dialog_text = "创建新的空白地图？"
	dialog.ok_button_text = "创建"
	add_child(dialog)
	dialog.confirmed.connect(func():
		dialog.queue_free()
		_create_default_map()
		_file_path = ""
		status_bar.show_message("已创建新地图")
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()


# ---------------------------------------------------------------------------
# UI refresh helpers
# ---------------------------------------------------------------------------

func _apply_map_to_ui(full_rebuild: bool) -> void:
	if _current_map == null:
		return
	grid_renderer.map_dimensions = _current_map.map_dimensions
	grid_renderer.grid_size = _current_map.grid_size

	_refresh_layer_panel()
	_refresh_grid_display()

	if full_rebuild:
		grid_renderer.queue_redraw()

	status_bar.show_message("地图: %s" % _current_map.map_name)


func _refresh_layer_panel() -> void:
	var floor= _current_map.get_active_floor()
	if floor == null:
		return
	var layer_data: Array = []
	for layer in floor.terrain_layers:
		layer_data.append({
			name = layer.layer_name,
			index = layer.layer_index,
			visible = layer.visible,
			locked = layer.locked,
			opacity = layer.opacity
		})
	layer_panel.set_layers(layer_data, _active_layer_index)


func _refresh_grid_display() -> void:
	var floor= _current_map.get_active_floor()
	if floor == null:
		return
	var layer_info: Array = []
	for layer in floor.terrain_layers:
		layer_info.append({
			tiles = layer.tiles,
			visible = layer.visible,
			opacity = layer.opacity,
			color = Color.WHITE
		})
	grid_renderer.set_layer_data(layer_info)


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

func _iso_date_now() -> String:
	var dt= Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
