#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D stencil_pass_image;
layout(rgba8, set = 1, binding = 0) uniform image2D color_image;
layout(rgba16f, set = 2, binding = 0) uniform image2D color_image_map;
layout(set = 3, binding = 0) uniform sampler2D depth_sampler;
// layout(rgba16f, set = 4, binding = 0) uniform image2D depth_image;


// Our push PushConstant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec4 outline_color;
	float outline_width;
	float time;
} params;

float clamp01(float x) {
	return clamp(x, 0.0f, 1.0f);
}

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}
	vec4 base=imageLoad(color_image_map,uv).rgba;
	vec4 color = imageLoad(color_image, uv);
	vec4 jfa_color = imageLoad(stencil_pass_image, uv).rgba;
	
	if(base.a>0.0 && base.a>texelFetch(depth_sampler,uv,0).r){
		base.a=1.0;
		
		imageStore(color_image,uv,base.rgba);
		
		return;
	}


	if (jfa_color.r > 0 || (jfa_color.g <= 0 && jfa_color.b <= 0)) {
		return;
	}
	// imageStore(color_image,uv,jfa_color.rgba);
	
	// Crazy outline
	ivec2 jfa_uv = uv + ivec2(sin((float(uv.x) * 0.07f) + params.time * 21.0f) * 10.0f, sin((float(uv.y) * 0.05) + params.time * 25.0f) * 17.0f);
	
	vec2 closestPoint = round(jfa_color.gb * params.raster_size);
	// vec2 offset = closestPoint - vec2(jfa_uv);
	vec2 offset = closestPoint - vec2(uv);
	float distSqr = dot(offset, offset);
	// float widthSqr = params.outline_width * params.outline_width;
	// float outline = 1.0f - clamp01((distSqr - widthSqr));
	
	// Ripple Outline
	/*float dist = length(offset);
	float outline = 0.0f;
	if (dist < params.outline_width) {
		outline = sin(dist - (params.time * 10.0f));
	}*/
	
	// Crazy Outline
	/*float dist = length(offset);
	float local_width = params.outline_width * (0.5f - (sin(closestPoint.x + params.time * 3.0f) + sin(closestPoint.y + params.time * 3.0f)) * 0.5f);
	float outline = 1.0f - clamp01(dist - local_width);*/
	
	float stepped_time = floor(params.time*8.0)*0.125;

	float dist = length(offset);
	float average_width = 0.0f;
	float num_samples = 0.0f;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			jfa_color.rgb = imageLoad(stencil_pass_image, uv + (ivec2(x, y) * 3)).rgb;
			if (jfa_color.r <= 0 && (jfa_color.g > 0 || jfa_color.b > 0)) {
				vec2 sample_closestPoint = round(jfa_color.gb * params.raster_size);
				float local_width = params.outline_width * (0.75f - (sin((sample_closestPoint.x * 0.15f) + stepped_time * 3.0f) + sin((sample_closestPoint.y * 0.15f) + stepped_time * 7.0f)) * 0.125f);
				average_width += local_width;
				num_samples += 1.0f;
			}
		}
	}
	
	if (num_samples > 0.5f) {
		average_width /= num_samples;
	}
	
	float outline = 1.0f - clamp01(dist - average_width);
	
	float alpha_reduced_mix_factor = clamp01(outline - (1.0f - params.outline_color.a));
	color.rgb = mix(color.rgb, params.outline_color.rgb, alpha_reduced_mix_factor);
	color.a += outline * params.outline_color.a;
	// if(jfa_color.a!=0.0){color.rgb+=jfa_color.rgb;}

	imageStore(color_image, uv, color);

	
}
