extends Polygon2D
# Author: GudBoiNero

# Based On: github.com/arypbatista/godot-bordered-polygon-2d CREATED 

# I wanted to use BorderedPolygon2D by arypbatista for a project of mine in 4.X, 
# but I noticed it was no longer supported. So I figured I should try and remake it myself.

#region EXPORTS
@export_category("Border")
# Thickness of border in pixels
@export() var _border_size = 16 : set = set_border_size, get = get_border_size
# Rotation offset of border textures
@export var _border_rotation: int = 0
# Scale of textures
@export var _border_scale: Vector2 = Vector2(1, 1)
# The material applied to the border
@export var _border_material: ShaderMaterial
# The array of textures useable in the terrain
@export var _textures: Array[Texture] = []
# How many entries does `_border_textures_map` have? If it has 1, then every border will be the assigned texture.
# Each value in `_border_textures_map` represents which texture in `_border_textures` is used at this point. Each time-
# -you add an entry to `_border_textures_map` the polygon gains another angle for the textures to lay on.
@export var _textures_map: Array[int] = []

@export_category("Fill")
# Overridden if `_fill_texture` is set
@export var _fill_color: Color
# Fills in with texture
@export var _fill_texture: Texture
# The material applied to the `_fill_texture`
@export var _fill_material: ShaderMaterial
#endregion EXPORTS

@onready var border: Polygon2D = new()
@onready var fill: Polygon2D = new()

#region METHODS

#endregion METHODS

#region NATIVE OVERLOADS
func _enter_tree() -> void:
	pass

func _init() -> void:
	pass

func _ready() -> void:
	pass

func _process(delta) -> void:
	pass
#endregion

#region POLYGON2D OVERLOADS
#endregion POLYGON2D OVERLOADS

#region SETGETTERS
func set_border_size(border_size: int) -> void: _border_size = border_size;
func get_border_size() -> int: return _border_size;
#endregion SETGETTERS