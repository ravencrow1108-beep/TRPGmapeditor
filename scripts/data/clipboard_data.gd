##
## ClipboardData — Payload for clipboard copy/paste operations.
## Holds tiles (relative coords), objects, and walls with adjusted positions.
##
class_name ClipboardData
extends RefCounted


## Relative-position tiles: {Vector2i: tile_data_Dictionary}
var tiles: Dictionary = {}

## Objects with positions relative to the copy origin.
var objects: Array[MapObjectData] = []

## Walls with endpoints relative to the copy origin.
var walls: Array[WallSegmentData] = []

## Bounding rectangle of the copied region (in source grid coords).
var source_bounds: Rect2i = Rect2i()
