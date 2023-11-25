@tool
extends Polygon2D
# Author: GudBoiNero

# Based On: github.com/arypbatista/godot-bordered-polygon-2d CREATED 

# I wanted to use BorderedPolygon2D by arypbatista for a project of mine in 4.X, 
# but I noticed it was no longer supported. So I figured I should try and remake it myself.

#region EXPORTS
@export_group("Border")
# Thickness of border in pixels
@export var _border_size = 16 : set = set_border_size, get = get_border_size
# Rotation offset of border textures
@export var _border_rotation: int = 0 : set = set_border_rotation, get = get_border_rotation
# Scale of textures
@export var _border_scale: Vector2 = Vector2(1, 1) : set = set_border_scale, get = get_border_scale
# The material applied to the border
@export var _border_material: ShaderMaterial
# The array of textures useable in the terrain
@export var _textures: Array[Texture] = [] 
# How many entries does `_border_textures_map` have? If it has 1, then every border will be the assigned texture.
# Each value in `_border_textures_map` represents which texture in `_border_textures` is used at this point. Each time-
# -you add an entry to `_border_textures_map` the polygon gains another angle for the textures to lay on.
@export var _textures_map: Array[int] = []
# Do textures fill in the border or do the textures expand past the border limits
@export var _spread: bool = false;
# How much is each texture spread from each other
@export var _spread_distance: int = 0;

@export_group("Fill")
# Overridden if `_fill_texture` is set
@export var _fill_color: Color
# Fills in with texture
@export var _fill_texture: Texture
# The material applied to the `_fill_texture`
@export var _fill_material: ShaderMaterial
#endregion EXPORTS

#region LOCAL VARS
# Contains children- all Polygon2D- which are frequently deleted and created to render.
@onready var borders: Node2D = null
@onready var fill: Node2D = null

var _is_reloading: bool = false
var _is_clockwise: bool

const BORDERS_NAME = "Borders"
const FILL_NAME = "Fill"
#endregion LOCAL VARS

#region METHODS
#region EVENT FLOW
func update_borders() -> void:
	remove_borders()
	if is_shape(polygon):
		make_borders()


func update_fill() -> void:
	pass
#endregion EVENT FLOW
#region UTIL
func make_borders() -> void:
	var shape_points := polygon
	
	if not is_clockwise_shape(shape_points):
		pass # invert `shape_points`


func remove_borders() -> void:
	for border in borders.get_children():
		borders.remove_child(border)
		border.free()


func prepare_nodes() -> void:
	borders = get_or_create_node(BORDERS_NAME)
	fill = get_or_create_node(FILL_NAME)

	move_child(fill, 0)
	move_child(borders, 1)


func get_or_create_node(name: String) -> Node2D:
	if has_node(name):
		return get_node(name)
	else:
		var node = Node2D.new()
		node.set_name(name)
		add_child(node)
		return node


func remove_child_if_present(name: String) -> void:
	if has_node(name):
		var node = get_node(name)
		remove_child(node)
		node.free()


func cross_product_z(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x
#endregion UTIL
#region CHECKS
func is_shape(_polygon: PackedVector2Array) -> bool:
	return _polygon.size() > 2;


func is_clockwise_shape(_polygon: PackedVector2Array) -> bool:
	var size = _polygon.size()
	if size >= 3:
		var total = 0
		for i in range(size):
			var res = cross_product_z(_polygon[i], _polygon[(i + 1) % size])
			total += res
		return total > 0
	else:
		return false


func is_clockwise():
	if _is_clockwise == null:
		_is_clockwise = is_clockwise_shape(polygon)
	return _is_clockwise


func is_editor_mode() -> bool:
	if get_tree() != null:
		return get_tree().is_editor_hint()
	elif get_tree() == null and get_children().size() > 0:
		return true
	return false
#endregion CHECKS
#endregion METHODS

#region NATIVE OVERLOADS
func _enter_tree() -> void:
	if _is_reloading:
		prepare_nodes()


func _init() -> void:
	if get_children().size() > 0:
		_is_reloading = true


func _draw() -> void:
	update_borders()
	update_fill()


func _ready() -> void:
	prepare_nodes()


func _process(delta) -> void:
	pass
#endregion

#region POLYGON2D OVERLOADS
#endregion POLYGON2D OVERLOADS

#region SETGETTERS
func set_border_size(border_size: int) -> void: 
	_border_size = border_size;


func get_border_size() -> int: 
	return _border_size;


func set_border_rotation(border_rotation: int) -> void: 
	_border_rotation = border_rotation;


func get_border_rotation() -> int: 
	return _border_rotation;


func set_border_scale(border_scale: Vector2) -> void:
	_border_scale = border_scale;


func get_border_scale() -> Vector2: 
	return _border_scale;
#endregion SETGETTERS
