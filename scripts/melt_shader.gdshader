shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform sampler2D albedo_texture : source_color;

uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_strength = 0.08;
uniform vec4 edge_color : source_color = vec4(0.5, 0.0, 0.0, 1.0);
uniform float edge_size = 0.05;

void fragment() {
    vec2 atlas_uv = UV;

    vec2 local_uv = (atlas_uv - uv_offset) / uv_scale;

    if (local_uv.x < 0.0 || local_uv.x > 1.0 ||
        local_uv.y < 0.0 || local_uv.y > 1.0) {
        discard;
    }

    vec4 tex = texture(albedo_texture, atlas_uv);

    float threshold = death_progress;

    if (local_uv.y < threshold) {
        discard;
    }

    ALBEDO = tex.rgb;
    ALPHA = tex.a;

    if (abs(local_uv.y - threshold) < edge_size) {
        ALBEDO = mix(ALBEDO, edge_color.rgb, 0.7);
    }
}
