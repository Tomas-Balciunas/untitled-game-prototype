shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform sampler2D albedo_texture : source_color, filter_nearest;

uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_strength = 0.08;
uniform vec4 edge_color : source_color = vec4(0.5, 0.0, 0.0, 1.0);
uniform float edge_size = 0.05;
uniform float noise_scale = 25.0;
uniform float drip_strength = 0.1;

// Simple 1D noise function
float noise(in float x) {
    return fract(sin(x) * 43758.5453);
}

// Layered noise for more organic variation
float layered_noise(in float x, in float progress) {
    float n = 0.0;
    float amp = 1.0;
    float freq = noise_scale;
    for (int i = 0; i < 4; i++) {
        n += (noise(x * freq + progress * 5.0) * 2.0 - 1.0) * amp;  // -1 to 1 range
        freq *= 2.0;
        amp *= 0.5;
    }
    return n;
}

void fragment() {
    vec2 atlas_uv = UV;

    vec2 local_uv = (atlas_uv - uv_offset) / uv_scale;

    if (local_uv.x < 0.0 || local_uv.x > 1.0 ||
        local_uv.y < 0.0 || local_uv.y > 1.0) {
        discard;
    }

    vec4 tex = texture(albedo_texture, atlas_uv);

    float threshold = death_progress;
	
	float n = layered_noise(local_uv.x, death_progress);
    
    // Apply noise for irregular edge
    float effective_threshold = threshold + n * noise_strength;
	
	effective_threshold -= abs(n) * drip_strength;  // Negative bias for longer drips where noise is high

    if (local_uv.y < threshold) {
        discard;
    }

    ALBEDO = tex.rgb;
    ALPHA = tex.a;

    if (abs(local_uv.y - effective_threshold) < edge_size) {
        float edge_factor = smoothstep(0.0, edge_size, edge_size - abs(local_uv.y - effective_threshold));
        ALBEDO = mix(ALBEDO, edge_color.rgb, edge_factor * 0.8);  // Smoother transition for gooey feel
    }
}
