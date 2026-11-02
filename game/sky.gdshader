shader_type canvas_item;
// Procedural night sky: gradient, twinkling parallax stars, ridges, frost vignette.
uniform vec2 cam = vec2(0.0);
uniform float warm = 0.0;   // 0 night .. 1 warm dusk .. 1.5 dawn
uniform float cold = 0.0;   // frost vignette
uniform float tm = 0.0;
uniform vec2 res = vec2(1280.0, 720.0);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n1(float x) { float i = floor(x); float f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(hash(vec2(i, 1.3)), hash(vec2(i + 1.0, 1.3)), f); }
float stars(vec2 p, float sc, float thr) {
	vec2 g = floor(p / sc); vec2 f = fract(p / sc);
	float h = hash(g);
	if (h < thr) return 0.0;
	vec2 c = vec2(0.2 + 0.6 * hash(g + 3.1), 0.2 + 0.6 * hash(g + 7.7));
	float d = length(f - c) * sc;
	float tw = 0.55 + 0.45 * sin(tm * (0.8 + h * 2.5) + h * 40.0);
	return (smoothstep(2.2, 0.0, d) + 0.25 * smoothstep(7.0, 0.0, d)) * tw;
}
void fragment() {
	vec2 px = UV * res;
	float w1 = clamp(warm, 0.0, 1.0);
	float w2 = clamp((warm - 1.0) * 2.0, 0.0, 1.0);
	vec3 top = mix(mix(vec3(0.012, 0.02, 0.06), vec3(0.09, 0.05, 0.19), w1), vec3(0.22, 0.30, 0.55), w2);
	vec3 bot = mix(mix(vec3(0.03, 0.05, 0.13), vec3(0.42, 0.20, 0.30), w1), vec3(1.0, 0.64, 0.42), w2);
	vec3 col = mix(top, bot, pow(UV.y, 1.5));
	// soft nebula band
	float neb = n1(px.x * 0.004 + cam.x * 0.0002 + 3.0) * n1(px.y * 0.006 + cam.y * 0.0004);
	col += vec3(0.10, 0.08, 0.22) * neb * 0.35 * (1.0 - w2);
	float s = stars(px + cam * 0.04, 37.0, 0.80) * 0.45
			+ stars(px + cam * 0.09, 61.0, 0.86) * 0.75
			+ stars(px + cam * 0.18, 97.0, 0.90) * 1.0;
	col += vec3(0.85, 0.9, 1.0) * s * (1.0 - 0.85 * w2);
	// ridges (far to near)
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float par = 0.12 + 0.16 * fi;
		vec2 wp = px + cam * par;
		float sc = 260.0 - 60.0 * fi;
		float h = n1(wp.x / sc + fi * 17.0) * 0.6 + n1(wp.x / sc * 2.3 + 5.0) * 0.3 + n1(wp.x / sc * 6.0) * 0.1;
		float H = 470.0 + 300.0 * par + fi * 45.0 - h * (190.0 - 35.0 * fi);
		float m = smoothstep(H - 1.5, H + 1.5, wp.y);
		vec3 rc = mix(vec3(0.03, 0.04, 0.09) * (1.6 - 0.4 * fi), vec3(0.16, 0.09, 0.14) * (1.4 - 0.3 * fi), w1);
		rc = mix(rc, vec3(0.30, 0.25, 0.36) * (1.2 - 0.3 * fi), w2);
		float rim = smoothstep(H + 6.0, H, wp.y) * m;
		rc += vec3(0.9, 0.55, 0.4) * rim * 0.25 * w1;
		col = mix(col, rc, m);
	}
	float d = length((UV - 0.5) * vec2(1.6, 1.0));
	col = mix(col, vec3(0.62, 0.76, 0.98), cold * smoothstep(0.45, 0.95, d) * 0.55);
	col += (hash(px + fract(tm)) - 0.5) / 128.0;
	COLOR = vec4(col, 1.0);
}
