#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

// Convert RGB to HSL
vec3 rgb2hsl(vec3 c) {
    float cMin = min(min(c.r, c.g), c.b);
    float cMax = max(max(c.r, c.g), c.b);
    float delta = cMax - cMin;
    float l = (cMax + cMin) * 0.5;
    float h = 0.0;
    float s = 0.0;

    if (delta > 0.00001) {
        s = l < 0.5 ? (delta / (cMax + cMin)) : (delta / (2.0 - cMax - cMin));
        if (c.r >= cMax) {
            h = (c.g - c.b) / delta + (c.g < c.b ? 6.0 : 0.0);
        } else if (c.g >= cMax) {
            h = (c.b - c.r) / delta + 2.0;
        } else {
            h = (c.r - c.g) / delta + 4.0;
        }
        h /= 6.0;
    }
    return vec3(h, s, l);
}

// Convert HSL sub-component to RGB
float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0 / 2.0) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

// Convert HSL back to RGB
vec3 hsl2rgb(vec3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;
    if (s <= 0.00001) {
        return vec3(l);
    }
    float q = l < 0.5 ? (l * (1.0 + s)) : (l + s - l * s);
    float p = 2.0 * l - q;
    return vec3(
        hue2rgb(p, q, h + 1.0 / 3.0),
        hue2rgb(p, q, h),
        hue2rgb(p, q, h - 1.0 / 3.0)
    );
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // 1. Convert to HSL
    vec3 hsl = rgb2hsl(pixColor.rgb);

    // 2. Invert ONLY Lightness channel (preserves original hue and color saturation)
    float invL = 1.0 - hsl.z;

    // 3. Compress dynamic range: pure white becomes comfortable #121212, black becomes soft #EAEAEA
    hsl.z = mix(0.07, 0.92, invL);

    // 4. Convert back to RGB
    vec3 outRgb = hsl2rgb(hsl);

    fragColor = vec4(outRgb, pixColor.a);
}
