##
## PreviewOverlay — Shared overlay layer for tool preview rendering.
## Cleared and redrawn on each mouse move / tool state change.
## Attached as a child of MapRoot, above other renderers.
##
class_name PreviewOverlay
extends Node2D


# ---------- Configurable ----------
@export var preview_color: Color = Color(0.2, 0.9, 0.4, 0.35)
@export var preview_border_color: Color = Color(0.2, 0.9, 0.4, 0.7)
@export var error_color: Color = Color(0.9, 0.2, 0.2, 0.5)
@export var paste_preview_color: Color = Color(0.4, 0.5, 1.0, 0.4)


# ---------- Internal state ----------
var _commands: Array = []


# ---------- Public API ----------

func clear() -> void:
	_commands.clear()
	queue_redraw()


func draw_preview_cells(cells: Array[Vector2i], color: Color = preview_color, grid_size: Vector2i = Vector2i(32, 32)) -> void:
	_commands.append({ type = "cells", cells = cells.duplicate(), color = color, grid_size = grid_size })
	queue_redraw()


func draw_preview_line(from: Vector2, to: Vector2, color: Color = preview_color, width: float = 2.0) -> void:
	_commands.append({ type = "line", from = from, to = to, color = color, width = width })
	queue_redraw()


func draw_preview_circle(center: Vector2, radius: float, color: Color = preview_color, width: float = 2.0) -> void:
	_commands.append({ type = "circle", center = center, radius = radius, color = color, width = width })
	queue_redraw()


func draw_selection_box(rect: Rect2, color: Color = preview_border_color) -> void:
	_commands.append({ type = "rect", rect = rect, color = color })
	queue_redraw()


func draw_paste_preview(cells: Array[Vector2i], grid_size: Vector2i = Vector2i(32, 32)) -> void:
	_commands.append({ type = "cells", cells = cells.duplicate(), color = paste_preview_color, grid_size = grid_size })
	queue_redraw()


# ---------- Drawing ----------

func _draw() -> void:
	for cmd in _commands:
		match cmd.type:
			"cells":
				_draw_cell_previews(cmd.cells, cmd.color, cmd.grid_size)
			"line":
				draw_line(cmd.from, cmd.to, cmd.color, cmd.width)
			"circle":
				draw_arc(cmd.center, cmd.radius, 0, TAU, 64, cmd.color, cmd.width)
				_draw_dashed_circle(cmd.center, cmd.radius, cmd.color)
			"rect":
				draw_rect(cmd.rect, cmd.color, false, 1.5)


func _draw_cell_previews(cells: Array, color: Color, grid_size: Vector2i) -> void:
	var gs: Vector2 = Vector2(grid_size)
	for cell in cells:
		var pos: Vector2 = Vector2(float(cell.x) * gs.x, float(cell.y) * gs.y)
		var rect: Rect2 = Rect2(pos, gs)
		draw_rect(rect, color, true)
		draw_rect(rect, color * 1.3, false, 1.0)


func _draw_dashed_circle(center: Vector2, radius: float, color: Color) -> void:
	var segments: int = 36
	var dash_count: int = 12
	var arc_per_dash: float = TAU / float(dash_count)
	var dash_arc: float = arc_per_dash * 0.5
	for i in range(dash_count):
		var start_angle: float = float(i) * arc_per_dash
		draw_arc(center, radius, start_angle, start_angle + dash_arc, 8, color, 1.0, false)
