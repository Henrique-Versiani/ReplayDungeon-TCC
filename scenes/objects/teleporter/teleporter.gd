extends Node3D #test

@onready var teleporter_mesh = $TeleporterMesh
var shader_instance
var shader = preload("res://scenes/objects/teleporter/teleporter.tres")
var color = Vector3(randf(), randf(), randf())
var active: bool = true
var temp_body
var temp_character
var tp_position: Vector3

func _ready():
	teleporter_mesh.mesh.material = shader.duplicate()
	
func UpdateShaderPosition(_x, _y, _z):
	print(_x, _y, _z)
	position += Vector3(_x, _y, _z)
	teleporter_mesh.mesh.material.set_shader_parameter("PORTAL_CENTER", Vector3(position.x, position.y, position.z))
	teleporter_mesh.mesh.material.set_shader_parameter("PORTAL_COLOR", Vector3(color.x, color.y, color.z))
	
func _on_body_entered(body):
	if active:
		temp_body = body
		temp_character = temp_body.get_child(3)
		active = false

func _process(delta):
	if $RayCast3D.is_colliding():
		if temp_body and !temp_body.is_teleporting and tp_position:
			temp_body.is_teleporting = true
			temp_body.TeleportPlayer(tp_position.x,tp_position.y,tp_position.z)

			


