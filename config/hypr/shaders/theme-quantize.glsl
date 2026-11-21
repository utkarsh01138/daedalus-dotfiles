#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// Catppuccin Mocha 16-color reference palette
const vec3 PALETTE[16] = vec3[16](
    vec3(0.118, 0.118, 0.180), // 0:  Base      #1E1E2E
    vec3(0.094, 0.094, 0.145), // 1:  Mantle    #181825
    vec3(0.067, 0.067, 0.106), // 2:  Crust     #11111B
    vec3(0.192, 0.196, 0.267), // 3:  Surface0  #313244
    vec3(0.271, 0.278, 0.353), // 4:  Surface1  #45475A
    vec3(0.345, 0.357, 0.439), // 5:  Surface2  #585B70
    vec3(0.804, 0.839, 0.957), // 6:  Text      #CDD6F4
    vec3(0.651, 0.678, 0.784), // 7:  Subtext0  #A6ADC8
    vec3(0.953, 0.545, 0.659), // 8:  Red       #F38BA8
    vec3(0.980, 0.702, 0.529), // 9:  Peach     #FAB387
    vec3(0.976, 0.886, 0.686), // 10: Yellow    #F9E2AF
    vec3(0.651, 0.890, 0.631), // 11: Green     #A6E3A1
    vec3(0.580, 0.886, 0.835), // 12: Teal      #94E2D5
    vec3(0.455, 0.780, 0.925), // 13: Sapphire  #74C7EC
    vec3(0.537, 0.706, 0.980), // 14: Blue      #89B4FA
    vec3(0.796, 0.651, 0.969)  // 15: Mauve     #CBA6F7
);

// Perceptually uniform redmean weighted color distance
float redmeanDistSq(vec3 c1, vec3 c2) {
    float rmean = 0.5 * (c1.r + c2.r);
    vec3 d = c1 - c2;
    return (2.0 + rmean) * d.r * d.r + 4.0 * d.g * d.g + (3.0 - rmean) * d.b * d.b;
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 src = pixColor.rgb;

    // Find nearest palette entry
    vec3 bestColor = PALETTE[0];
    float bestDist = redmeanDistSq(src, PALETTE[0]);

    for (int i = 1; i < 16; i++) {
        float d = redmeanDistSq(src, PALETTE[i]);
        if (d < bestDist) {
            bestDist = d;
            bestColor = PALETTE[i];
        }
    }

    // Soft-theme blend: 75% snapped palette + 25% original to preserve photographic recognition
    vec3 col = mix(src, bestColor, 0.75);

    fragColor = vec4(col, pixColor.a);
}
