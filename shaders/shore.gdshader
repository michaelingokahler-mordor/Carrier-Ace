shader_type canvas_item;
render_mode unshaded;
uniform float mission_seconds = 0.0;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

void fragment() {
	float bank = texture(TEXTURE, UV).r;
	float detail = texture(noise_tex, UV * 8.0 + vec2(mission_seconds * 0.014, -mission_seconds * 0.009)).r;
	float front = 0.48 + sin(mission_seconds * 1.4 + detail * 4.0) * 0.28;
	float foam = exp(-pow((bank - front) / 0.19, 2.0)) * smoothstep(0.28, 0.67, detail);
	vec3 color = mix(vec3(0.07, 0.52, 0.56), vec3(0.88, 0.95, 0.90), foam);
	COLOR = vec4(color, bank * (0.20 + foam * 0.36));
}
