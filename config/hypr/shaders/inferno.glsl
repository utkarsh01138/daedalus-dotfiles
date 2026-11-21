#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// 6th-degree polynomial approximation of Matplotlib Inferno colormap
vec3 inferno(float t) {
    t = clamp(t, 0.0, 1.0);
    const vec3 c0 = vec3(0.0002, 0.0016, -0.0194);
    const vec3 c1 = vec3(0.1065, 0.5639, 3.9327);
    const vec3 c2 = vec3(11.6024, -3.9728, -15.9423);
    const vec3 c3 = vec3(-41.7039, 17.4363, 44.3541);
    const vec3 c4 = vec3(77.1629, -33.4023, -81.8073);
    const vec3 c5 = vec3(-71.3194, 32.6260, 73.2095);
    const vec3 c6 = vec3(25.1311, -12.2426, -23.0703);
    return clamp(c0 + t*(c1 + t*(c2 + t*(c3 + t*(c4 + t*(c5 + t*c6))))), 0.0, 1.0);
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    vec3 col = inferno(Y);

    fragColor = vec4(col, pixColor.a);
}
