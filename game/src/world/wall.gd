@tool
extends Node3D
## A single wall, built from code so no .tscn needs hand-editing.
##
## Level geometry is built procedurally at load time rather than authored in the
## editor. Reasons, in order of importance:
##
##  1. The prologue is FOUR ROOMS. Authoring that as .tscn files means dozens of
##     merge-conflicting files for two people. docs/scope.md advises one file
##     per person per week.
##  2. The triangle budget is enforced in code, not by discipline.
##     docs/art-direction.md §3.
##  3. Room dimensions are data, so "the small house" is a table you can read.

@export var width: float = 4.0
@export var height: float = 2.6
@export var thickness: float = 0.12
@export var colour: Color = Color(0.62, 0.60, 0.58)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build()


func _build() -> void:
	# A wall is one box mesh + one static body, no subdivision surface.
	# 12 triangles. That is the whole point. docs/art-direction.md §3.
	var body := StaticBody3D.new()
	add_child(body)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, thickness)

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material()
	body.add_child(mi)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	col.shape = shape
	body.add_child(col)


func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 1.0
	m.metallic = 0.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# No PBR, no normal maps, albedo only. docs/art-direction.md §3.
	return m


## Convenience: place a wall along an X-aligned span.
func place_x(x: float, z: float, span: float, rot_y: float = 0.0) -> void:
	width = span
	position = Vector3(x, height * 0.5, z)
	rotation.y = rot_y


## Convenience: place a wall along a Z-aligned span.
func place_z(x: float, z: float, span: float, rot_y: float = 0.0) -> void:
	width = span
	position = Vector3(x, height * 0.5, z)
	rotation.y = rot_y + PI * 0.5