shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform int correction = 0;
uniform bool high_contrast = false;
uniform float post_intensity = 0.0;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	if (correction == 1) { c.rgb = vec3(c.r * 0.55 + c.g * 0.45, c.g, c.b + c.r * 0.25); }
	if (correction == 2) { c.rgb = vec3(c.r, c.g * 0.55 + c.r * 0.45, c.b + c.g * 0.25); }
	if (correction == 3) { c.rgb = vec3(c.r + c.b * 0.25, c.g, c.b * 0.55 + c.g * 0.45); }
	if (high_contrast) { c.rgb = clamp((c.rgb - 0.5) * 1.25 + 0.5, vec3(0.0), vec3(1.0)); }
	float edge = smoothstep(0.25, 0.72, distance(SCREEN_UV, vec2(0.5)));
	c.rgb *= 1.0 - edge * post_intensity * 0.12;
	COLOR = c;
}
