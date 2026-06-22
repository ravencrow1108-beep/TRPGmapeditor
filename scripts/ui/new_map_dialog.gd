##
## NewMapDialog — Dialog for creating a new map with configurable parameters.
## VBox form: name, author, description, grid type, grid size, dimensions, initial floor.
##
class_name NewMapDialog
extends AcceptDialog


signal map_created(map_data: MapData)


var _name_edit: LineEdit = null
var _author_edit: LineEdit = null
var _desc_edit: TextEdit = null
var _grid_type_option: OptionButton = null
var _grid_size_x: SpinBox = null
var _grid_size_y: SpinBox = null
var _map_width: SpinBox = null
var _map_height: SpinBox = null
var _floor_name_edit: LineEdit = null


func _ready() -> void:
	title = "新建地图"
	ok_button_text = "创建"
	_setup_form()
	confirmed.connect(_on_create)


func _setup_form() -> void:
	var form = VBoxContainer.new()

	var name_row = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = "地图名称:"
	name_label.custom_minimum_size = Vector2(80, 0)
	name_row.add_child(name_label)
	_name_edit = LineEdit.new()
	_name_edit.text = "新建地图"
	_name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	name_row.add_child(_name_edit)
	form.add_child(name_row)

	var auth_row = HBoxContainer.new()
	var auth_label = Label.new()
	auth_label.text = "作者:"
	auth_label.custom_minimum_size = Vector2(80, 0)
	auth_row.add_child(auth_label)
	_author_edit = LineEdit.new()
	_author_edit.placeholder_text = "你的名字"
	_author_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	auth_row.add_child(_author_edit)
	form.add_child(auth_row)

	var desc_label = Label.new()
	desc_label.text = "描述:"
	form.add_child(desc_label)
	_desc_edit = TextEdit.new()
	_desc_edit.custom_minimum_size = Vector2(0, 60)
	_desc_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	form.add_child(_desc_edit)

	var gtype_row = HBoxContainer.new()
	var gtype_label = Label.new()
	gtype_label.text = "网格类型:"
	gtype_label.custom_minimum_size = Vector2(80, 0)
	gtype_row.add_child(gtype_label)
	_grid_type_option = OptionButton.new()
	_grid_type_option.add_item("方形网格")
	_grid_type_option.add_item("六边形 (尖顶)")
	_grid_type_option.add_item("六边形 (平顶)")
	_grid_type_option.size_flags_horizontal = SIZE_EXPAND_FILL
	gtype_row.add_child(_grid_type_option)
	form.add_child(gtype_row)

	var gs_row = HBoxContainer.new()
	var gs_label = Label.new()
	gs_label.text = "网格大小:"
	gs_label.custom_minimum_size = Vector2(80, 0)
	gs_row.add_child(gs_label)
	_grid_size_x = SpinBox.new()
	_grid_size_x.min_value = 8
	_grid_size_x.max_value = 128
	_grid_size_x.value = 32
	_grid_size_x.suffix = "px"
	gs_row.add_child(_grid_size_x)
	var gsx = Label.new()
	gsx.text = " x "
	gs_row.add_child(gsx)
	_grid_size_y = SpinBox.new()
	_grid_size_y.min_value = 8
	_grid_size_y.max_value = 128
	_grid_size_y.value = 32
	_grid_size_y.suffix = "px"
	gs_row.add_child(_grid_size_y)
	form.add_child(gs_row)

	var dim_row = HBoxContainer.new()
	var dim_label = Label.new()
	dim_label.text = "地图尺寸:"
	dim_label.custom_minimum_size = Vector2(80, 0)
	dim_row.add_child(dim_label)
	_map_width = SpinBox.new()
	_map_width.min_value = 10
	_map_width.max_value = 500
	_map_width.value = 100
	_map_width.suffix = " 格宽"
	dim_row.add_child(_map_width)
	dim_row.add_child(Label.new())
	_map_height = SpinBox.new()
	_map_height.min_value = 10
	_map_height.max_value = 500
	_map_height.value = 100
	_map_height.suffix = " 格高"
	dim_row.add_child(_map_height)
	form.add_child(dim_row)

	var floor_row = HBoxContainer.new()
	var flabel = Label.new()
	flabel.text = "初始楼层:"
	flabel.custom_minimum_size = Vector2(80, 0)
	floor_row.add_child(flabel)
	_floor_name_edit = LineEdit.new()
	_floor_name_edit.text = "地面层"
	_floor_name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	floor_row.add_child(_floor_name_edit)
	form.add_child(floor_row)

	add_child(form)


func get_form_values() -> Dictionary:
	return {
		map_name = _name_edit.text,
		author = _author_edit.text,
		description = _desc_edit.text,
		grid_type = _grid_type_option.selected,
		grid_size = Vector2i(int(_grid_size_x.value), int(_grid_size_y.value)),
		map_dimensions = Vector2i(int(_map_width.value), int(_map_height.value)),
		floor_name = _floor_name_edit.text
	}


func _on_create() -> void:
	var values = get_form_values()
	var md = MapData.new()
	md.map_name = values.map_name
	md.author = values.author
	md.description = values.description
	md.grid_type = values.grid_type
	md.grid_size = values.grid_size
	md.map_dimensions = values.map_dimensions
	md.created_date = _iso_date_now()
	md.modified_date = md.created_date

	var fd = FloorData.new()
	fd.floor_index = 0
	fd.floor_name = values.floor_name
	fd.floor_z = 0

	var layer = TerrainLayerData.new()
	layer.layer_index = 0
	layer.layer_name = "图层 1"
	fd.terrain_layers.append(layer)

	md.floors.append(fd)
	md.current_floor = 0

	map_created.emit(md)


func _iso_date_now() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02dT%02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
