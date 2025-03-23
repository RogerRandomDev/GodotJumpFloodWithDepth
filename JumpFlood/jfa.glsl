#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(constant_id = 0) const int OFFSET = 1;
layout(constant_id = 1) const bool X_DIR = false;

layout(rgba16f, set = 0, binding = 0) uniform image2D source_image;
layout(rgba16f, set = 1, binding = 0) uniform image2D dest_image;

// Our push constant
layout(push_constant, std430) uniform Params {
	vec2 raster_size;
	vec2 inv_raster_size;
} params;

const float MAX_DISTANCE = 1000000000.0f;


// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(params.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(source_image, uv);
	color.a = 1.0f;
	vec2 pos = vec2(uv);
	float bestSqrDistance = MAX_DISTANCE;
	vec2 closestPoint = vec2(0.0f);
	ivec2 direction = X_DIR ? ivec2(1, 0) : ivec2(0, 1);
	for (int i = -1; i <= 1; i++) {
		ivec2 offset = direction * i * OFFSET;
		vec2 point = round(imageLoad(source_image, uv + offset).gb * params.raster_size);
		float sqrDistance = (point.x > 0.0f || point.y > 0.0f) ? dot(point - pos, point - pos) : MAX_DISTANCE;
		if (sqrDistance < bestSqrDistance) {
			bestSqrDistance = sqrDistance;
			closestPoint = point;
		}
	}
	
	color.gb = closestPoint * params.inv_raster_size;
	
	imageStore(dest_image, uv, color);
}
