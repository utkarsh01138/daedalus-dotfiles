#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// EVA-95 Central Dogma CRT Amber Phosphor Shader:
// Authentic 1995 Sony Trinitron CRT simulation:
// 1200p scanlines + subtle amber phosphor warmth + slight edge vignette
void main() {
    vec4 pix = texture(tex, v_texcoord);
    
    // 1200p horizontal scanlines
    float scanline = sin(v_texcoord.y * 1200.0 * 3.14159265);
    float scanMod = 1.0 - 0.05 * (0.5 + 0.5 * scanline);
    
    vec3 col = pix.rgb * scanMod;
    
    // Warm CRT Amber Phosphor Enhancement
    col.r = min(1.0, col.r * 1.04);
    col.g = min(1.0, col.g * 1.02);
    col.b = col.b * 0.96;
    
    // Subtle CRT corner vignette
    vec2 uv = v_texcoord - 0.5;
    float vign = 1.0 - dot(uv, uv) * 0.22;
    col *= max(0.0, vign);
    
    fragColor = vec4(col, pix.a);
}
