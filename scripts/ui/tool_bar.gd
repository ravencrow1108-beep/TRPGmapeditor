##
## ToolBar — Vertical toolbar with toggle-mode tool buttons.
## Phase 0: only Brush and Eraser are functional; others show a notice.
##
class_name ToolBar
extends VBoxContainer


signal tool_selected(tool_name)


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


func _ready() -> void:
	_setup_buttons()


func _setup_buttons() -> void:
	var group = ButtonGroup.new()
	var first = true

	for tool_def in TOOLS:
		var btn = Button.new()
		btn.text = "%s %s" % [tool_def.icon_text, tool_def.label]
		btn.toggle_mode = true
		btn.button_group = group
		btn.name = tool_def.name
		btn.add_theme_font_size_override("font_size", 14)
		btn.size_flags_horizontal = SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(96, 36)

		# Tag with tool name in metadata
		btn.set_meta("tool_name", tool_def.name)
		btn.pressed.connect(_on_button_pressed.bind(btn))

		if first:
			btn.button_pressed = true
			first = false

		add_child(btn)

	# Spacer to push buttons to the top
	var spacer = Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(spacer)


func _on_button_pressed(btn: Button) -> void:
	var tool_name: String = btn.get_meta("tool_name", "")
	var valid_phase0 = ["brush", "eraser", "select"]

	if tool_name in valid_phase0:
		tool_selected.emit(tool_name)
	else:
		tool_selected.emit(tool_name)
		# Show notice for Phase 0 unimplemented tools
		print("[ToolBar] '%s' tool not implemented in Phase 0" % tool_name)
