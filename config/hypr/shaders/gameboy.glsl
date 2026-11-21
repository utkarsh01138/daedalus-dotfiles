#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// Authentic 1989 Nintendo Game Boy DMG-01 4-shade olive-green LCD palette
const vec3 GB_PALETTE[4] = vec3[4](
    vec3(0.059, 0.220, 0.059), // Shade 0: #0F380F (Darkest)
    vec3(0.188, 0.384, 0.188), // Shade 1: #306230 (Dark)
    vec3(0.545, 0.675, 0.059), // Shade 2: #8BAC0F (Light)
    vec3(0.608, 0.737, 0.059)  // Shade 3: #9BBC0F (Lightest)
);

// 2x2 Bayer Matrix for subtle sub-banding dither
const float bayer2[4] = float[4](
    0.0/4.0, 2.0/4.0,
    3.0/4.0, 1.0/4.0
);

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1. Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // 2. 2x2 Bayer dither jitter (+/- 0.075) to prevent flat color banding
    ivec2 coord2 = ivec2(mod(gl_FragCoord.xy, 2.0));
    float dither = (bayer2[coord2.y * 2 + coord2.x] - 0.5) * 0.15;
    float ditheredY = clamp(Y + dither, 0.0, 0.999);

    // 3. 4-level quantization
    int idx = int(clamp(floor(ditheredY * 4.0), 0.0, 3.0));
    vec3 col = GB_PALETTE[idx];

    // 4. Dot-matrix reflective LCD sub-cell gap simulation (darken grid borders by 8%)
    if (mod(gl_FragCoord.x, 3.0) < 1.0 || mod(gl_FragCoord.y, 3.0) < 1.0) {
        col *= 0.92;
    }

    fragColor = vec4(col, pixColor.a);
}
