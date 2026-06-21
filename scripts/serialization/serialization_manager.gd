##
## SerializationManager — Save and load MapData to/from .trpgmap JSON files.
## Phase 0: static utility methods. Promoted to Node-based manager in Phase 5.
##
class_name SerializationManager
extends RefCounted


const FORMAT_VERSION = "1.0"
const FORMAT_TYPE = "trpgmap"


# ---------------------------------------------------------------------------
# Public static API
# ---------------------------------------------------------------------------

static func save_map(map_data: MapData, file_path: String) -> bool:
	if map_data == null:
		push_error("[SerializationManager] Cannot save null MapData")
		return false

	var root = _serialize_map_data(map_data)

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("[SerializationManager] Cannot open file for writing: %s" % file_path)
		return false

	file.store_string(JSON.stringify(root, "\t"))
	file.close()

	EventBus.map_saved.emit(file_path)
	print("[SerializationManager] Map saved to: %s" % file_path)
	return true


static func load_map(file_path: String) -> MapData:
	if not FileAccess.file_exists(file_path):
		push_error("[SerializationManager] File not found: %s" % file_path)
		return null

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[SerializationManager] Cannot open file for reading: %s" % file_path)
		return null

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(text)
	if error != OK:
		push_error("[SerializationManager] JSON parse error: %s" % json.get_error_message())
		return null

	var root = json.get_data()
	if not root is Dictionary:
		push_error("[SerializationManager] Invalid map file: root is not a Dictionary")
		return null

	var map_data = _deserialize_map_data(root)
	if map_data:
		EventBus.map_loaded.emit(map_data)
	return map_data


# ---------------------------------------------------------------------------
# Serialize helpers
# ---------------------------------------------------------------------------

static func _serialize_map_data(md: MapData) -> Dictionary:
	var dict = {}
	dict["format_version"] = FORMAT_VERSION
	dict["format_type"] = FORMAT_TYPE
	dict["metadata"] = _serialize_metadata(md)
	dict["floors"] = _serialize_floors(md.floors)
	dict["portals"] = _serialize_portals(md.portals)
	dict["light_sources"] = _serialize_lights(md.light_sources)
	dict["vision_tokens"] = _serialize_vision_tokens(md.vision_tokens)
	return dict


static func _serialize_metadata(md: MapData) -> Dictionary:
	var d = {}
	d["map_name"] = md.map_name
	d["map_version"] = md.map_version
	d["author"] = md.author
	d["created_date"] = md.created_date
	d["modified_date"] = md.modified_date
	d["description"] = md.description
	d["grid_type"] = md.grid_type
	d["grid_size"] = [md.grid_size.x, md.grid_size.y]
	d["map_dimensions"] = [md.map_dimensions.x, md.map_dimensions.y]
	return d


static func _serialize_floors(floors: Array) -> Array:
	var result = []
	for floor in floors:
		result.append(_serialize_floor_data(floor))
	return result


static func _serialize_floor_data(fd: FloorData) -> Dictionary:
	var layers = []
	for layer in fd.terrain_layers:
		layers.append(_serialize_terrain_layer(layer))

	var objects = []
	for obj in fd.objects:
		objects.append(_serialize_map_object(obj))

	var walls = []
	for wall in fd.walls:
		walls.append(_serialize_wall_segment(wall))

	var d = {}
	d["floor_index"] = fd.floor_index
	d["floor_name"] = fd.floor_name
	d["floor_z"] = fd.floor_z
	d["elevation"] = fd.elevation
	d["visible"] = fd.visible
	d["locked"] = fd.locked
	d["opacity"] = fd.opacity
	d["tint_color"] = _color_to_dict(fd.tint_color)
	d["terrain_layers"] = layers
	d["objects"] = objects
	d["walls"] = walls
	d["fog_data"] = _serialize_fog_data(fd.fog_data)
	return d


static func _serialize_terrain_layer(tl: TerrainLayerData) -> Dictionary:
	var d = {}
	d["layer_name"] = tl.layer_name
	d["layer_index"] = tl.layer_index
	d["visible"] = tl.visible
	d["locked"] = tl.locked
	d["opacity"] = tl.opacity
	d["tileset_ref"] = tl.tileset_ref
	d["tiles"] = _tiles_to_string_keys(tl.tiles)
	return d


