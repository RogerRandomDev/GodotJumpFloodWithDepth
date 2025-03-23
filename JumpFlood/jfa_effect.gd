@tool
extends Node3D
class_name JFAEffect

static var JFASubviewport : SubViewport

@export var target_camera: Camera3D = null
@export var mask_camera : Camera3D = null
@export var mask_viewport : SubViewport

var shader_material: ShaderMaterial = null

func _ready() -> void:
	$SubViewport.render_target_update_mode=4


func _process(delta: float) -> void:
	if !JFASubviewport:
		JFASubviewport = mask_viewport
	#RenderingServer.force_draw(false)
	if Engine.is_editor_hint():
		var editor_viewport = EditorInterface.get_editor_viewport_3d(0)
		var editor_camera = editor_viewport.get_camera_3d();
		editor_camera.compositor = target_camera.compositor
		
		mask_camera.global_transform = editor_camera.global_transform
		mask_camera.fov = editor_camera.fov
		mask_viewport.size.x = editor_viewport.size.x
		mask_viewport.size.y = editor_viewport.size.y
		
	elif target_camera != null:
		mask_camera.global_transform = target_camera.global_transform
		mask_camera.fov = target_camera.fov
		mask_camera.projection = target_camera.projection
		mask_viewport.size = get_viewport().size
	#mask_viewport.render_target_update_mode=1
	#$SubViewportContainer/SubViewport.render_target_update_mode=1
	
	
