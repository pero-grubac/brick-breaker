shader_type canvas_item;

// Retro CRT look drawn on top of everything: dark scanlines and a soft vignette.
// It only darkens, so it needs no screen texture and works with the Compatibility renderer.

uniform float line_alpha : hint_range(0.0, 1.0) = 0.16;
// Scanline period in screen pixels.
uniform float line_period : hint_range(2.0, 8.0) = 3.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;

void fragment() {
	float line = step(line_period * 0.5, mod(FRAGCOORD.y, line_period));
	vec2 centered = SCREEN_UV - vec2(0.5);
	float vignette = smoothstep(0.35, 0.8, length(centered)) * vignette_strength;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(line * line_alpha + vignette, 0.0, 1.0));
}