static func _serialize_map_object(obj: MapObjectData) -> Dictionary:
	var d = {}
	d["object_id"] = obj.object_id
	d["object_type"] = obj.object_type
	d["display_name"] = obj.display_name
	d["position"] = [obj.position.x, obj.position.y]
	d["grid_position"] = [obj.grid_position.x, obj.grid_position.y]
	d["rotation"] = obj.rotation
	d["scale"] = [obj.scale.x, obj.scale.y]
	d["sprite_path"] = obj.sprite_path
	d["z_index"] = obj.z_index
	d["collision_shape"] = obj.collision_shape
	d["custom_properties"] = obj.custom_properties
	return d


static func _serialize_wall_segment(wall: WallSegmentData) -> Dictionary:
	var d = {}
	d["segment_id"] = wall.segment_id
	d["start_point"] = [wall.start_point.x, wall.start_point.y]
	d["end_point"] = [wall.end_point.x, wall.end_point.y]
	d["wall_type"] = wall.wall_type
	d["height"] = wall.height
	d["thickness"] = wall.thickness
	d["block_flags"] = wall.block_flags
	return d


static func _serialize_fog_data(fog: FogData) -> Dictionary:
	if fog == null:
		return {}
	var d = {}
	d["enabled"] = fog.enabled
	d["fog_type"] = fog.fog_type
	d["fog_color"] = _color_to_dict(fog.fog_color)
	d["unexplored_color"] = _color_to_dict(fog.unexplored_color)
	d["explored_color"] = _color_to_dict(fog.explored_color)
	d["fog_transition_speed"] = fog.fog_transition_speed
	d["fog_grid"] = _tiles_to_string_keys(fog.fog_grid)
	return d


static func _serialize_portals(portals: Array) -> Array:
	var result = []
	for portal in portals:
		var d = {}
		d["portal_id"] = portal.portal_id
		d["portal_name"] = portal.portal_name
		d["source_floor"] = portal.source_floor
		d["source_position"] = [portal.source_position.x, portal.source_position.y]
		d["source_size"] = [portal.source_size.x, portal.source_size.y]
		d["target_floor"] = portal.target_floor
		d["target_position"] = [portal.target_position.x, portal.target_position.y]
		d["target_map"] = portal.target_map
		d["is_bidirectional"] = portal.is_bidirectional
		d["is_active"] = portal.is_active
		d["visual_color"] = _color_to_dict(portal.visual_color)
		d["label_visible"] = portal.label_visible
		d["label_text"] = portal.label_text
		d["trigger_type"] = portal.trigger_type
		result.append(d)
	return result


static func _serialize_lights(lights: Array) -> Array:
	var result = []
	for light in lights:
		var d = {}
		d["light_id"] = light.light_id
		d["light_name"] = light.light_name
		d["floor_index"] = light.floor_index
		d["position"] = [light.position.x, light.position.y]
		d["grid_position"] = [light.grid_position.x, light.grid_position.y]
		d["light_type"] = light.light_type
		d["intensity"] = light.intensity
		d["color"] = _color_to_dict(light.color)
		d["radius"] = light.radius
		d["falloff"] = light.falloff
		d["inner_angle"] = light.inner_angle
		d["outer_angle"] = light.outer_angle
		d["rotation"] = light.rotation
		d["is_static"] = light.is_static
		d["is_dynamic"] = light.is_dynamic
		d["flicker_enabled"] = light.flicker_enabled
		d["flicker_speed"] = light.flicker_speed
		d["flicker_amount"] = light.flicker_amount
		result.append(d)
	return result


static func _serialize_vision_tokens(tokens: Array) -> Array:
	var result = []
	for token in tokens:
		var d = {}
		d["token_id"] = token.token_id
		d["token_name"] = token.token_name
		d["floor_index"] = token.floor_index
		d["position"] = [token.position.x, token.position.y]
		d["grid_position"] = [token.grid_position.x, token.grid_position.y]
		d["vision_range"] = token.vision_range
		d["vision_arc"] = token.vision_arc
		d["facing_angle"] = token.facing_angle
		d["darkvision_range"] = token.darkvision_range
		d["low_light_multiplier"] = token.low_light_multiplier
		d["vision_height"] = token.vision_height
		d["can_see_invisible"] = token.can_see_invisible
		d["is_player_controlled"] = token.is_player_controlled
		d["owner_player_id"] = token.owner_player_id
		result.append(d)
	return result


