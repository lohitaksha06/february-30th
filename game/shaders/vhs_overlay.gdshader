shader_type canvas_item;
// VHS / analog overlay for FEBRUARY 30th Part 1.
// One fullscreen ColorRect. Costs almost nothing: no blur, no extra passes.
// Bad Parenting register = scanlines + noise + vignette + tracking bar.

uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float scan_strength = 0.16;
uniform float noise_strength = 0.09;
uniform float vignette_strength = 0.55;
uniform float tracking_speed = 0.13;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	// Scanlines (horizontal, tied to low internal res)
	float scan = sin(uv.y * 180.0 * 3.14159) * 0.5 + 0.5;
	scan = (1.0 - scan_strength) + scan * scan_strength;

	// Animated grain
	float n = hash(uv * vec2(320.0, 180.0) + vec2(TIME * 61.7, TIME * 83.3));
	float noise = (n - 0.5) * noise_strength;

	// Vignette: dark soft corners, very analog
	vec2 d = uv - vec2(0.5);
	float vig = 1.0 - dot(d, d) * vignette_strength * 2.0;

	// Tracking bar: one pale band drifting down, occasional
	float band_y = fract(TIME * tracking_speed);
	float band = smoothstep(0.03, 0.0, abs(uv.y - band_y)) * 0.10;

	// Head-switching noise at the very bottom (VHS tell)
	float head = smoothstep(0.94, 1.0, uv.y) * (hash(vec2(TIME * 91.0, uv.x * 40.0)) - 0.5) * 0.25;

	vec3 col = vec3(noise + band + head);
	float alpha = (1.0 - scan) * 0.6 + abs(noise) * 2.0 + band + abs(head);
	// Keep it subtle: this rect sits OVER the 3D view
	COLOR = vec4(col, clamp(alpha, 0.0, 0.32)) * vec4(vig, vig, vig, 1.0);
}
