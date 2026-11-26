//
//  Ocean.metal
//  DeepBlueWeather
//
//  Two stitchable shaders that draw a semi-realistic sea.
//    oceanSurface — perspective view across the water (sky, sun/moon, waves)
//    waterline    — side-on cross section (sky above, light shafts below)
//  Every visual parameter comes from real forecast data (see SeaState).
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: Noise

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float vnoise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + float2(1, 0)), u.x),
               mix(hash21(i + float2(0, 1)), hash21(i + float2(1, 1)), u.x), u.y);
}

static float fbm(float2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) { v += a * vnoise(p); p = p * 2.03 + 11.7; a *= 0.5; }
    return v;
}

// MARK: Sky

struct Light { float day; float gold; float night; float cloud; };

static Light makeLight(float sunElev, float cloud) {
    Light l;
    l.day = smoothstep(-0.10, 0.30, sunElev);
    l.gold = exp(-pow((sunElev - 0.04) / 0.17, 2.0));
    l.night = 1.0 - smoothstep(-0.22, 0.02, sunElev);
    l.cloud = cloud;
    return l;
}

static float3 skyColor(float3 rd, float3 sunDir, Light l, float time, float disk) {
    float h = clamp(rd.y * 2.6, 0.0, 1.0);

    float3 zen = mix(float3(0.016, 0.034, 0.085), float3(0.06, 0.27, 0.55), l.day);
    float3 hor = mix(float3(0.085, 0.155, 0.27), float3(0.55, 0.74, 0.86), l.day);
    zen = mix(zen, float3(0.13, 0.17, 0.37), l.gold * 0.75);
    hor = mix(hor, float3(0.98, 0.55, 0.30), l.gold * 0.85);
    float3 col = mix(hor, zen, pow(h, 0.62));

    float sd = max(dot(rd, sunDir), 0.0);
    float3 sunTint = mix(float3(1.0, 0.95, 0.84), float3(1.0, 0.58, 0.26), l.gold);
    sunTint = mix(sunTint, float3(0.72, 0.82, 1.0), l.night);
    float clear = max(pow(1.0 - l.cloud * 0.92, 2.0), 0.28 * l.night);

    // Halo around sun or moon
    col += sunTint * (pow(sd, 90.0) * 0.35 + pow(sd, 9.0) * 0.12) * clear * mix(1.0, 0.55, l.night);
    // Disk
    float radius = mix(0.99975, 0.99955, l.night);
    col += sunTint * smoothstep(radius, radius + 0.00006, sd) * disk * clear * mix(1.4, 0.95, l.night);

    // Stars
    if (l.night > 0.01 && rd.y > 0.015) {
        float2 sp = float2(rd.x, rd.y) / max(rd.z, 0.2) * 190.0;
        float2 cell = floor(sp);
        float r = hash21(cell);
        if (r > 0.975) {
            float2 c = cell + 0.5 + (float2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5) * 0.6;
            float tw = 0.75 + 0.25 * sin(time * 0.9 + r * 80.0);
            col += float3(0.85, 0.9, 1.0) * smoothstep(0.34, 0.0, length(sp - c)) * tw * l.night * clear;
        }
    }

    // Clouds: thin wisps on clear days, a grey deck when rain is likely
    float2 cp = float2(rd.x / (rd.y + 0.12), 1.0 / (rd.y + 0.12));
    float n = fbm(cp * float2(1.1, 0.55) + float2(time * 0.012, 0.0));
    float cover = smoothstep(mix(0.62, 0.24, l.cloud), mix(0.95, 0.72, l.cloud), n);
    float3 cloudCol = mix(float3(0.095, 0.135, 0.205), float3(0.86, 0.89, 0.93), l.day);
    cloudCol = mix(cloudCol, float3(0.95, 0.6, 0.45), l.gold * 0.6);
    cloudCol = mix(cloudCol, cloudCol * float3(0.46, 0.50, 0.56) * (0.75 + 0.5 * n), l.cloud);
    float overcast = mix(0.35, 0.95, l.cloud);
    col = mix(col, cloudCol, cover * overcast * smoothstep(0.0, 0.08, rd.y));
    col = mix(col, cloudCol * 0.95, l.cloud * l.cloud * 0.45);
    return col;
}

