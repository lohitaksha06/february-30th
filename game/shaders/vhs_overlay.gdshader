shader_type canvas_item;
// VHS / analog overlay for FEBRUARY 30th Part 1.
// One fullscreen ColorRect. Costs almost nothing: no blur, no extra passes.
// Bad Parenting register = scanlines + noise + vignette + tracking bar.
//
// This is an OVERLAY, not a post-process. It can only add darkness, grain and
// tint on top of the 3D view. The vignette therefore works by fading the
// overlay to black and raising its alpha at the edges, which is the cheap way
// to do a grade in Compatibility.

uniform vec4 shadow_tint : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform float scan_strength = 0.18;
uniform float noise_strength = 0.10;
uniform float vignette_strength = 0.80;
uniform float tracking_speed = 0.09;
uniform float tint_amount = 0.10;

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

	// Tracking bar: one pale band drifting down, plus a slower ghost
	float band_y = fract(TIME * tracking_speed);
	float band = smoothstep(0.030, 0.0, abs(uv.y - band_y)) * 0.075;
	float band2 = smoothstep(0.110, 0.0, abs(uv.y - fract(TIME * 0.041 + 0.37))) * 0.028;

	// Head-switching noise at the very bottom (VHS tell)
	float head = smoothstep(0.955, 1.0, uv.y)
		* (hash(vec2(TIME * 91.0, uv.x * 40.0)) - 0.5) * 0.30;

	// Vignette: black at the edges, not a multiply. d is 0..0.71 at corners.
	vec2 d = uv - vec2(0.5);
	float edge = smoothstep(0.30, 0.72, length(d));

	// Slight cold cast in the shadows. Just enough to read as tape, not filter.
	vec3 col = shadow_tint.rgb * tint_amount;
	float grain_alpha = abs(noise) * 2.1;

	// Mix the overlay toward black at the edges so the corners fall away.
	col = mix(col, vec3(0.0), edge * 0.92);
	float alpha = (1.0 - scan) * 0.55 + grain_alpha + band + band2 + abs(head)
		+ tint_amount + edge * vignette_strength;

	COLOR = vec4(col, clamp(alpha, 0.0, 0.74));
}
