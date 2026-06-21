##
## LayerPanel — Right-side panel for terrain layer management.
## Shows a list of layers with visibility/lock toggles, opacity slider,
## and add/remove/reorder buttons.
##
class_name LayerPanel
extends VBoxContainer


# ---------- Signals ----------
signal layer_selected(index: int)
signal layer_visibility_toggled(index: int, visible: bool)
signal layer_lock_toggled(index: int, locked: bool)
signal layer_opacity_changed(index: int, opacity: float)
signal layer_add_requested()
signal layer_remove_requested(index: int)
signal layer_reorder_requested(from_index: int, to_index: int)


# ---------- Node refs ----------
var _layer_list: VBoxContainer = null
var _opacity_slider: HSlider = null
var _entries: Array = []
var _active_layer_index: int = 0


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	# Title
	var title = Label.new()
	title.text = "图层"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Layer list in a scroll container
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(200, 150)
	_layer_list = VBoxContainer.new()
	_layer_list.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_layer_list)
	add_child(scroll)

	# Opacity slider row
	var opacity_row = HBoxContainer.new()
	var opacity_label = Label.new()
	opacity_label.text = "不透明度"
	opacity_row.add_child(opacity_label)
	_opacity_slider = HSlider.new()
	_opacity_slider.min_value = 0.0
	_opacity_slider.max_value = 1.0
	_opacity_slider.step = 0.01
	_opacity_slider.value = 1.0
	_opacity_slider.size_flags_horizontal = SIZE_EXPAND_FILL
	_opacity_slider.value_changed.connect(_on_opacity_slider_changed)
	opacity_row.add_child(_opacity_slider)
	add_child(opacity_row)

	# Buttons row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var add_btn = Button.new()
	add_btn.text = "+"
	add_btn.tooltip_text = "添加图层"
	add_btn.pressed.connect(func(): layer_add_requested.emit())
	btn_row.add_child(add_btn)

	var rem_btn = Button.new()
	rem_btn.text = "-"
	rem_btn.tooltip_text = "删除图层"
	rem_btn.pressed.connect(func(): layer_remove_requested.emit(_active_layer_index))
	btn_row.add_child(rem_btn)

	var up_btn = Button.new()
	up_btn.text = "↑"
	up_btn.tooltip_text = "上移"
	up_btn.pressed.connect(func():
		if _active_layer_index > 0:
			layer_reorder_requested.emit(_active_layer_index, _active_layer_index - 1)
	)
	btn_row.add_child(up_btn)

	var down_btn = Button.new()
	down_btn.text = "↓"
	down_btn.tooltip_text = "下移"
	down_btn.pressed.connect(func():
		if _active_layer_index < _entries.size() - 1:
			layer_reorder_requested.emit(_active_layer_index, _active_layer_index + 1)
	)
	btn_row.add_child(down_btn)

	add_child(btn_row)


## Populate the layer list from data.
func set_layers(layers: Array, active_index: int) -> void:
	_active_layer_index = active_index

	# Clear existing entries
	for child in _layer_list.get_children():
		child.queue_free()
	_entries.clear()

	for i in range(layers.size()):
		var data: Dictionary = layers[i]
		var entry = _build_layer_entry(i, data)
		_entries.append(entry)
		_layer_list.add_child(entry)

	if _active_layer_index < _entries.size():
		_opacity_slider.set_value_no_signal(layers[_active_layer_index].get("opacity", 1.0))


func _build_layer_entry(index: int, data: Dictionary) -> Node:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = SIZE_EXPAND_FILL

	# Select button
	var select_btn = Button.new()
	select_btn.text = data.get("name", "Layer %d" % index)
	select_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	select_btn.toggle_mode = true
	select_btn.button_pressed = (index == _active_layer_index)
	select_btn.pressed.connect(func():
		layer_selected.emit(index)
		# Update highlight
		for j in range(_entries.size()):
			var entry_row = _entries[j] as HBoxContainer
			if entry_row:
				var btn = entry_row.get_child(0) as Button
				if btn:
					btn.button_pressed = (j == index)
		if index < _entries.size():
			# Also update opacity slider
			pass
	)
	row.add_child(select_btn)

	# Visibility toggle (eye icon)
	var vis_btn = Button.new()
	vis_btn.text = "👁" if data.get("visible", true) else "—"
	vis_btn.toggle_mode = true
	vis_btn.button_pressed = data.get("visible", true)
	vis_btn.tooltip_text = "显示/隐藏"
	vis_btn.pressed.connect(func():
		vis_btn.text = "👁" if vis_btn.button_pressed else "—"
		layer_visibility_toggled.emit(index, vis_btn.button_pressed)
	)
	row.add_child(vis_btn)

	# Lock toggle
	var lock_btn = Button.new()
	lock_btn.text = "🔓" if not data.get("locked", false) else "🔒"
	lock_btn.toggle_mode = true
	lock_btn.button_pressed = data.get("locked", false)
	lock_btn.tooltip_text = "锁定/解锁"
	lock_btn.pressed.connect(func():
		lock_btn.text = "🔒" if lock_btn.button_pressed else "🔓"
		layer_lock_toggled.emit(index, lock_btn.button_pressed)
	)
	row.add_child(lock_btn)

	return row


func _on_opacity_slider_changed(value: float) -> void:
	if _active_layer_index < _entries.size():
		layer_opacity_changed.emit(_active_layer_index, value)