// MARK: Surface view

static float swellHeight(float2 p, float time, float height, float chop, int octaves) {
    // Long swell follows measured wave height; short ripples follow the wind.
    const float2 dirs[6] = { float2(0.18, 1.0), float2(-0.45, 0.9), float2(0.72, 0.7),
                             float2(-0.9, 0.45), float2(0.35, 0.94), float2(-0.2, 0.98) };
    const float lengths[6] = { 19.0, 11.0, 6.4, 3.5, 1.9, 1.05 };
    float swell = 0.04 + height * 0.40;
    float wind = 0.004 + chop * 0.075;
    const float swellW[6] = { 0.62, 0.34, 0.18, 0.05, 0.0, 0.0 };
    const float windW[6]  = { 0.0, 0.1, 0.45, 0.9, 0.65, 0.4 };
    float h = 0.0;
    for (int i = 0; i < octaves; i++) {
        float2 d = normalize(dirs[i]);
        float k = 6.28318 / lengths[i];
        float w = sqrt(9.8 * k) * 0.55;
        float warp = vnoise(p * (k * 0.11) + float(i) * 7.3) * 4.6;
        float th = dot(d, p) * k + time * w + warp;
        // Peaked crests, flat troughs
        float s = 1.0 - abs(sin(th * 0.5));
        s = mix(sin(th) * 0.5 + 0.5, s * s, clamp(0.25 + height * 0.3, 0.0, 0.85));
        h += (s - 0.4) * 2.0 * (swell * swellW[i] + wind * windW[i]);
    }
    return h;
}

