##
## FloorSelector — Vertical panel listing all floors with thumbnails and edit buttons.
## Replaces the Phase 0 "Floor Select (Phase 1)" placeholder.
##
class_name FloorSelector
extends VBoxContainer


signal floor_clicked(index: int)
signal floor_double_clicked(index: int)
signal floor_add_requested()
signal floor_duplicate_requested(index: int)
signal floor_delete_requested(index: int)
signal floor_move_up_requested(index: int)
signal floor_move_down_requested(index: int)
signal show_adjacent_floors_changed(show: bool, opacity: float)


var _scroll_container: ScrollContainer = null
var _floor_list: VBoxContainer = null
var _entries: Array = []
var _active_floor_index: int = 0
var _floor_count: int = 0


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	var title = Label.new()
	title.text = "楼层"
	title.add_theme_font_size_override("font_size", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll_container.custom_minimum_size = Vector2(100, 200)
	_floor_list = VBoxContainer.new()
	_floor_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll_container.add_child(_floor_list)
	add_child(_scroll_container)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var add_btn = Button.new()
	add_btn.text = "+"
	add_btn.tooltip_text = "添加楼层"
	add_btn.pressed.connect(func(): floor_add_requested.emit())
	btn_row.add_child(add_btn)

	var dup_btn = Button.new()
	dup_btn.text = "⧉"
	dup_btn.tooltip_text = "复制楼层"
	dup_btn.pressed.connect(func(): floor_duplicate_requested.emit(_active_floor_index))
	btn_row.add_child(dup_btn)

	var del_btn = Button.new()
	del_btn.text = "−"
	del_btn.tooltip_text = "删除楼层"
	del_btn.pressed.connect(func(): floor_delete_requested.emit(_active_floor_index))
	btn_row.add_child(del_btn)

	var up_btn = Button.new()
	up_btn.text = "↑"
	up_btn.tooltip_text = "上移"
	up_btn.pressed.connect(func():
		if _active_floor_index > 0:
			floor_move_up_requested.emit(_active_floor_index)
	)
	btn_row.add_child(up_btn)

	var down_btn = Button.new()
	down_btn.text = "↓"
	down_btn.tooltip_text = "下移"
	down_btn.pressed.connect(func():
		if _active_floor_index < _floor_count - 1:
			floor_move_down_requested.emit(_active_floor_index)
	)
	btn_row.add_child(down_btn)

	add_child(btn_row)

	var adj_row = HBoxContainer.new()
	var adj_check = CheckBox.new()
	adj_check.text = "显示邻层"
	adj_check.tooltip_text = "显示相邻楼层（降低不透明度）"
	adj_check.toggled.connect(func(toggled: bool):
		show_adjacent_floors_changed.emit(toggled, 0.25)
	)
	adj_row.add_child(adj_check)

	var adj_opacity_slider = HSlider.new()
	adj_opacity_slider.min_value = 0.1
	adj_opacity_slider.max_value = 0.5
	adj_opacity_slider.step = 0.05
	adj_opacity_slider.value = 0.25
	adj_opacity_slider.size_flags_horizontal = SIZE_EXPAND_FILL
	adj_opacity_slider.visible = false
	adj_opacity_slider.value_changed.connect(func(value: float):
		show_adjacent_floors_changed.emit(adj_check.button_pressed, value)
	)
	adj_check.toggled.connect(func(toggled: bool):
		adj_opacity_slider.visible = toggled
	)
	adj_row.add_child(adj_opacity_slider)
	add_child(adj_row)


func set_floors(floors: Array, active_index: int) -> void:
	_active_floor_index = active_index
	_floor_count = floors.size()

	for child in _floor_list.get_children():
		child.queue_free()
	_entries.clear()

	for i in range(floors.size()):
		var data: Dictionary = floors[i]
		var entry = _build_floor_entry(i, data)
		_entries.append(entry)
		_floor_list.add_child(entry)


func _build_floor_entry(index: int, data: Dictionary) -> Node:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 48)

	var thumb_rect = TextureRect.new()
	thumb_rect.custom_minimum_size = Vector2(64, 36)
	thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var thumb_img = data.get("thumbnail", null)
	if thumb_img is Image and not thumb_img.is_empty():
		var tex = ImageTexture.create_from_image(thumb_img)
		thumb_rect.texture = tex
	row.add_child(thumb_rect)

	var name_btn = Button.new()
	name_btn.text = data.get("name", "Floor %d" % index)
	name_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	name_btn.toggle_mode = true
	name_btn.button_pressed = data.get("is_active", false)
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.add_theme_font_size_override("font_size", 13)
	name_btn.pressed.connect(func(): floor_clicked.emit(index))
	name_btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
			floor_double_clicked.emit(index)
	)
	row.add_child(name_btn)

	return row
