##
## TerrainLayerData — One terrain layer within a floor.
## Tiles are stored as a Dictionary keyed by grid cell (Vector2i).
##
class_name TerrainLayerData
extends Resource


@export var layer_name: String = "图层"
@export var layer_index: int = 0
@export var visible: bool = true
@export var locked: bool = false
@export var opacity: float = 1.0
@export var tileset_ref: String = ""   ## Tileset resource ID (stub)


## Pre-computed chunk index for Phase 6 optimization.
## Set to -1 to indicate "not assigned" (default).
@export var chunk_index: int = -1


## Tile storage — {Vector2i: {id: int, ...}}
## Value is a Dictionary so tile metadata can grow in later phases.
@export var tiles: Dictionary = {}
