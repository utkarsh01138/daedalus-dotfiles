#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Soft-knee true-black thresholding:
    // Pixels below Y=0.02 snap to pure #000000.
    // Pixels between 0.02 and 0.08 transition smoothly without harsh edge banding.
    // Pixels above 0.08 remain 100% untouched and color-accurate.
    float factor = smoothstep(0.02, 0.08, Y);

    vec3 col = pixColor.rgb * factor;

    fragColor = vec4(col, pixColor.a);
}
