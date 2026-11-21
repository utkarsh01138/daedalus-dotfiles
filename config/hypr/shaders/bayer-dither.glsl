#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// 4x4 Ordered Bayer Matrix
const float bayer[16] = float[16](
     0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
     3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
);

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // Slight gamma boost so dark terminal themes don't crush into solid black
    Y = pow(clamp(Y, 0.0, 1.0), 0.85);

    // Modulo 4 screen coordinates (gl_FragCoord.xy)
    ivec2 coord = ivec2(mod(gl_FragCoord.xy, 4.0));
    int index = coord.y * 4 + coord.x;
    float threshold = bayer[index];

    // 1-Bit quantization: 1.0 if Y >= threshold, else 0.0
    float bw = step(threshold, Y);

    fragColor = vec4(vec3(bw), pixColor.a);
}
