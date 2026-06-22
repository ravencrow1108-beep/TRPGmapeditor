##
## ObjectPropertyInspector — Right-side panel showing editable properties of a selected item.
## Dynamically builds form fields based on the selected item's type (object or wall).
##
class_name ObjectPropertyInspector
extends VBoxContainer


@warning_ignore("unused_signal")
signal property_changed(object_id: String, property: String, value: Variant)


var _current_object: MapObjectData = null
var _current_wall: WallSegmentData = null
var _form_container: VBoxContainer = null
var _no_selection_label: Label = null


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	var title = Label.new()
	title.text = "属性"
	title.add_theme_font_size_override("font_size", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_form_container = VBoxContainer.new()
	_form_container.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_form_container)
	add_child(scroll)

	_no_selection_label = Label.new()
	_no_selection_label.text = "未选择"
	_no_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_selection_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_no_selection_label.add_theme_font_size_override("font_size", 13)
	_form_container.add_child(_no_selection_label)


func inspect_object(obj: MapObjectData) -> void:
	_current_object = obj
	_current_wall = null
	_rebuild_form()


func inspect_wall(wall: WallSegmentData) -> void:
	_current_wall = wall
	_current_object = null
	_rebuild_form()


func clear_inspection() -> void:
	_current_object = null
	_current_wall = null
	_rebuild_form()


func _rebuild_form() -> void:
	_clear_form()

	if _current_object != null:
		_build_object_form()
	elif _current_wall != null:
		_build_wall_form()
	else:
		if _no_selection_label == null or not is_instance_valid(_no_selection_label):
			_no_selection_label = Label.new()
			_no_selection_label.text = "未选择"
			_form_container.add_child(_no_selection_label)
		else:
			_no_selection_label.visible = true


func _clear_form() -> void:
	for child in _form_container.get_children():
		child.queue_free()
	_no_selection_label = null


func _build_object_form() -> void:
	var obj = _current_object
	if obj == null:
		return

	_add_readonly("ID", obj.object_id)

	_add_line_edit("名称", obj.display_name, func(text: String):
		obj.display_name = text
		property_changed.emit(obj.object_id, "display_name", text)
	)

	_add_line_edit("类型", obj.object_type, func(text: String):
		obj.object_type = text
		property_changed.emit(obj.object_id, "object_type", text)
	)

	_add_readonly("位置", "(%.0f, %.0f)" % [obj.position.x, obj.position.y])
	_add_readonly("格位", "(%d, %d)" % [obj.grid_position.x, obj.grid_position.y])

	_add_spin_box("旋转", obj.rotation, -360.0, 360.0, 1.0, func(value: float):
		obj.rotation = value
		property_changed.emit(obj.object_id, "rotation", value)
	)

	_add_spin_box("缩放 X", obj.scale.x, 0.1, 10.0, 0.1, func(value: float):
		obj.scale.x = value
		property_changed.emit(obj.object_id, "scale_x", value)
	)

	_add_spin_box("缩放 Y", obj.scale.y, 0.1, 10.0, 0.1, func(value: float):
		obj.scale.y = value
		property_changed.emit(obj.object_id, "scale_y", value)
	)

	_add_spin_box("Z 层级", obj.z_index, -100, 100, 1, func(value: int):
		obj.z_index = value
		property_changed.emit(obj.object_id, "z_index", value)
	)

	_add_option("碰撞形状", ["矩形", "圆形", "多边形", "网格填充"], obj.collision_shape, func(idx: int):
		obj.collision_shape = idx
		property_changed.emit(obj.object_id, "collision_shape", idx)
	)

	if not obj.custom_properties.is_empty():
		var prop_label = Label.new()
		prop_label.text = "自定义属性:"
		prop_label.add_theme_font_size_override("font_size", 12)
		_form_container.add_child(prop_label)
		for key in obj.custom_properties.keys():
			_add_readonly(key, str(obj.custom_properties[key]))


func _build_wall_form() -> void:
	var wall = _current_wall
	if wall == null:
		return

	_add_readonly("ID", wall.segment_id)

	var type_names = ["实墙", "窗户", "栏杆", "幻象", "半高", "透明"]
	_add_option("墙类型", type_names, wall.wall_type, func(idx: int):
		wall.wall_type = idx
		property_changed.emit(wall.segment_id, "wall_type", idx)
	)

	_add_spin_box("高度 (m)", wall.height, 0.0, 20.0, 0.5, func(value: float):
		wall.height = value
		property_changed.emit(wall.segment_id, "height", value)
	)

	_add_spin_box("厚度 (m)", wall.thickness, 0.05, 5.0, 0.05, func(value: float):
		wall.thickness = value
		property_changed.emit(wall.segment_id, "thickness", value)
	)

	var flags_label = Label.new()
	flags_label.text = "阻挡标记:"
	flags_label.add_theme_font_size_override("font_size", 12)
	_form_container.add_child(flags_label)

	var flag_names = ["视野", "光线", "弹射物", "移动", "飞行", "掘地"]
	var flag_consts = [
		WallSegmentData.BLOCK_VISION,
		WallSegmentData.BLOCK_LIGHT,
		WallSegmentData.BLOCK_PROJECTILE,
		WallSegmentData.BLOCK_MOVEMENT,
		WallSegmentData.BLOCK_FLYING,
		WallSegmentData.BLOCK_BURROWING
	]

	for i in range(flag_names.size()):
		var fc = flag_consts[i]
		_add_checkbox(flag_names[i], wall.has_flag(fc), func(toggled: bool, f = fc):
			wall.set_flag(f, toggled)
			property_changed.emit(wall.segment_id, "block_flags", wall.block_flags)
		)


# ---------- Field builders ----------

func _add_readonly(label_text: String, value_text: String) -> void:
	var row = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 12)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	var value_lbl = Label.new()
	value_lbl.text = value_text
	value_lbl.add_theme_font_size_override("font_size", 12)
	value_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(value_lbl)
	_form_container.add_child(row)


func _add_line_edit(label_text: String, initial_value: String, callback: Callable) -> void:
	var row = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 12)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	var le = LineEdit.new()
	le.text = initial_value
	le.size_flags_horizontal = SIZE_EXPAND_FILL
	le.text_changed.connect(func(text: String): callback.call(text))
	row.add_child(le)
	_form_container.add_child(row)


func _add_spin_box(label_text: String, initial_value: float, min_val: float, max_val: float, step: float, callback: Callable) -> void:
	var row = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 12)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	var sb = SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.step = step
	sb.value = initial_value
	sb.size_flags_horizontal = SIZE_EXPAND_FILL
	sb.value_changed.connect(func(value: float): callback.call(value))
	row.add_child(sb)
	_form_container.add_child(row)


func _add_option(label_text: String, items: Array, selected: int, callback: Callable) -> void:
	var row = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text + ":"
	label.add_theme_font_size_override("font_size", 12)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)
	var ob = OptionButton.new()
	for item in items:
		ob.add_item(item)
	ob.select(selected)
	ob.size_flags_horizontal = SIZE_EXPAND_FILL
	ob.item_selected.connect(func(idx: int): callback.call(idx))
	row.add_child(ob)
	_form_container.add_child(row)


func _add_checkbox(label_text: String, checked: bool, callback: Callable) -> void:
	var cb = CheckBox.new()
	cb.text = label_text
	cb.button_pressed = checked
	cb.toggled.connect(func(toggled: bool): callback.call(toggled))
	_form_container.add_child(cb)
