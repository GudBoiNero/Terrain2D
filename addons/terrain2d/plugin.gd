@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Terrain2D", "Polygon2D", preload("terrain2d.gd"), preload("icon.png"))


func _exit_tree():
	remove_custom_type("Terrain2D")
