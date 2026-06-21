##
## FloorData — Data for one floor level of a map.
## Each floor owns terrain layers, objects, walls, portals, lights, and fog.
##
class_name FloorData
extends Resource


# ---------- Base info ----------
@export var floor_index: int = 0
@export var floor_name: String = "地面层"
@export var floor_z: int = 0
@export var elevation: float = 0.0


# ---------- Floor properties ----------
@export var visible: bool = true
@export var locked: bool = false
@export var opacity: float = 1.0
@export var tint_color: Color = Color.WHITE


# ---------- Terrain layers ----------
@export var terrain_layers: Array[TerrainLayerData] = []


# ---------- Objects ----------
@export var objects: Array[MapObjectData] = []


# ---------- Walls / Obstacles ----------
@export var walls: Array[WallSegmentData] = []


# ---------- Floor-scoped portals ----------
@export var floor_portals: Array[PortalData] = []


# ---------- Floor-scoped lights ----------
@export var floor_lights: Array[LightData] = []


# ---------- Fog of war ----------
@export var fog_data: FogData = FogData.new()
