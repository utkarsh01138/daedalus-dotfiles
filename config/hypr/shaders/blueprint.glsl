#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1. Rec. 709 perceptual luminance
    float Y = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));

    // 2. Steep contrast S-curve so text/lines pop against the blueprint substrate
    float curvedY = smoothstep(0.15, 0.85, Y);

    // 3. Color ramp: Deep Prussian Blue -> Mid Architectural Cyan -> Crisp White Ink
    vec3 prussianBlue = vec3(0.0, 0.192, 0.325); // #003153
    vec3 midCyan      = vec3(0.118, 0.376, 0.569); // #1E6091
    vec3 whiteInk     = vec3(0.941, 0.973, 1.0);   // #F0F8FF

    vec3 col;
    if (curvedY < 0.5) {
        col = mix(prussianBlue, midCyan, curvedY * 2.0);
    } else {
        col = mix(midCyan, whiteInk, (curvedY - 0.5) * 2.0);
    }

    // 4. Subtle 1px architectural drafting grid every 32px (6% opacity blend)
    vec2 gridCoord = mod(gl_FragCoord.xy, 32.0);
    if (gridCoord.x < 1.0 || gridCoord.y < 1.0) {
        col = mix(col, whiteInk, 0.06);
    }

    fragColor = vec4(col, pixColor.a);
}
