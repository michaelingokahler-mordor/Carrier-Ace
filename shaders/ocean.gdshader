shader_type canvas_item;
render_mode unshaded;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float mission_seconds = 0.0;
uniform float scroll_offset = 0.0;

void fragment() {
	vec2 world = UV * vec2(960.0, 540.0) - vec2(0.0, scroll_offset);
	vec2 uv = world / vec2(700.0, 140.0);
	vec2 current = vec2(mission_seconds * 0.007, mission_seconds * 0.004);
	float swell = texture(noise_tex, uv + current).r;
	float ripple = texture(noise_tex, uv * 3.3 - current * 1.8).r;
	float grain = texture(noise_tex, uv * 10.0 + current * 0.6).r;
	float light = texture(noise_tex, uv + current + vec2(0.006, -0.004)).r - swell;
	float ridge = sin(world.y * 0.075 + world.x * 0.018 + ripple * 5.0 - mission_seconds * 0.8);
	vec3 sea = mix(vec3(0.025, 0.18, 0.27), vec3(0.04, 0.39, 0.47), swell);
	sea += vec3(0.05, 0.10, 0.11) * (ripple - 0.45);
	sea += vec3(0.30, 0.47, 0.46) * max(light, 0.0) * 0.85;
	sea += vec3(0.10, 0.18, 0.19) * smoothstep(0.68, 0.98, ridge) * grain * 0.16;
	float foam = smoothstep(0.87, 0.99, ridge) * smoothstep(0.62, 0.79, grain) * 0.09;
	sea = mix(sea, vec3(0.70, 0.86, 0.85), foam);
	COLOR = vec4(sea, 1.0);
}
