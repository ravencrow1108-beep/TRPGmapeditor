##
## MapData — Root data resource for a TRPG map.
## Holds metadata, floor list, and cross-floor entities.
##
class_name MapData
extends Resource


# ---------- Grid type enum ----------
enum GridType {
	SQUARE,       ## Square grid (standard)
	HEX_POINTY,   ## Pointy-top hex grid
	HEX_FLAT      ## Flat-top hex grid
}


# ---------- Coordinate system enum ----------
enum CoordSystem {
	OFFSET,       ## Offset coords (row/col)
	AXIAL,        ## Axial coords (q/r)
	CUBE          ## Cube coords (q/r/s)
}


# ---------- Metadata ----------
@export var map_name: String = "未命名地图"
@export var map_version: String = "1.0.0"
@export var author: String = ""
@export var created_date: String = ""
@export var modified_date: String = ""
@export var description: String = ""


# ---------- Map parameters ----------
@export var grid_size: Vector2i = Vector2i(32, 32)
@export var map_dimensions: Vector2i = Vector2i(100, 100)
@export var grid_type: int = GridType.SQUARE
@export var coordinate_system: int = CoordSystem.OFFSET


# ---------- Floor data ----------
@export var floors: Array[FloorData] = []
@export var current_floor: int = 0


# ---------- Global entity arrays ----------
@export var portals: Array[PortalData] = []
@export var light_sources: Array[LightData] = []
@export var fog_of_war: Array[FogData] = []
@export var vision_tokens: Array[VisionTokenData] = []


# ---------- Tileset references ----------
@export var tilesets: Array = []   ## Stub for TilesetReference


## Helper: get the active FloorData, or null when floors is empty.
func get_active_floor() -> FloorData:
	if floors.is_empty() or current_floor < 0 or current_floor >= floors.size():
		return null
	return floors[current_floor]
