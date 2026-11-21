#version 300 es

precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1200 vertical resolution on Hal (1920x1200)
    float scanline = sin(v_texcoord.y * 1200.0 * 3.14159) * 0.08;
    vec3 crtColor = pixColor.rgb - scanline;

    // Subtle phosphor shift
    crtColor.r *= 1.04;
    crtColor.b *= 0.94;

    // Subtle edge vignette
    vec2 uv = v_texcoord * (1.0 - v_texcoord.yx);
    float vignette = uv.x * uv.y * 15.0;
    vignette = clamp(pow(vignette, 0.15), 0.0, 1.0);
    crtColor *= vignette;

    fragColor = vec4(crtColor, pixColor.a);
}
