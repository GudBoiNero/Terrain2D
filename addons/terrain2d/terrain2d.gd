@tool
extends Polygon2D
# Author: GudBoiNero

# Credit to: github.com/arypbatista/godot-bordered-polygon-2d
# Most code is derived from here. 

# I wanted to use BorderedPolygon2D by arypbatista for a project of mine in 4.X, 
# but I noticed it was no longer supported. So I figured I should try and remake it myself.

#region EXPORTS
@export_group("Border")
# Thickness of border in pixels
@export var _border_size = 16 : set = set_border_size, get = get_border_size
# Rotation offset of border textures
@export var _border_rotation: int = 0 : set = set_border_rotation, get = get_border_rotation
# Smooth level of borders
@export_range(0.0, 1.0, 0.001) var _border_smooth: float = 0 : set = set_border_smooth, get = get_border_smooth
# Max level smoothed borders
@export_range(0.0, 179, 1) var _border_smooth_max_angle: float = 90 : set = set_border_smooth_max_angle, get = get_border_smooth_max_angle
# How much the outer border overlaps with the inner polygon
@export var _border_overlap: float = 0 : set = set_border_overlap, get = get_border_overlap
# Scale of textures
@export var _border_texture_scale: Vector2 = Vector2(1, 1) : set = set_border_texture_scale, get = get_border_texture_scale
# Offset of textures
@export var _border_texture_offset: Vector2 = Vector2(0, 0) : set = set_border_texture_offset, get = get_border_texture_offset
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
@onready var inner_polygon: Polygon2D = null

var _is_reloading: bool = false
var _is_clockwise: bool

const BORDERS_NAME := "Borders"
const FILL_NAME := "Fill"

const QUAD_TOP_1    := 1
const QUAD_TOP_2    := 0
const QUAD_BOTTOM_1 := 3
const QUAD_BOTTOM_2 := 2

const SMOOTH_MAX_PASSES := 5
const SMOOTH_MIN_ANGLE := PI*0.08
const SMOOTH_MIN_ANGLE_GAIN := PI*0.08
const SMOOTH_MAX_NODES_PER_FACE := 10
#endregion LOCAL VARS

#region METHODS
#region EVENT FLOW
func update_borders() -> void:
	remove_borders()
	if is_shape(polygon):
		make_border(_border_size)


func update_fill() -> void:
	pass
#endregion EVENT FLOW
#region UTIL
func make_border(border_size):
	var shape_points = get_polygon()

	if not is_clockwise_shape(shape_points):
		shape_points.invert()

	if _border_smooth > 0:
		shape_points = smooth_shape_points(shape_points, _border_smooth_max_angle)

	set_inner_polygon(expand_or_contract_shape_points(shape_points, _border_overlap))
	var border_points = calculate_border_points(shape_points, _border_size, _border_overlap)

	# Turn points to quads
	var lastborder_texture_offset = 0
	var border_points_count = border_points.size()
	# var sample_width = get_texture_sample().get_size().x # FIXME: test code?

	for i in range(border_points_count/2 - 1):
		var quad = calculate_quad(i, border_points, border_points_count)
		var width = quad[QUAD_BOTTOM_1].distance_to(quad[QUAD_BOTTOM_2])
		var border = create_border(border_size, quad, Vector2(lastborder_texture_offset + _border_texture_offset.x, _border_texture_offset.y))
		lastborder_texture_offset = -width + lastborder_texture_offset
		borders.add_child(border)

# TODO: Refactor, Document, & Customize to Needs
func create_border(border_size, quad, offset=Vector2(0,0)):
	var border = Polygon2D.new()
	border.set_name('Border')
	var border_angle = quad_angle(quad)

	var n = (quad[1] - quad[0]).normalized()
	var phi = Vector2(-1,0).angle_to(n)

	var top_width = quad[0].distance_to(quad[1])
	var bottom_width = quad[2].distance_to(quad[3])

	var bottom_x = (quad[0] - quad[3]).rotated(-phi).x

	border.set_uv([Vector2(0, 0) + offset,
		Vector2(0 + top_width, 0) + offset,
		Vector2(bottom_x + bottom_width, border_size) + offset,
		Vector2(bottom_x, border_size) + offset])

	border.set_polygon(quad)

	# Prepare textures only if they're set
	var tex: Texture = null
	if _textures.size() > 0:
		tex = get_tex_from_angle(_textures, border_angle)
		
		border.texture = tex
		border.texture_rotation = deg_to_rad(_border_rotation)
		border.texture_offset = _border_texture_offset
		border.texture_scale = _border_texture_scale
		border.material = _border_material