[[ stitchable ]] half4 oceanSurface(float2 position, half4 color, float4 bounds,
                                    float time, float horizon, float waveHeight,
                                    float chop, float sunElev, float cloud) {
    float2 size = bounds.zw;
    float2 uv = (position - bounds.xy) / size;
    float aspect = size.x / size.y;
    const float fov = 1.05;

    Light l = makeLight(sunElev, cloud);
    float lightElev = l.night > 0.5 ? 0.17 : max(sunElev * 0.34, 0.015);
    float3 sunDir = normalize(float3(0.20, lightElev, 1.0));

    float3 rd = normalize(float3((uv.x - 0.5) * aspect * fov, (horizon - uv.y) * fov, 1.0));
    float camH = 3.4;
    float3 col;
    float top = waveHeight * 0.6 + 0.3;

    // March the height field
    float tHit = -1.0;
    if (rd.y < (top > camH ? 0.2 : 0.012)) {
        float t = rd.y < -0.001 ? max((camH - top) / -rd.y, 0.2) : 2.0;
        float prevT = t;
        for (int i = 0; i < 90; i++) {
            float3 p = float3(0, camH, 0) + rd * t;
            float d = p.y - swellHeight(p.xz, time, waveHeight, chop, 4);
            if (d < 0.0) {
                float a = prevT, b = t;
                for (int j = 0; j < 6; j++) {
                    float m = (a + b) * 0.5;
                    float3 q = float3(0, camH, 0) + rd * m;
                    if (q.y - swellHeight(q.xz, time, waveHeight, chop, 4) < 0.0) b = m; else a = m;
                }
                tHit = (a + b) * 0.5;
                break;
            }
            prevT = t;
            t += max(d * 0.55, 0.04 + t * 0.012);
            if (t > 260.0) break;
        }
        if (tHit < 0.0 && rd.y < -0.004) tHit = camH / -rd.y;
    }

    if (tHit < 0.0) {
        col = skyColor(rd, sunDir, l, time, 1.0);
    } else {
        float3 p = float3(0, camH, 0) + rd * tHit;
        float e = 0.03 + tHit * 0.004;
        float h0 = swellHeight(p.xz, time, waveHeight, chop, 6);
        float hx = swellHeight(p.xz + float2(e, 0), time, waveHeight, chop, 6);
        float hz = swellHeight(p.xz + float2(0, e), time, waveHeight, chop, 6);
        float3 n = normalize(float3(h0 - hx, e, h0 - hz));

        // Fine ripples
        float2 rp = p.xz * 2.3 + float2(time * 0.35, time * 0.55);
        float r0 = fbm(rp);
        float2 rg = float2(fbm(rp + float2(0.15, 0)) - r0, fbm(rp + float2(0, 0.15)) - r0);
        float ripple = (0.12 + chop * 0.55) / (1.0 + tHit * 0.06);
        n = normalize(n + float3(-rg.x, 0, -rg.y) * ripple * 2.2);
        n = normalize(mix(n, float3(0, 1, 0), smoothstep(20.0, 200.0, tHit) * 0.75));

        float3 refl = reflect(rd, n);
        refl.y = abs(refl.y);
        float fres = 0.03 + 0.97 * pow(1.0 - clamp(dot(n, -rd), 0.0, 1.0), 5.0);

        float3 deep = mix(float3(0.008, 0.028, 0.055), float3(0.008, 0.105, 0.16), l.day);
        deep = mix(deep, float3(0.05, 0.06, 0.11), l.gold * 0.6);
        deep = mix(deep, deep * float3(0.65, 0.78, 0.74), cloud);
        float3 scatter = mix(float3(0.0, 0.035, 0.05), float3(0.0, 0.30, 0.30), l.day) * (1.0 - cloud * 0.55);
        float crest = clamp(h0 / (top + 0.05) + 0.35, 0.0, 1.0);
        float3 body = deep + scatter * crest * crest * (0.35 + 0.65 * max(n.z * -1.0 + 0.3, 0.0));

        col = mix(body, skyColor(refl, sunDir, l, time, 0.0), fres);

        // Glitter path
        float3 sunTint = mix(float3(1.0, 0.92, 0.75), float3(1.0, 0.52, 0.22), l.gold);
        sunTint = mix(sunTint, float3(0.65, 0.78, 1.0), l.night);
        float sd = max(dot(refl, sunDir), 0.0);
        col += sunTint * (pow(sd, 420.0) * 2.4 + pow(sd, 60.0) * 0.16) * (1.0 - cloud * mix(0.9, 0.6, l.night))
               * mix(1.0, 0.75, l.night);

        // Whitecaps only when the sea is actually rough
        float rough = clamp((waveHeight - 0.8) / 0.9 + (chop - 0.45) * 0.9, 0.0, 1.0);
        if (rough > 0.0) {
            float f = fbm(p.xz * 1.7 + float2(time * 0.3, time * 0.2));
            float foam = smoothstep(0.55, 0.92, crest + (f - 0.5) * 0.9) * smoothstep(0.38, 0.7, fbm(p.xz * 5.0 - time * 0.2));
            col = mix(col, mix(float3(0.12, 0.15, 0.2), float3(0.80, 0.85, 0.88), l.day), foam * rough);
        }

        // Aerial perspective toward the horizon
        float3 horizonCol = skyColor(normalize(float3(rd.x, 0.012, rd.z)), sunDir, l, time, 0.0);
        col = mix(col, horizonCol, smoothstep(35.0, 240.0, tHit) * 0.92);
    }

    col += (hash21(position) - 0.5) / 255.0;
    return half4(half3(saturate(col)), 1.0h);
}

// MARK: Cross-section view

