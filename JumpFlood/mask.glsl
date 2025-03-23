#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D depth_sampler;
layout(rgba16f, set = 1, binding = 0) uniform image2D dest_image;
layout(set = 2, binding = 0) uniform sampler2D depth_sampler_main;
layout(rgba16f, set = 3, binding = 0) uniform image2D base_image;


// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 inv_raster_size;
} params;

float get_raw_depth(ivec2 p_coord) {
	return texelFetch(depth_sampler, p_coord, 0).r;
}
float get_raw_depth_main(ivec2 p_coord) {
	return texelFetch(depth_sampler_main, p_coord, 0).r;
}



// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}
	float main_depth=get_raw_depth_main(uv);
	
	vec4 color = vec4(get_raw_depth(uv), 0, 0, 0);
	vec4 img_col=vec4(imageLoad(base_image,uv).rgb,color.r);
	// if(main_depth>color.r+0.01){color.r=0.0f;}
	if (color.r > 0.0f){
		if(main_depth<color.r){
			color.gb = vec2(uv) * params.inv_raster_size;
		}else{
			color.r = 0.0;
		}
	}
	
	imageStore(base_image,uv,img_col);
	imageStore(dest_image, uv, color);
}