# ---------------------------------------------------------------------------
# Deserialize helpers
# ---------------------------------------------------------------------------

static func _deserialize_map_data(dict: Dictionary) -> MapData:
	var md = MapData.new()

	var meta = dict.get("metadata", {})
	if meta is Dictionary:
		md.map_name = _get_str(meta, "map_name", md.map_name)
		md.map_version = _get_str(meta, "map_version", md.map_version)
		md.author = _get_str(meta, "author", md.author)
		md.created_date = _get_str(meta, "created_date", md.created_date)
		md.modified_date = _get_str(meta, "modified_date", md.modified_date)
		md.description = _get_str(meta, "description", md.description)
		md.grid_type = _get_int(meta, "grid_type", md.grid_type)
		md.grid_size = _array_to_vector2i(meta.get("grid_size", [32, 32]))
		md.map_dimensions = _array_to_vector2i(meta.get("map_dimensions", [100, 100]))

	var floors_data = dict.get("floors", [])
	for fd_dict in floors_data:
		if fd_dict is Dictionary:
			md.floors.append(_deserialize_floor_data(fd_dict))

	if not md.floors.is_empty():
		md.current_floor = 0

	var portals_data = dict.get("portals", [])
	for p_dict in portals_data:
		if p_dict is Dictionary:
			md.portals.append(_deserialize_portal(p_dict))

	var lights_data = dict.get("light_sources", [])
	for l_dict in lights_data:
		if l_dict is Dictionary:
			md.light_sources.append(_deserialize_light(l_dict))

	var tokens_data = dict.get("vision_tokens", [])
	for t_dict in tokens_data:
		if t_dict is Dictionary:
			md.vision_tokens.append(_deserialize_vision_token(t_dict))

	return md


static func _deserialize_floor_data(dict: Dictionary) -> FloorData:
	var fd = FloorData.new()
	fd.floor_index = _get_int(dict, "floor_index", 0)
	fd.floor_name = _get_str(dict, "floor_name", fd.floor_name)
	fd.floor_z = _get_int(dict, "floor_z", 0)
	fd.elevation = _get_float(dict, "elevation", 0.0)
	fd.visible = _get_bool(dict, "visible", true)
	fd.locked = _get_bool(dict, "locked", false)
	fd.opacity = _get_float(dict, "opacity", 1.0)
	fd.tint_color = _dict_to_color(dict.get("tint_color", {}))

	var layers = dict.get("terrain_layers", [])
	for tl_dict in layers:
		if tl_dict is Dictionary:
			fd.terrain_layers.append(_deserialize_terrain_layer(tl_dict))

	var objects = dict.get("objects", [])
	for obj_dict in objects:
		if obj_dict is Dictionary:
			fd.objects.append(_deserialize_map_object(obj_dict))

	var walls = dict.get("walls", [])
	for wall_dict in walls:
		if wall_dict is Dictionary:
			fd.walls.append(_deserialize_wall_segment(wall_dict))

	var fog_dict = dict.get("fog_data", {})
	if not fog_dict.is_empty():
		fd.fog_data = _deserialize_fog_data(fog_dict)

	return fd


static func _deserialize_terrain_layer(dict: Dictionary) -> TerrainLayerData:
	var tl = TerrainLayerData.new()
	tl.layer_name = _get_str(dict, "layer_name", tl.layer_name)
	tl.layer_index = _get_int(dict, "layer_index", 0)
	tl.visible = _get_bool(dict, "visible", true)
	tl.locked = _get_bool(dict, "locked", false)
	tl.opacity = _get_float(dict, "opacity", 1.0)
	tl.tileset_ref = _get_str(dict, "tileset_ref", "")
	tl.tiles = _tiles_from_string_keys(dict.get("tiles", {}))
	return tl


