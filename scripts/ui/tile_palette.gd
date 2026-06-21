##
## TilePalette — Placeholder panel for tile selection.
## Will be replaced with a full tile palette in Phase 1.
##
class_name TilePalette
extends Panel


func _ready() -> void:
	var label = Label.new()
	label.text = "Tile Palette\n(Phase 1+)"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	label.anchors_preset = Control.PRESET_FULL_RECT
	add_child(label)
