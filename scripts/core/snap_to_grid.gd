##
## SnapToGrid — Configurable snap-to-grid utility.
## Reads/writes snap settings to ConfigManager.
## Shift key temporarily disables snapping.
##
class_name SnapToGrid
extends RefCounted


var enabled: bool = true
var mode: int = GridUtils.SnapMode.CELL_CENTER


func set_from_config() -> void:
	enabled = ConfigManager.get_value("snap_enabled", true)
	mode = ConfigManager.get_value("snap_mode", GridUtils.SnapMode.CELL_CENTER)


func save_to_config() -> void:
	ConfigManager.set_value("snap_enabled", enabled)
	ConfigManager.set_value("snap_mode", mode)
	ConfigManager.save_config()


func snap(world_pos: Vector2, grid_size: Vector2i) -> Vector2:
	if not enabled or Input.is_key_pressed(KEY_SHIFT):
		return world_pos
	return GridUtils.snap_to_grid(world_pos, grid_size, mode)


func snap_cell(world_pos: Vector2, grid_size: Vector2i) -> Vector2i:
	var snapped: Vector2 = snap(world_pos, grid_size)
	return GridUtils.world_to_grid(snapped, grid_size)


func is_snap_active() -> bool:
	return enabled and not Input.is_key_pressed(KEY_SHIFT)
