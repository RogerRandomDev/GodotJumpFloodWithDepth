@tool
extends Camera3D
class_name PlayerCamera
var targetOrigin

@export var sub_camera : Camera3D

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	
	if not Engine.is_editor_hint():
		sub_camera.compositor.compositor_effects[0].set_img=true
		sub_camera.compositor.compositor_effects[0].extra_buffer=compositor.compositor_effects[0].render_scene_buffers
