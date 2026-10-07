shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// PS1 vertex snap + affine texture warping.
//
// This is roughly 20 lines and it is the single biggest contributor to the
// look. docs/art-direction.md §4.2.
//
// Why it works: PS1 hardware had no sub-pixel precision in the vertex stage,
// so geometry quantised as it moved and textures warped because there was no
// perspective correction. Both artefacts read instantly as "old cursed game",
// and both are free.

uniform float snap_strength : hint_range(0.0, 4.0) = 2.0;
// Lower = coarser jitter. 1.0 is very visible, 0.5 is subtle.
uniform float snap_horizontal : hint_range(0.0, 2.0) = 0.5;
uniform vec2 snap_resolution = vec2(320.0, 180.0);

// Affine warping: 0 = correct perspective, 1 = full PS1 affine. The stretching
// on a surface viewed at a grazing angle is what makes the world feel wrong
// in a way the player cannot name.
uniform float affine_amount : hint_range(0.0, 1.0) = 0.85;

// Vertex lighting baked to avoid depending on light directions.
varying vec4 v_affine;

void vertex() {
	// --- vertex snap -------------------------------------------------
	// Quantise in screen space. MODELVIEW_MATRIX gives us view space; the
	// projection happens after, so snapping in clip space is what actually
	// produces the wobble as the camera moves.
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);

	// --- affine UV --------------------------------------------------
	// PS1 interpolated UVs across the triangle linearly in screen space,
	// which means dividing by w only once instead of per-fragment.
	v_affine = vec4(UV * 2.0 - 1.0, 0.0, 1.0);

	// Reconstruct clip position so we can snap it.
	vec4 clip = PROJECTION_MATRIX * view_pos;
	vec2 grid = snap_resolution;
	// Snap position, keep depth uncorrected (that is the artefact).
	clip.xy = floor(clip.xy / grid) * grid;

	POSITION = clip;
}

void fragment() {
	// Affine texture lookup: interpolate UV/w linearly.
	vec2 uv = (v_affine.xy / v_affine.w) * 0.5 + 0.5;
	uv = mix(UV, uv, affine_amount);

	vec4 tex = texture(albedo_texture, uv);
	ALBEDO = tex.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}