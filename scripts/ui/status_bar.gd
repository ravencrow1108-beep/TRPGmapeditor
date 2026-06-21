##
## StatusBar — Bottom status bar displaying grid position, zoom level, and active tool.
##
class_name StatusBar
extends HBoxContainer


var _position_label: Label
var _zoom_label: Label
var _tool_label: Label
var _message_label: Label


func _ready() -> void:
	_setup_ui()


func _setup_ui() -> void:
	custom_minimum_size = Vector2(0, 28)

	_position_label = Label.new()
	_position_label.text = "Grid: (0, 0)"
	_position_label.add_theme_font_size_override("font_size", 12)
	add_child(_position_label)

	var sep1 = VSeparator.new()
	add_child(sep1)

	_zoom_label = Label.new()
	_zoom_label.text = "Zoom: 100%"
	_zoom_label.add_theme_font_size_override("font_size", 12)
	add_child(_zoom_label)

	var sep2 = VSeparator.new()
	add_child(sep2)

	_tool_label = Label.new()
	_tool_label.text = "Tool: Select"
	_tool_label.add_theme_font_size_override("font_size", 12)
	add_child(_tool_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(spacer)

	_message_label = Label.new()
	_message_label.text = ""
	_message_label.add_theme_font_size_override("font_size", 12)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_message_label)


func update_position(grid_pos: Vector2i) -> void:
	_position_label.text = "Grid: (%d, %d)" % [grid_pos.x, grid_pos.y]


func update_zoom(zoom: float) -> void:
	_zoom_label.text = "Zoom: %d%%" % int(zoom * 100)


func update_tool(tool_name: String) -> void:
	_tool_label.text = "Tool: %s" % tool_name.capitalize()


func show_message(msg: String) -> void:
	_message_label.text = msg
