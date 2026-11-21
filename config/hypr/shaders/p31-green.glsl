#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// Rec. 709 Luminance
float luminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1. Perceptual luminance with slight S-curve contrast boost
    float Y = luminance(pixColor.rgb);
    Y = smoothstep(0.02, 0.98, Y);

    // 2. Base P31 phosphor color ramp (dark unlit phosphor -> vibrant P31 cyan-green)
    vec3 shadowColor = vec3(0.0, 0.02, 0.005);
    vec3 p31Green = vec3(0.18, 1.0, 0.25);
    vec3 col = mix(shadowColor, p31Green, Y);

    // 3. Highlight saturation bloom (phosphor saturating to mint-white)
    if (Y > 0.85) {
        float bloomFactor = smoothstep(0.85, 1.0, Y);
        col = mix(col, vec3(0.85, 1.0, 0.90), bloomFactor * 0.75);
    }

    // 4. Halation / beam scatter: sample 4 cardinal neighbors at +/-2px offset (1920x1200)
    vec2 px = vec2(2.0 / 1920.0, 2.0 / 1200.0);
    float n1 = luminance(texture(tex, v_texcoord + vec2( px.x, 0.0)).rgb);
    float n2 = luminance(texture(tex, v_texcoord + vec2(-px.x, 0.0)).rgb);
    float n3 = luminance(texture(tex, v_texcoord + vec2(0.0,  px.y)).rgb);
    float n4 = luminance(texture(tex, v_texcoord + vec2(0.0, -px.y)).rgb);
    float nAvg = (max(n1 - 0.5, 0.0) + max(n2 - 0.5, 0.0) + max(n3 - 0.5, 0.0) + max(n4 - 0.5, 0.0)) * 0.25;

    col += vec3(0.18, 1.0, 0.25) * (nAvg * 0.25);

    fragColor = vec4(col, pixColor.a);
}