#### Ref Code
#	var tex_idx = 0
#	if has_border_textures():
#		if border_textures != null:
#			tex_idx = texture_idx_from_angle(border_textures, border_angle)
#		var tex = get_border_texture(tex_idx)
#		tex.set_flags(tex.get_flags() | Texture.FLAG_REPEAT)
#		border.set_texture(tex)
#
#		var texture_rotation = deg2rad(border_texture_rotation) + PI
#		border.set_texture_rotation(texture_rotation)
#		border.set_texture_scale(invert_scale(border_texture_scale))
#
#	border.set_material(get_border_material(tex_idx))
	return border


func remove_borders() -> void:
	for border in borders.get_children():
		borders.remove_child(border)
		border.free()


func prepare_nodes() -> void:
	borders = get_or_create_node(BORDERS_NAME)
	fill = get_or_create_node(FILL_NAME)

	move_child(fill, 0)
	move_child(borders, 1)


func get_tex_from_angle(_textures: Array[Texture], _angle: float) -> Texture:
	return _textures[0]


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

# TODO: Refactor & Document
func create_inner_polygon():
	var p = Polygon2D.new()
	p.set_name('Fill')
	p.set_texture(get_texture())
	p.set_texture_scale(get_texture_scale())
	p.set_texture_rotation(get_texture_rotation())
	p.set_texture_offset(get_texture_offset())
	p.set_uv(get_uv())
	p.modulate.a = modulate.a
	p.set_vertex_colors(get_vertex_colors())
	p.set_material(get_material())
	set_inner_polygon_node(p)

# TODO: Refactor & Document
func set_inner_polygon_node(polygon: Polygon2D):
	if inner_polygon != null:
		inner_polygon.free()
		inner_polygon = null
	inner_polygon = polygon
	fill.add_child(inner_polygon)

# TODO: Refactor & Document
func set_inner_polygon(polygon):
	if typeof(polygon) == TYPE_PACKED_VECTOR2_ARRAY:
		create_inner_polygon()
		inner_polygon.set_polygon(polygon)
	else: # polygon is Polygon2D node
		set_inner_polygon_node(polygon)

# TODO: Refactor & Document
func calculate_quad(index, points, border_points_count):
	# Quad order: [topRight, topLeft, bottomLeft, bottomRight]
	var quad = [
		points[(index + 1) % border_points_count],
		points[index % border_points_count],
		points[(index + border_points_count/2) % border_points_count],
		points[(index + border_points_count/2 + 1) % border_points_count]
	]

	# If quad twisted
	var intersect_point_1 = Geometry2D.segment_intersects_segment(quad[0], quad[3], quad[1], quad[2])
	var intersect_point_2 = Geometry2D.segment_intersects_segment(quad[1], quad[0], quad[2], quad[3])
	if intersect_point_1 != null:
		quad = [quad[1], quad[0], quad[2], quad[3]]
	if intersect_point_2 != null:
		quad = [quad[2], quad[3], quad[1], quad[0]]

	return quad

# TODO: Refactor & Document
func calculate_border_points(shape_points, border_size, border_overlap=0):
	var border_inner_points = shape_points
	var border_outer_points = expand_or_contract_shape_points(border_inner_points, border_size)

	# close outer shape
	border_inner_points.append(border_inner_points[0] + Vector2(0.0001, 0))
	for i in range(border_outer_points.size()):
		border_inner_points.append(border_outer_points[i])
	# close inner inner shape
	border_inner_points.append(border_outer_points[0] + Vector2(0, 0.0001))
	return border_inner_points

# TODO: Refactor & Document COLOSSAL
func expand_or_contract_shape_points(shape_points, amount, advance=true):
		var points_count = shape_points.size()
		var expand_or_contract_amount = 0.0
		var output_points = []
		var point_normals = []

		for i in range(points_count):
			var a = shape_points[(i + points_count - 1) % points_count]
			var b = shape_points[i]
			var c = shape_points[(i + 1) % points_count]
			# get normals
			var subtractA_B = (b - a).normalized()
			var subtractC_B = (c - b).normalized()
			var a_90 = Vector2(subtractA_B.y, -subtractA_B.x)
			var c_90 = Vector2(subtractC_B.y, -subtractC_B.x)

			point_normals.append((a_90 + c_90).normalized())

		if advance == true:
			for test_point in range(points_count):
				var closet_point
				var closest_distance = abs(amount)
				var test_normal = [shape_points[test_point], amount * point_normals[test_point] + shape_points[test_point]]
				for wall in range(points_count):
					if wall != test_point:
						var top_wall = [shape_points[wall],shape_points[(wall + 1) % points_count]]
						# get wall intersection
						var normal_and_wall_intersect = Geometry2D.segment_intersects_segment(test_normal[0], test_normal[1], top_wall[0], top_wall[1])
						if normal_and_wall_intersect != null :
							var distance_from_test_point_to_intersetion = shape_points[test_point].distance_to(normal_and_wall_intersect)
							if distance_from_test_point_to_intersetion < closest_distance and distance_from_test_point_to_intersetion != 0:
								closest_distance = distance_from_test_point_to_intersetion
								closet_point =  normal_and_wall_intersect

				var newVector
				if closest_distance != abs(amount):
					newVector = closet_point
				else:
					newVector = point_normals[test_point] * amount + shape_points[test_point]
				output_points.append(newVector)
		else:
			for i in range(points_count):
				output_points.append(point_normals[i] * amount + shape_points[i])

		return PackedVector2Array(output_points)

