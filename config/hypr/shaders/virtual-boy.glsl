#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1. Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // 2. Quantize into 4 discrete levels: 0.0, 0.333, 0.667, 1.0
    float q = floor(clamp(Y, 0.0, 0.999) * 4.0) / 3.0;

    // 3. 1995 Virtual Boy oscillating mirror LED line effect
    float scan = 0.88 + 0.12 * sin(gl_FragCoord.y * 3.14159);
    float redOut = q * scan;

    // 4. Strict zero-pass on green and blue (pure night-vision safe monochromatic crimson)
    fragColor = vec4(redOut, 0.0, 0.0, pixColor.a);
}
