shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;


uniform vec4 hazard_color : source_color = vec4(0.4, 0.9, 0.3, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.6;
uniform float flow_speed = 0.6;
uniform float pattern_scale = 1.4;
uniform float pixel_size = 0.0625;
uniform float edge_fade = 0.15;
uniform vec2 patch_size = vec2(2.0, 2.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = world_pos.xz;
	if (pixel_size > 0.0) {
		p = floor(p / pixel_size) * pixel_size;
	}

	float t = TIME * flow_speed;
	float n = noise(p * pattern_scale + vec2(t, t * 0.7)) * 0.6
		+ noise(p * pattern_scale * 2.3 - vec2(t * 1.3, t * 0.4)) * 0.4;
	float glow = smoothstep(0.35, 0.85, n);

	vec2 from_edge = min(UV, 1.0 - UV) * patch_size;
	float border = smoothstep(0.0, edge_fade, min(from_edge.x, from_edge.y));

	ALBEDO = hazard_color.rgb * (0.55 + 0.9 * glow);
	ALPHA = opacity * mix(0.45, 1.0, glow) * border;
}
