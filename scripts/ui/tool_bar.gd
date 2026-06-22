##
## ToolBar — Vertical toolbar with toggle-mode tool buttons.
## All 12 tools functional in Phase 1. Sub-mode buttons appear for Brush.
##
class_name ToolBar
extends VBoxContainer


signal tool_selected(tool_name)
@warning_ignore("unused_signal")
signal brush_mode_requested(mode_name)
@warning_ignore("unused_signal")
signal wall_type_requested(wall_type_index)


const TOOLS: Array = [
	{ name = "select",  label = "选择",   icon_text = "⬚" },
	{ name = "brush",   label = "笔刷",   icon_text = "🖌" },
	{ name = "line",    label = "线段",   icon_text = "╱" },
	{ name = "rect",    label = "矩形",   icon_text = "▭" },
	{ name = "fill",    label = "填充",   icon_text = "▣" },
	{ name = "eraser",  label = "橡皮擦", icon_text = "◻" },
	{ name = "wall",    label = "墙壁",   icon_text = "▊" },
	{ name = "portal",  label = "传送门", icon_text = "◎" },
	{ name = "light",   label = "光源",   icon_text = "☀" },
	{ name = "fog",     label = "迷雾",   icon_text = "☁" },
	{ name = "token",   label = "指示物", icon_text = "♟" },
	{ name = "measure", label = "测量",   icon_text = "↔" },
]

var _group: ButtonGroup = null
var _brush_mode_container: HBoxContainer = null
var _wall_type_option: OptionButton = null
var _wall_type_container: HBoxContainer = null


func _ready() -> void:
	_setup_buttons()
	_setup_sub_options()


func _setup_buttons() -> void:
	_group = ButtonGroup.new()
	var first = true

	for tool_def in TOOLS:
		var btn = Button.new()
		btn.text = "%s %s" % [tool_def.icon_text, tool_def.label]
		btn.toggle_mode = true
		btn.button_group = _group
		btn.name = tool_def.name
		btn.add_theme_font_size_override("font_size", 13)
		btn.size_flags_horizontal = SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(96, 32)
		btn.set_meta("tool_name", tool_def.name)
		btn.pressed.connect(_on_button_pressed.bind(btn))
		if first:
			btn.button_pressed = true
			first = false
		add_child(btn)


func _setup_sub_options() -> void:
	_brush_mode_container = HBoxContainer.new()
	_brush_mode_container.name = "BrushModes"
	_brush_mode_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_brush_mode_container.visible = false

	var modes = [
		{ name = "single", label = "点" },
		{ name = "line",   label = "线" },
		{ name = "rect",   label = "框" },
		{ name = "fill",   label = "填" },
	]
	var mode_group = ButtonGroup.new()
	var first_mode = true

	for mode_def in modes:
		var btn = Button.new()
		btn.text = mode_def.label
		btn.toggle_mode = true
		btn.button_group = mode_group
		btn.name = mode_def.name
		btn.custom_minimum_size = Vector2(28, 26)
		btn.add_theme_font_size_override("font_size", 12)
		btn.set_meta("mode", mode_def.name)
		btn.pressed.connect(func(): brush_mode_requested.emit(mode_def.name))
		if first_mode:
			btn.button_pressed = true
			first_mode = false
		_brush_mode_container.add_child(btn)

	add_child(_brush_mode_container)

	_wall_type_container = HBoxContainer.new()
	_wall_type_container.name = "WallTypes"
	_wall_type_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_wall_type_container.visible = false

	_wall_type_option = OptionButton.new()
	_wall_type_option.add_item("实墙")
	_wall_type_option.add_item("窗户")
	_wall_type_option.add_item("栏杆")
	_wall_type_option.add_item("幻象")
	_wall_type_option.add_item("半高")
	_wall_type_option.add_item("透明")
	_wall_type_option.custom_minimum_size = Vector2(80, 26)
	_wall_type_option.item_selected.connect(func(idx: int):
		wall_type_requested.emit(idx)
	)
	_wall_type_container.add_child(_wall_type_option)

	add_child(_wall_type_container)

	var spacer = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(spacer)


func _on_button_pressed(btn: Button) -> void:
	var tool_name: String = btn.get_meta("tool_name", "")
	tool_selected.emit(tool_name)
	_update_sub_options(tool_name)


func _update_sub_options(tool_name: String) -> void:
	if _brush_mode_container:
		_brush_mode_container.visible = (tool_name == "brush")
	if _wall_type_container:
		_wall_type_container.visible = (tool_name == "wall")
