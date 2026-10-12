shader_type canvas_item;
uniform int paint_mode = 0;
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 vec3 c = source.rgb;
 float light = dot(c, vec3(0.299, 0.587, 0.114));
 // Preserve bright insignia and dark canopy / panel lines.
 float metal = smoothstep(0.10,0.24,light) * (1.0-smoothstep(0.73,0.90,light));
 vec3 paint = c;
 if (paint_mode == 1) paint = vec3(0.91,0.92,0.88) * (0.42+light);
 if (paint_mode == 2) paint = vec3(0.93,0.19,0.15) * (0.38+light);
 if (paint_mode == 3) {
  float patch = step(0.1, sin(UV.x*31.0+sin(UV.y*19.0)*2.5));
  paint = mix(vec3(0.23,0.33,0.19),vec3(0.56,0.55,0.33),patch)*(0.65+light);
 }
 COLOR = vec4(mix(c,paint,metal),source.a);
}
