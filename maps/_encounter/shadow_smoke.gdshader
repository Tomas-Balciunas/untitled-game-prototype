shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 core_color : source_color = vec4(0.01, 0.01, 0.015, 1.0);
uniform vec4 edge_color : source_color = vec4(0.16, 0.17, 0.24, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.9;
uniform float flow_speed = 0.3;
uniform float distortion : hint_range(0.0, 1.0) = 0.5;
uniform float pixel_columns : hint_range(4.0, 64.0) = 40.0;
uniform float anim_fps = 10.0;
uniform int color_steps : hint_range(2, 8) = 3;
uniform sampler2D noise : repeat_enable, filter_linear;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
const float ASPECT = 1.6;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 grid = vec2(pixel_columns, pixel_columns * ASPECT);
	vec2 cell = floor(UV * grid);
	vec2 puv = (cell + 0.5) / grid;

	float time = anim_fps > 0.0 ? floor(TIME * anim_fps) / anim_fps : TIME;
	float t = time * flow_speed;
	vec2 seed = NODE_POSITION_WORLD.xz * 0.07;

	float h0 = 1.0 - puv.y;
	vec2 w = vec2(
		texture(noise, puv * 0.7 + seed + vec2(t * 0.15, t * 0.4)).r,
		texture(noise, puv * 0.7 - seed + vec2(0.37 - t * 0.2, t * 0.35)).r) - 0.5;
	vec2 uv = puv + w * distortion * (0.25 + 0.75 * h0) * 0.6;
	uv.x += sin(t * 3.0 + seed.x * 6.0) * 0.06 * distortion * h0;

	float h = 1.0 - uv.y;
	float n1 = texture(noise, uv * vec2(1.0, 0.8) + seed + vec2(0.0, t)).r;
	float n2 = texture(noise, uv * vec2(1.7, 1.4) - seed + vec2(t * 0.3, t * 1.6)).r;
	float n = n1 * 0.6 + n2 * 0.4;

	float lean = texture(noise, vec2(0.5 + seed.y, h * 0.6 - t * 0.2)).r - 0.5;
	float rag = texture(noise, vec2(seed.x * 3.0, h * 1.5 - t * 0.5)).r;
	float x = (uv.x - 0.5) * 2.0 - lean * 0.5 * distortion;

	float body_w = mix(0.8, 0.5, smoothstep(0.0, 0.7, h)) * mix(1.0, 0.6 + rag * 0.8, distortion);
	float body = 1.0 - smoothstep(body_w - 0.3, body_w, abs(x));
	body *= 1.0 - smoothstep(0.62, 0.82, h + (n - 0.5) * 0.3 * distortion);

	vec2 hp = vec2(x * 1.2, (h - 0.8) * 3.2);
	float head = 1.0 - smoothstep(0.1, 0.5, length(hp) + (n - 0.5) * 0.6 * distortion);

	float wisp = smoothstep(0.6, 0.85, n2) * (1.0 - smoothstep(0.75, 1.0, h))
		* (1.0 - smoothstep(0.0, 0.6, abs(x))) * distortion * 0.8;

	float shape = max(max(body, head), wisp);
	shape *= smoothstep(0.0, 0.3, h + (n - 0.5) * 0.5);
	shape *= smoothstep(0.0, 0.1, puv.x) * smoothstep(1.0, 0.9, puv.x) * smoothstep(0.0, 0.06, puv.y);

	float density = shape * (0.5 + n * 0.9);
	float a = smoothstep(0.25, 0.75, density);

	ivec2 ic = ivec2(cell) % 4;
	if (a <= (BAYER[ic.y * 4 + ic.x] + 0.5) / 16.0) {
		discard;
	}

	float steps = float(color_steps);
	float shade = floor(clamp(smoothstep(0.4, 1.0, density), 0.0, 0.999) * steps) / (steps - 1.0);
	ALBEDO = mix(edge_color.rgb, core_color.rgb, shade);
	ALPHA = opacity;
}
