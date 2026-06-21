##
## EventBus — Global signal bus autoload
## All subsystem communication flows through this bus.
## Zero logic — only signal definitions.
##
## NOTE: Each signal has a @warning_ignore annotation because signals are
## emitted by other classes (MapEditorController, SerializationManager, etc.)
## — never inside EventBus itself. This is by design.
##
extends Node


# ---------- Map signals ----------
@warning_ignore("unused_signal")
signal map_loaded(map_data)
@warning_ignore("unused_signal")
signal map_saved(file_path)


# ---------- Floor signals ----------
@warning_ignore("unused_signal")
signal floor_changed(old_floor, new_floor)
@warning_ignore("unused_signal")
signal floor_added(floor_index)
@warning_ignore("unused_signal")
signal floor_removed(floor_index)


# ---------- Editing signals ----------
@warning_ignore("unused_signal")
signal tile_placed(cell, tile_data, layer_index)
@warning_ignore("unused_signal")
signal tile_removed(cell, layer_index)
@warning_ignore("unused_signal")
signal object_placed(position, object_type, properties)
@warning_ignore("unused_signal")
signal object_removed(object_id)


# ---------- Portal signals ----------
@warning_ignore("unused_signal")
signal portal_created(portal_data)
@warning_ignore("unused_signal")
signal portal_teleported(portal_id, target_id)


# ---------- Obstacle signals ----------
@warning_ignore("unused_signal")
signal obstacle_placed(obstacle_id, flags)
@warning_ignore("unused_signal")
signal obstacle_updated(obstacle_id, flags)
@warning_ignore("unused_signal")
signal obstacle_removed(obstacle_id)


# ---------- Fog / Visibility signals ----------
@warning_ignore("unused_signal")
signal fog_updated(floor)
@warning_ignore("unused_signal")
signal visibility_changed(token_id, visible_cells)
@warning_ignore("unused_signal")
signal light_source_updated(light_id)


# ---------- Selection signal ----------
@warning_ignore("unused_signal")
signal selection_changed(selected_type, selected_data)
