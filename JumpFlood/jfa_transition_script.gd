@tool
extends MeshInstance3D

@export var images : Array[Texture]

var shader_material : ShaderMaterial
var wait_timer: float = 0
var transition_timer: float = 0
var transition_index: int = -1

func is_jfa_pass(index: int):
	return (index >= 1 and index <= 4)

func _ready() -> void:
	shader_material = mesh.material as ShaderMaterial
	shader_material.set_shader_parameter("from", images[0])
	shader_material.set_shader_parameter("to", images[1])
	shader_material.set_shader_parameter("time", 0.0)
	wait_timer = 2

func _process(delta: float) -> void:
	if wait_timer > 0:
		if transition_index >= images.size() - 2:
			return
		
		wait_timer -= delta * 0.5
		if wait_timer <= 0:
			transition_index += 1
			shader_material.set_shader_parameter("from", images[transition_index])
			shader_material.set_shader_parameter("to", images[transition_index + 1])
			shader_material.set_shader_parameter("time", 0.0)
			shader_material.set_shader_parameter("jfa_pass_from", is_jfa_pass(transition_index))
			shader_material.set_shader_parameter("jfa_pass_to", is_jfa_pass(transition_index + 1))
			transition_timer = 1
	elif transition_timer > 0:
		transition_timer -= delta * 0.5
		shader_material.set_shader_parameter("time", 1.0 - transition_timer)
		if transition_timer <= 0:
			shader_material.set_shader_parameter("time", 1.0)
			wait_timer = 1
		
