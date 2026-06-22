##
## StatusBar — Bottom status bar displaying grid position, zoom level,
## active tool, active floor, and status messages.
##
class_name StatusBar
extends HBoxContainer


var _position_label: Label
var _zoom_label: Label
var _tool_label: Label
var _floor_label: Label
var _mode_label: Label
var _message_label: Label


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	custom_minimum_size = Vector2(0, 28)

	_position_label = Label.new()
	_position_label.text = "Grid: (0, 0)"
	_position_label.add_theme_font_size_override("font_size", 12)
	add_child(_position_label)

	add_child(_make_sep())

	_zoom_label = Label.new()
	_zoom_label.text = "Zoom: 100%"
	_zoom_label.add_theme_font_size_override("font_size", 12)
	add_child(_zoom_label)

	add_child(_make_sep())

	_tool_label = Label.new()
	_tool_label.text = "Tool: Select"
	_tool_label.add_theme_font_size_override("font_size", 12)
	add_child(_tool_label)

	add_child(_make_sep())

	_floor_label = Label.new()
	_floor_label.text = "Floor: —"
	_floor_label.add_theme_font_size_override("font_size", 12)
	add_child(_floor_label)

	add_child(_make_sep())

	_mode_label = Label.new()
	_mode_label.text = ""
	_mode_label.add_theme_font_size_override("font_size", 12)
	_mode_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	add_child(_mode_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(spacer)

	_message_label = Label.new()
	_message_label.text = ""
	_message_label.add_theme_font_size_override("font_size", 12)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_message_label)


func _make_sep() -> VSeparator:
	return VSeparator.new()


func update_position(grid_pos: Vector2i) -> void:
	_position_label.text = "Grid: (%d, %d)" % [grid_pos.x, grid_pos.y]


func update_zoom(zoom: float) -> void:
	_zoom_label.text = "Zoom: %d%%" % int(zoom * 100)


func update_tool(tool_name: String) -> void:
	_tool_label.text = "Tool: %s" % tool_name.capitalize()


func update_floor(floor_name: String, floor_index: int) -> void:
	_floor_label.text = "Floor: %s (%d)" % [floor_name, floor_index]


func update_mode(mode: String) -> void:
	_mode_label.text = mode


func show_message(msg: String) -> void:
	_message_label.text = msg
