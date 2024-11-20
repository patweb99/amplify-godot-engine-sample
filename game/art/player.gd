extends Node3D
class_name Character

@onready var meshInstance3D: MeshInstance3D = $Sphere_001

var _eye_color: Color = Color.WHITE
var _pupil_color: Color = Color.BLACK
var _body_color: Color = Color.ORANGE_RED

func set_eye_color(color):
	_eye_color = color
	_update_colors()

func set_pupil_color(color):
	_pupil_color = color
	_update_colors()
	
func set_body_color(color):
	_body_color = color
	_update_colors()
	
func _update_colors() -> void:
	var mesh = meshInstance3D.mesh
	for i in mesh.get_surface_count():
		var surface_material: BaseMaterial3D = mesh.surface_get_material(i)
		if i == 0:
			surface_material.albedo_color = _pupil_color
		elif i == 1:
			surface_material.albedo_color = _body_color
		else:
			surface_material.albedo_color = _eye_color

func _ready() -> void:
	_update_colors()
