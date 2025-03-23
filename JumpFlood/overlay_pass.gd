@tool
extends BaseCompositorEffect
class_name OverlayPass

@export_category("Outline Settings")
@export var outline_color: Color = Color(0, 0, 0, 1)
@export var outline_width: int = 20

static var public_outline_width: int = 20

const OVERLAY_SHADER_PATH = "res://JumpFlood/overlay.glsl";

var context := "OverlayPass"

var overlay_shader : RID
var overlay_shader_pipeline : RID
var output_img:RDUniform

# Called from _init().
func _initialize_resource() -> void:
	pass


# Called on render thread after _init().
func _initialize_render() -> void:
	overlay_shader = create_shader(OVERLAY_SHADER_PATH)
	overlay_shader_pipeline = create_pipeline(overlay_shader)
	pass
func get_buffer():
	return render_scene_buffers

# Called at beginning of _render_callback(), after updating render variables
# and after _render_size_changed().
# Use this function to setup textures or uniforms.
func _render_setup() -> void:
	public_outline_width = outline_width
	pass


# Called for each view. Run the compute shaders from here.
func _render_view(p_view : int) -> void:
	var color_texture = render_scene_buffers.get_color_layer(p_view)
	var depth_texture = render_scene_buffers.get_depth_layer(p_view)
	var depth_image = get_sampler_uniform(depth_texture, nearest_sampler)
	
	
	var jfa_color = JFAPass.col_pass_in 
	var jfa_image = JFAPass.jfa_pass_in
	var color_image = get_image_uniform(color_texture, 0)
	#if jfa_color==null:return
	var uniform_sets : Array[Array] = [
		[jfa_image],
		[color_image],
		[jfa_color],
		[depth_image]
	]

	var push_constant = PackedFloat32Array([
		render_size.x,
		render_size.y,
		0.0,
		0.0,
		outline_color.r,
		outline_color.g,
		outline_color.b,
		outline_color.a,
		float(outline_width),
		float(Time.get_ticks_msec() / 1000.0)
	])
	
	run_compute_shader(
		"Overlay Pass",
		overlay_shader,
		overlay_shader_pipeline,
		uniform_sets,
		push_constant
	)


# Called before _render_setup() if `render_size` has changed.
func _render_size_changed() -> void:
	render_scene_buffers.clear_context(context)
