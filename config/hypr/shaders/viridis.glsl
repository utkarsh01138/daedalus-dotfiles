#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// 6th-degree polynomial approximation of Matplotlib Viridis colormap
vec3 viridis(float t) {
    t = clamp(t, 0.0, 1.0);
    const vec3 c0 = vec3(0.2777, 0.0055, 0.3341);
    const vec3 c1 = vec3(0.1051, 1.4046, 1.3846);
    const vec3 c2 = vec3(-0.3309, 0.2149, 0.0951);
    const vec3 c3 = vec3(-4.6342, -5.7292, -5.7709);
    const vec3 c4 = vec3(6.2283, 14.1297, 10.5412);
    const vec3 c5 = vec3(4.7764, -14.6469, -10.9671);
    const vec3 c6 = vec3(-5.4354, 4.6076, 4.4172);
    return clamp(c0 + t*(c1 + t*(c2 + t*(c3 + t*(c4 + t*(c5 + t*c6))))), 0.0, 1.0);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    vec3 col = viridis(Y);

    fragColor = vec4(col, pixColor.a);
}
