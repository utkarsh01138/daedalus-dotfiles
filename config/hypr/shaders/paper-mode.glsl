#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// Fast deterministic spatial pseudo-random noise generator
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1. Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // 2. 88% Desaturation: keeps 12% subtle color cues for syntax / UI distinction
    vec3 desat = mix(pixColor.rgb, vec3(Y), 0.88);

    // 3. Contrast compression: simulate reflective E-Ink dynamic range (no pure black or pure white)
    vec3 compressed = mix(vec3(0.12), vec3(0.88), desat);

    // 4. Physical paper tint (warm off-white matte substrate)
    vec3 paperBase = vec3(0.96, 0.94, 0.89);
    vec3 paperCol = compressed * paperBase;

    // 5. Deterministic static paper fiber grain (+/- 0.015) based on screen pixel coordinates
    float grain = (hash(gl_FragCoord.xy) - 0.5) * 0.03;
    paperCol = clamp(paperCol + grain, 0.0, 1.0);

    fragColor = vec4(paperCol, pixColor.a);
}