[[ stitchable ]] half4 waterline(float2 position, half4 color, float4 bounds,
                                 float time, float surfaceY, float pointsPerMetre,
                                 float waveHeight, float chop, float sunElev, float cloud) {
    float2 size = bounds.zw;
    float2 pt = position - bounds.xy;
    Light l = makeLight(sunElev, cloud);
    // Low and right of centre, clear of the text above the waterline
    float3 sunDir = normalize(float3(0.13, l.night > 0.5 ? 0.085 : max(sunElev * 0.095, 0.012), 1.0));

    float amp = max(waveHeight * 0.5 * pointsPerMetre, 1.2);
    float x = pt.x;
    float wave = sin(x * 0.019 + time * 0.9) * 0.72
               + sin(x * 0.037 - time * 1.25 + 1.7) * 0.28;
    float ripple = (vnoise(float2(x * 0.09 + time * 1.6, time * 0.5)) - 0.5) * chop * 9.0;
    float line = surfaceY + wave * amp + ripple;
    float depth = pt.y - line;

    // Sky, seen level with the water
    float3 rd = normalize(float3((pt.x - size.x * 0.5) * 0.0015, max(surfaceY - pt.y, 0.0) * 0.0015, 1.0));
    float3 sky = skyColor(rd, sunDir, l, time, 1.0);

    // Water column: red light is absorbed first, so colour shifts to blue then black
    float d = clamp(depth / max(size.y - surfaceY, 1.0), 0.0, 1.0);
    float3 shallow = mix(float3(0.030, 0.140, 0.230), float3(0.02, 0.43, 0.52), l.day);
    shallow = mix(shallow, float3(0.10, 0.20, 0.30), l.gold * 0.6);
    shallow = mix(shallow, shallow * float3(0.55, 0.68, 0.66), cloud);
    float3 mid = mix(float3(0.012, 0.060, 0.120), float3(0.012, 0.17, 0.31), l.day);
    float3 abyssCol = float3(0.006, 0.028, 0.058);
    float3 water = mix(shallow, mid, smoothstep(0.0, 0.48, d));
    water = mix(water, abyssCol, smoothstep(0.38, 1.0, d));

    // Light shafts
    float sx = (pt.x - size.x * 0.68) / (max(depth, 0.0) + 230.0);
    float rays = vnoise(float2(sx * 17.0 + time * 0.12, 1.0)) * vnoise(float2(sx * 39.0 - time * 0.09, 4.0));
    float3 rayTint = mix(float3(0.25, 0.4, 0.65), float3(0.55, 0.95, 0.9), l.day);
    water += rayTint * pow(rays, 1.6) * (1.0 - d) * (1.0 - d) * mix(0.18, 0.55, l.day) * (1.0 - cloud * 0.75);

    // Drifting particles
    float2 g = pt / 26.0 + float2(sin(time * 0.15) * 0.3, time * 0.07);
    float2 cell = floor(g);
    float r = hash21(cell);
    if (r > 0.82) {
        float2 c = cell + 0.2 + 0.6 * float2(hash21(cell + 2.0), hash21(cell + 9.0));
        water += float3(0.5, 0.7, 0.75) * smoothstep(0.075, 0.0, length(g - c)) * 0.35 * (1.0 - d * 0.5);
    }

    // Bright underside and foam at the interface
    water += rayTint * exp(-max(depth, 0.0) / 9.0) * mix(0.16, 0.38, l.day);
    float3 col = mix(sky, water, smoothstep(-0.8, 0.8, depth));
    float rough = clamp((waveHeight - 0.8) / 1.2 + (chop - 0.4), 0.0, 1.0);
    float foamBand = exp(-abs(depth) / (1.0 + rough * 7.0));
    float foamNoise = fbm(float2(x * 0.08 + time, pt.y * 0.14));
    col = mix(col, mix(float3(0.35, 0.45, 0.58), float3(0.92, 0.97, 0.98), l.day),
              saturate(foamBand * (0.35 + rough * foamNoise * 1.3)));

    col += (hash21(position) - 0.5) / 255.0;
    return half4(half3(saturate(col)), 1.0h);
}
