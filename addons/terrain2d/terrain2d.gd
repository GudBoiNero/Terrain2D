extends Polygon2D
# Author: GudBoiNero

# Based On: github.com/arypbatista/godot-bordered-polygon-2d CREATED 

# I wanted to use BorderedPolygon2D by arypbatista for a project of mine in 4.X, 
# but I noticed it was no longer supported. So I figured I should try and remake it myself.

#region EXPORTS
@export_group("Border")
# Thickness of border in pixels
@export() var _border_size = 16 : set = set_border_size, get = get_border_size
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

# Contains children- all Polygon2D- which are frequently deleted and created to render.
@onready var borders: Node2D = null
@onready var fill: Node2D = null

#region METHODS
func prepare_nodes() -> void:
	borders = Node2D.new()
	fill = Node2D.new()

	add_child(borders)
	add_child(fill)

func update_borders() -> void:
	pass

func update_fill() -> void:
	pass
#endregion METHODS

#region NATIVE OVERLOADS
func _enter_tree() -> void:
	pass


func _init() -> void:
	prepare_nodes()


func _draw() -> void:
	update_borders()
	update_fill()


func _ready() -> void:
	pass


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