# TODO: Refactor and Document
func smooth_three_points(a, b, c):
	var vector_ba = a - b
	var vector_bc = c - b

	var splitted_b = [
		b + vector_ba.normalized() * (vector_ba.length()/4),
		b + vector_bc.normalized() * (vector_bc.length()/4)
	]

	var output_points = []
	output_points.append(a)
	for point in splitted_b:
		output_points.append(point)
	output_points.append(c)

	return output_points

# TODO: Refactor
func quad_angle(quad):
	# Vector for top quad segment
	var v = quad[QUAD_TOP_1] - quad[QUAD_TOP_2]

	# Perpendicular vector to the segment vector
	# This is the angle for the segment, the face angle
	var vp = Vector2(v.y, v.x * -1)

	# Make angle clockwise
	var angle = positive_angle(PI*2 - vp.angle())
	return angle

func get_smooth_max_nodes():
	return get_polygon().size() * SMOOTH_MAX_NODES_PER_FACE * _border_smooth

# TODO: Refactor
func triad_angle(a, b, c):
	var vector_ab = (b - a).normalized()
	var vector_bc = (c - b).normalized()
	return vector_ab.angle_to(vector_bc)

# TODO: Refactor
func smooth_shape_points(shape_points: PackedVector2Array, max_angle):
	var original_points_count = shape_points.size()
	var new_smooth_points_count = 0
	for _i in range(SMOOTH_MAX_PASSES): # max passes
		var point_to_smooth = []
		var angles_smoothed_this_round = 0
		var current_shape_size = shape_points.size()

		var round_new_points_count = 0
		for i in range(shape_points.size()):
			# b is the point to be smoothen
			# a and c are adyacent points
			var a = shape_points[(i + current_shape_size - 1) % current_shape_size]
			var b = shape_points[i]
			var c = shape_points[(i + 1) % current_shape_size]
			var triad_angle = abs(triad_angle(a, b, c))
			if triad_angle < max_angle:
				var smoothed_points = smooth_three_points(a, b, c)
				var obtained_angle = abs(triad_angle(smoothed_points[0], smoothed_points[1], smoothed_points[2]))
				var angle_gain = triad_angle - obtained_angle
				if angle_gain > SMOOTH_MIN_ANGLE_GAIN:
					round_new_points_count += smoothed_points.size()
					point_to_smooth.append([i, smoothed_points])

		if new_smooth_points_count + round_new_points_count >= get_smooth_max_nodes():
			break
		else:
			new_smooth_points_count += round_new_points_count

		var num_added_points = 0
		for point_info in point_to_smooth:
			shape_points.remove_at(point_info[0] + num_added_points)
			shape_points.insert(point_info[0] + num_added_points, point_info[1][2])
			shape_points.insert(point_info[0] + num_added_points, point_info[1][1])
			angles_smoothed_this_round += 1
			num_added_points += 1

		if angles_smoothed_this_round != 0 and shape_points.size() > 3:
			continue
		break

	return shape_points

# TODO: Refactor
func positive_angle(angle):
	if angle < 0:
		return PI*2 + angle
	else:
		return angle
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


func set_border_smooth(border_smooth: float) -> void:
	_border_smooth = border_smooth


func get_border_smooth() -> float:
	return _border_smooth


func set_border_smooth_max_angle(border_max_smooth_angle: float) -> void:
	_border_smooth_max_angle = border_max_smooth_angle


func get_border_smooth_max_angle() -> float:
	return _border_smooth_max_angle


func set_border_texture_scale(border_texture_scale: Vector2) -> void:
	_border_texture_scale = border_texture_scale;


func get_border_texture_scale() -> Vector2: 
	return _border_texture_scale;


func set_border_texture_offset(border_texture_offset: Vector2) -> void:
	_border_texture_offset = border_texture_offset;


func get_border_texture_offset() -> Vector2: 
	return _border_texture_offset;


func set_border_overlap(border_overlap: float) -> void:
	_border_overlap = border_overlap


func get_border_overlap() -> float:
	return _border_overlap 
#endregion SETGETTERS