static func _deserialize_map_object(dict: Dictionary) -> MapObjectData:
	var obj = MapObjectData.new()
	obj.object_id = _get_str(dict, "object_id", "")
	obj.object_type = _get_str(dict, "object_type", "")
	obj.display_name = _get_str(dict, "display_name", "")
	obj.position = _array_to_vector2(dict.get("position", [0.0, 0.0]))
	obj.grid_position = _array_to_vector2i(dict.get("grid_position", [0, 0]))
	obj.rotation = _get_float(dict, "rotation", 0.0)
	obj.scale = _array_to_vector2(dict.get("scale", [1.0, 1.0]))
	obj.sprite_path = _get_str(dict, "sprite_path", "")
	obj.z_index = _get_int(dict, "z_index", 0)
	obj.collision_shape = _get_int(dict, "collision_shape", MapObjectData.CollisionShape.RECTANGLE)
	obj.custom_properties = dict.get("custom_properties", {})
	return obj


static func _deserialize_wall_segment(dict: Dictionary) -> WallSegmentData:
	var wall = WallSegmentData.new()
	wall.segment_id = _get_str(dict, "segment_id", "")
	wall.start_point = _array_to_vector2(dict.get("start_point", [0.0, 0.0]))
	wall.end_point = _array_to_vector2(dict.get("end_point", [0.0, 0.0]))
	wall.wall_type = _get_int(dict, "wall_type", WallSegmentData.WallType.SOLID)
	wall.height = _get_float(dict, "height", 2.0)
	wall.thickness = _get_float(dict, "thickness", 0.3)
	wall.block_flags = _get_int(dict, "block_flags", wall.block_flags)
	return wall


static func _deserialize_fog_data(dict: Dictionary) -> FogData:
	var fog = FogData.new()
	fog.enabled = _get_bool(dict, "enabled", true)
	fog.fog_type = _get_int(dict, "fog_type", FogData.FogType.NONE)
	fog.fog_color = _dict_to_color(dict.get("fog_color", {}))
	fog.unexplored_color = _dict_to_color(dict.get("unexplored_color", {}))
	fog.explored_color = _dict_to_color(dict.get("explored_color", {}))
	fog.fog_transition_speed = _get_float(dict, "fog_transition_speed", 0.5)
	fog.fog_grid = _tiles_from_string_keys(dict.get("fog_grid", {}))
	return fog


static func _deserialize_portal(dict: Dictionary) -> PortalData:
	var portal = PortalData.new()
	portal.portal_id = _get_str(dict, "portal_id", "")
	portal.portal_name = _get_str(dict, "portal_name", "")
	portal.source_floor = _get_int(dict, "source_floor", 0)
	portal.source_position = _array_to_vector2i(dict.get("source_position", [0, 0]))
	portal.source_size = _array_to_vector2i(dict.get("source_size", [1, 1]))
	portal.target_floor = _get_int(dict, "target_floor", 0)
	portal.target_position = _array_to_vector2i(dict.get("target_position", [0, 0]))
	portal.target_map = _get_str(dict, "target_map", "")
	portal.is_bidirectional = _get_bool(dict, "is_bidirectional", true)
	portal.is_active = _get_bool(dict, "is_active", true)
	portal.visual_color = _dict_to_color(dict.get("visual_color", {}))
	portal.label_visible = _get_bool(dict, "label_visible", true)
	portal.label_text = _get_str(dict, "label_text", "")
	portal.trigger_type = _get_int(dict, "trigger_type", PortalData.TriggerType.WALK_ON)
	return portal


static func _deserialize_light(dict: Dictionary) -> LightData:
	var light = LightData.new()
	light.light_id = _get_str(dict, "light_id", "")
	light.light_name = _get_str(dict, "light_name", "")
	light.floor_index = _get_int(dict, "floor_index", 0)
	light.position = _array_to_vector2(dict.get("position", [0.0, 0.0]))
	light.grid_position = _array_to_vector2i(dict.get("grid_position", [0, 0]))
	light.light_type = _get_int(dict, "light_type", LightData.LightType.POINT)
	light.intensity = _get_float(dict, "intensity", 1.0)
	light.color = _dict_to_color(dict.get("color", {}))
	light.radius = _get_float(dict, "radius", 5.0)
	light.falloff = _get_float(dict, "falloff", 0.5)
	light.inner_angle = _get_float(dict, "inner_angle", 30.0)
	light.outer_angle = _get_float(dict, "outer_angle", 60.0)
	light.rotation = _get_float(dict, "rotation", 0.0)
	light.is_static = _get_bool(dict, "is_static", true)
	light.is_dynamic = _get_bool(dict, "is_dynamic", false)
	light.flicker_enabled = _get_bool(dict, "flicker_enabled", false)
	light.flicker_speed = _get_float(dict, "flicker_speed", 3.0)
	light.flicker_amount = _get_float(dict, "flicker_amount", 0.15)
	return light


