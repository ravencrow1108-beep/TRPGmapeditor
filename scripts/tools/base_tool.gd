##
## BaseTool — Abstract base class for all editing tools.
## Tools are RefCounted (not Node) — managed by ToolManager.
## Virtual methods are called by ToolManager when the tool is active.
##
class_name BaseTool
extends RefCounted


var tool_name: String = ""
var is_active: bool = false


func on_activate() -> void:
	pass


func on_deactivate() -> void:
	pass


func on_mouse_pressed(world_pos: Vector2, button: int) -> void:
	pass


func on_mouse_moved(world_pos: Vector2) -> void:
	pass


func on_mouse_released(world_pos: Vector2, button: int) -> void:
	pass


func on_key_pressed(event: InputEventKey) -> void:
	pass


func on_draw_overlay(canvas: Node2D) -> void:
	pass
