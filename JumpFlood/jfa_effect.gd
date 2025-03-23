@tool
extends Node3D
class_name JFAEffect

static var JFASubviewport : SubViewport

@export var target_camera: Camera3D = null
@export var mask_camera : Camera3D = null
@export var mask_viewport : SubViewport

var shader_material: ShaderMaterial = null
var old_selection:Node=null
func _ready() -> void:
	mask_viewport=SubViewport.new()
	mask_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(mask_viewport)
	mask_camera=Camera3D.new()
	mask_viewport.add_child(mask_camera)
	mask_camera.compositor=Compositor.new()
	mask_camera.compositor.compositor_effects=[JFAPass.new()]
	mask_camera.compositor.compositor_effects[0].effect_callback_type=CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	target_camera.sub_camera=mask_camera
	for i in range(1,21,1):mask_camera.set_cull_mask_value(i,i>15)
	var view=get_viewport()
	mask_camera.global_transform=global_transform
	var f = func():
		mask_camera.compositor.compositor_effects[0].extra_buffer=null
		mask_camera.compositor.compositor_effects[0].external_img=null
		mask_camera.compositor.compositor_effects[0].jfa_pass_in=null
		mask_camera.compositor.compositor_effects[0].col_pass_in=null
	if Engine.is_editor_hint():
		var editor_viewport = EditorInterface.get_editor_viewport_3d(0)
		var editor_camera = editor_viewport.get_camera_3d();
		editor_camera.set_cull_mask_value(20,false)
		editor_camera.set_cull_mask_value(19,false)
		editor_camera.set_cull_mask_value(18,false)
		editor_camera.set_cull_mask_value(17,false)
		editor_camera.set_cull_mask_value(16,false)
		view=EditorInterface.get_editor_viewport_3d(0)
		
		tree_exiting.connect(func():
			f.call()
			editor_camera.compositor=null
			)
		
	
	view.size_changed.connect(func():
		var size=view.size
		target_camera.compositor.compositor_effects[0].render_size=size
		mask_camera.compositor.compositor_effects[0].render_size=size
		f.call()
		if Engine.is_editor_hint():
			var editor_camera = view.get_camera_3d()
			editor_camera.compositor.compositor_effects[0].render_size=size
		)


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
		#target_camera.global_transform=editor_camera.global_transform
		mask_camera.fov=editor_camera.fov
		mask_camera.compositor.compositor_effects[0].set_img=true
		mask_camera.compositor.compositor_effects[0].extra_buffer=editor_camera.compositor.compositor_effects[0].render_scene_buffers
	elif target_camera != null:
		mask_camera.global_transform = target_camera.global_transform
		mask_camera.fov = target_camera.fov
		mask_camera.projection = target_camera.projection
		mask_viewport.size = get_viewport().size
	#mask_viewport.render_target_update_mode=1
	#$SubViewportContainer/SubViewport.render_target_update_mode=1
