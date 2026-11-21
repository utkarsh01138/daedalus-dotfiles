#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// NERV Tactical Command Shader:
// Subtle tactical CRT scanlines + warm phosphor tint + mild edge darkening
void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    
    // Subtle horizontal scanline pass matched to 1200p
    float scanline = sin(v_texcoord.y * 1200.0 * 3.14159265);
    float scanMod = 1.0 - 0.04 * (0.5 + 0.5 * scanline);
    
    // Warm tactical phosphor enhancement (slight boost to red/green amber spectrum)
    vec3 col = pixColor.rgb * scanMod;
    col.r = min(1.0, col.r * 1.03);
    col.g = min(1.0, col.g * 1.01);
    
    // Soft subtle vignette
    vec2 uv = v_texcoord - 0.5;
    float vign = 1.0 - dot(uv, uv) * 0.15;
    col *= vign;
    
    fragColor = vec4(col, pixColor.a);
}
