// The water standing in the mine: clear blue, darker the deeper it is, with
// moving caustics of light, a few rising bubbles, and a wavy, foamy surface.
//
// Draw each cell of water as a textured rectangle (any white texture) of the
// size of a cell, whose modulate color carries the parameters: r = how full the
// cell is (0 to 1), g = 1 if the cell above is full of water too (so the cell
// has no surface), b = how deep the top of the cell lies under the surface, in
// cells divided by 4 (0 to 1), a = 1. The waves, the caustics and the bubbles
// follow the position in the mine (see [member scroll]), so that they run on
// seamlessly from cell to cell.

shader_type canvas_item;

#include "res://scenes/effects/noise.gdshaderinc"

// The size of a cell, in pixels.
uniform float cell_size = 174.5;
// How far the view scrolled down the mine, in pixels.
uniform float scroll = 0.0;

varying vec2 world;

void vertex() {
    world = VERTEX + vec2(0.0, scroll);
}

void fragment() {
    float level = COLOR.r;
    bool covered = COLOR.g > 0.5;
    float top_depth = COLOR.b * 4.0 * cell_size;
    float y = UV.y * cell_size;
    float t = TIME;

    // NOTE (mristin):
    // Three sines of different lengths make waves which never quite repeat;
    // a shallow puddle has small waves, so that it stays in its cell.
    float wave = 0.5 * sin(world.x * 0.031 + t * 2.1)
        + 0.3 * sin(world.x * 0.077 - t * 2.9)
        + 0.2 * sin(world.x * 0.013 + t * 1.3);
    float amplitude = covered ? 0.0 : 6.0 * smoothstep(0.05, 0.35, level);
    float surface = covered ? -1.0 : (1.0 - level) * cell_size + amplitude * wave;
    float depth = covered ? top_depth + y : y - surface;

    if (depth < 0.0) {
        COLOR = vec4(0.0);
    } else {
        float deep = clamp(depth / (cell_size * 2.5), 0.0, 1.0);
        vec3 shallow_color = vec3(0.24, 0.6, 0.98);
        vec3 deep_color = vec3(0.05, 0.2, 0.55);
        vec3 color = mix(shallow_color, deep_color, deep);

        // Caustics: the light through the waves dances on the water, brighter
        // near the surface.
        vec2 p = world / 130.0;
        float a = fbm(p + vec2(t * 0.16, t * 0.1));
        float b = fbm(p * 1.4 + vec2(-t * 0.13, t * 0.2));
        float caustic = smoothstep(0.0, 1.0, clamp(1.0 - abs(a - b) * 2.2, 0.0, 1.0));
        caustic = caustic * caustic * caustic;
        color += vec3(0.5, 0.82, 1.0) * caustic * (0.3 - 0.2 * deep);

        // Bubbles which rise up through the water.
        vec2 grid = world / vec2(70.0, 70.0) + vec2(0.0, t * 0.9);
        vec2 cell = floor(grid);
        float h = hash21(cell);
        vec2 center = vec2(0.25 + 0.5 * hash21(cell + 7.1), 0.5)
            + vec2(0.08 * sin(t * 3.0 + h * 6.28), 0.0);
        float radius = 0.06 + 0.05 * hash21(cell + 3.3);
        float bubble = h > 0.82
            ? smoothstep(radius, radius * 0.5, length(fract(grid) - center))
            : 0.0;
        color = mix(color, vec3(0.85, 0.95, 1.0), bubble * 0.6);

        float alpha = mix(0.5, 0.72, deep) + bubble * 0.2;

        // The surface: a bright line with flecks of foam.
        if (!covered) {
            float foam = fbm(vec2(world.x / 25.0 + t * 0.6, t * 0.4));
            float line = smoothstep(4.0 + 4.0 * foam, 0.0, depth);
            float glint = smoothstep(14.0, 0.0, depth) * 0.35;
            color = mix(color, vec3(0.88, 0.97, 1.0), clamp(line + glint * foam, 0.0, 1.0));
            alpha = max(alpha, line * 0.95);
        }
        COLOR = vec4(color, alpha);
    }
}