static func _deserialize_vision_token(dict: Dictionary) -> VisionTokenData:
	var token = VisionTokenData.new()
	token.token_id = _get_str(dict, "token_id", "")
	token.token_name = _get_str(dict, "token_name", "")
	token.floor_index = _get_int(dict, "floor_index", 0)
	token.position = _array_to_vector2(dict.get("position", [0.0, 0.0]))
	token.grid_position = _array_to_vector2i(dict.get("grid_position", [0, 0]))
	token.vision_range = _get_int(dict, "vision_range", 8)
	token.vision_arc = _get_float(dict, "vision_arc", 360.0)
	token.facing_angle = _get_float(dict, "facing_angle", 0.0)
	token.darkvision_range = _get_int(dict, "darkvision_range", 0)
	token.low_light_multiplier = _get_float(dict, "low_light_multiplier", 1.0)
	token.vision_height = _get_float(dict, "vision_height", 1.5)
	token.can_see_invisible = _get_bool(dict, "can_see_invisible", false)
	token.is_player_controlled = _get_bool(dict, "is_player_controlled", false)
	token.owner_player_id = _get_str(dict, "owner_player_id", "")
	return token


# ---------------------------------------------------------------------------
# Utility: Vector2i Dictionary key conversion
# ---------------------------------------------------------------------------

static func _tiles_to_string_keys(d: Dictionary) -> Dictionary:
	var result = {}
	for key in d.keys():
		if key is Vector2i:
			result["%d,%d" % [key.x, key.y]] = d[key]
		else:
			result[key] = d[key]
	return result


static func _tiles_from_string_keys(d: Dictionary) -> Dictionary:
	var result = {}
	for key in d.keys():
		if key is String and "," in key:
			var parts = key.split(",")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
				result[Vector2i(parts[0].to_int(), parts[1].to_int())] = d[key]
				continue
		result[key] = d[key]
	return result


# ---------------------------------------------------------------------------
# Utility: Color ⇄ Dictionary
# ---------------------------------------------------------------------------

static func _color_to_dict(c: Color) -> Dictionary:
	var d = {}
	d["r"] = c.r
	d["g"] = c.g
	d["b"] = c.b
	d["a"] = c.a
	return d


static func _dict_to_color(d: Dictionary) -> Color:
	if d.is_empty():
		return Color.WHITE
	return Color(
		float(d.get("r", 1.0)),
		float(d.get("g", 1.0)),
		float(d.get("b", 1.0)),
		float(d.get("a", 1.0))
	)


# ---------------------------------------------------------------------------
# Utility: Vector ⇄ Array
# ---------------------------------------------------------------------------

static func _array_to_vector2(a: Array) -> Vector2:
	if a.size() < 2:
		return Vector2.ZERO
	return Vector2(float(a[0]), float(a[1]))


static func _array_to_vector2i(a: Array) -> Vector2i:
	if a.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(a[0]), int(a[1]))


# ---------------------------------------------------------------------------
# Utility: Safe typed getters from Dictionary
# ---------------------------------------------------------------------------

static func _get_str(d: Dictionary, key: String, default: String) -> String:
	var v = d.get(key, default)
	if v is String:
		return v
	return default


static func _get_int(d: Dictionary, key: String, default: int) -> int:
	var v = d.get(key, default)
	if v is int:
		return v
	if v is float:
		return int(v)
	return default


static func _get_float(d: Dictionary, key: String, default: float) -> float:
	var v = d.get(key, default)
	if v is float:
		return v
	if v is int:
		return float(v)
	return default


static func _get_bool(d: Dictionary, key: String, default: bool) -> bool:
	var v = d.get(key, default)
	if v is bool:
		return v
	return default
