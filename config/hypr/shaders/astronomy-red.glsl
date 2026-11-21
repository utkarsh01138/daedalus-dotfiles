#version 300 es

precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Standard human perception luminance: 0.299 R + 0.587 G + 0.114 B
    float lum = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));

    // Preserve dominant red or use mapped luminance
    float redIntensity = max(pixColor.r, lum);

    // Strict zero-pass for Green and Blue channels
    fragColor = vec4(redIntensity * 0.85, 0.0, 0.0, pixColor.a);
}
