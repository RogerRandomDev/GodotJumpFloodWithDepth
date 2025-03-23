@tool
extends BaseCompositorEffect
class_name JFAPass

static var jfa_pass_in : RDUniform
static var col_pass_in : RDUniform

const MASK_SHADER_PATH := "res://JumpFlood/mask.glsl"
const JFA_SHADER_PATH := "res://JumpFlood/jfa.glsl"

var context := "StencilPass"

var mask_shader : RID
var mask_shader_pipeline : RID

var jfa_shader : RID
var jfa_shader_x_pipelines := {}
var jfa_shader_y_pipelines := {}

var texture_a : StringName = "TextureA"
var image_a : RDUniform

var texture_b : StringName = "TextureB"
var image_b : RDUniform
var image_c : RDUniform
var external_img:RDUniform
var set_img:bool=false

var extra_buffer:RenderSceneBuffersRD

var default_push_constant: PackedFloat32Array

# Called from _init().
func _initialize_resource() -> void:
	pass


# Called on render thread after _init().
func _initialize_render() -> void:
	mask_shader = create_shader(MASK_SHADER_PATH)
	mask_shader_pipeline = create_pipeline(mask_shader)
	
	jfa_shader = create_shader(JFA_SHADER_PATH)
	
	const MAX_WIDTH = 500
	var max_index = ceil(log(MAX_WIDTH) / log(2))
	
	for i in range(max_index):
		jfa_shader_x_pipelines[i] = create_pipeline(jfa_shader, {
			0: 2 ** i,
			1: true
		})
		jfa_shader_y_pipelines[i] = create_pipeline(jfa_shader, {
			0: 2 ** i,
			1: false
		})
	pass


# Called at beginning of _render_callback(), after updating render variables
# and after _render_size_changed().
# Use this function to setup textures or uniforms.
func _render_setup() -> void:
	default_push_constant = PackedFloat32Array([
		render_size.x,
		render_size.y,
		1.0 / render_size.x,
		1.0 / render_size.y
	]);
	if not (render_scene_buffers.has_texture(context, texture_a) and render_scene_buffers.has_texture(context, texture_b)):
		create_textures()
	pass


# Called for each view. Run the compute shaders from here.
func _render_view(p_view : int) -> void:
	if extra_buffer==null or not set_img:return
	var color_texture = render_scene_buffers.get_color_layer(p_view)
	var depth_texture = render_scene_buffers.get_depth_layer(p_view)
	var color_image = get_image_uniform(color_texture)
	if external_img==null:
		var ex_depth= extra_buffer.get_depth_layer(p_view)
		external_img=get_sampler_uniform(ex_depth,nearest_sampler)
	
	var depth_image = get_sampler_uniform(depth_texture, nearest_sampler)
	
	maskPass(depth_image, image_a,color_image)
	
	var max_index = ceil(log(OverlayPass.public_outline_width) / log(2))
	
	for i in range(max_index, 0, -1):
		jfaPass(image_a, image_b, false, i - 1)
			
		jfaPass(image_b, image_a, true, i - 1)
	
	jfa_pass_in = image_a
	col_pass_in = color_image


func maskPass(from: RDUniform, to: RDUniform,color:RDUniform):
	if external_img==null or color==null:return
	var uniform_sets : Array[Array];
	RenderingServer
	uniform_sets = [
		[from],
		[to],
		[external_img],
		[color]
	]
	
	run_compute_shader(
		"MaskPass",
		mask_shader,
		mask_shader_pipeline,
		uniform_sets,
		default_push_constant
	)

func jfaPass(from: RDUniform, to: RDUniform, x_dir: bool, index: int):
	if external_img==null:return
	var uniform_sets : Array[Array] = [
		[from],
		[to]
	]
	
	if x_dir:
		run_compute_shader(
			"JFA X Pass %d" % index,
			jfa_shader,
			jfa_shader_x_pipelines[index],
			uniform_sets,
			default_push_constant
		)
	else:
		run_compute_shader(
			"JFA Y Pass %d" % index,
			jfa_shader,
			jfa_shader_y_pipelines[index],
			uniform_sets,
			default_push_constant
		)
		


# Called before _render_setup() if `render_size` has changed.
func _render_size_changed() -> void:
	render_scene_buffers.clear_context(context)
	

func create_textures() -> void:
	var texture_a_image : RID = create_simple_texture(
			context,
			texture_a,
			RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
	)
	image_a = get_image_uniform(texture_a_image)


	var texture_b_image : RID = create_simple_texture(
			context,
			texture_b,
			RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
	)
	image_b = get_image_uniform(texture_b_image)
	#
	#var texture_c_image : RID = create_simple_texture(
			#context,
			#"Texture_C_Image",
			#RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT,
	#)
	#image_c = get_image_uniform(texture_c_image)
