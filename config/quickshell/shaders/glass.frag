#version 440
// Chất liệu kính cho các viên kính của shell (thanh trên, dock, đảo động, bảng điều khiển...).
//
// Hai lớp, trộn theo `refractAmt` (0 … 1):
//   chất liệu  (luôn có)  màu kính + vệt sáng ở mép phía nguồn sáng + bóng tối nhẹ ở mép trong + vân hạt rất mịn.
//                         Ruột kính trong suốt một phần, nên phần làm mờ của Hyprland phía sau vẫn lộ ra.
//   khúc xạ    (refractAmt)  hình nền phía sau bị bẻ cong ở mép như nhìn qua tấm kính lồi (định luật Snell),
//                         tách màu nhẹ ở viền, làm mờ ở giữa. Chỉ bật khi phía sau là hình nền (không có cửa sổ),
//                         vì shell chỉ có ảnh hình nền, không có ảnh của cửa sổ.
// Thêm: `glowAmt` > 0 thì viền sáng lên ở chỗ gần con trỏ (ô tìm kiếm, nút được rê chuột).
//
// Dựng lại sau khi sửa:  /usr/lib/qt6/bin/qsb --qt6 -o glass.frag.qsb glass.frag
// Cách tính mép cong và khúc xạ học từ liquidglass.frag của MacShell (github.com/0-ss/MacShell, giấy phép MIT).

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;          // cỡ viên kính (px)
    float radius;       // bo góc (px)
    float refractAmt;   // 0 = chỉ chất liệu, 1 = khúc xạ hình nền
    vec4 screenRect;    // x, y của viên kính trên màn hình; rộng, cao của màn hình (px)
    vec4 fit;           // uv hình nền = vị trí trên màn hình / cỡ màn hình * fit.xy + fit.zw (cắt vừa màn hình)
    vec4 tint;          // màu kính (r, g, b, độ đậm), chưa nhân alpha
    float bezel;        // độ rộng mép cong (px)
    float thickness;    // mép cong đẩy hình nền đi bao xa (px)
    float dispersion;   // tách màu ở mép (0 = không)
    float blurLod;      // độ mờ ở ruột kính (mức mipmap)
    float rim;          // độ sáng vệt sáng mép (1 = vừa)
    vec2 glowPos;       // vị trí con trỏ trong viên kính (px)
    float glowAmt;      // 0 … 1
};

layout(binding = 1) uniform sampler2D wall;

float roundBox(vec2 q, vec2 hs, float r)
{
    vec2 d = abs(q) - (hs - r);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 wallAt(vec2 screenPx, float lod)
{
    vec2 uv = screenPx / screenRect.zw * fit.xy + fit.zw;
    return textureLod(wall, clamp(uv, vec2(0.001), vec2(0.999)), lod).rgb;
}

// làm mờ rẻ: vài điểm lấy mẫu xoay vòng, mỗi điểm đọc một mức mipmap đã mờ sẵn
vec3 blurred(vec2 screenPx, float lod, float spread)
{
    const int TAPS = 8;
    float rot = hash12(gl_FragCoord.xy) * 6.2831853;
    vec3 acc = wallAt(screenPx, lod) * 1.5;
    float wsum = 1.5;
    for (int i = 0; i < TAPS; ++i) {
        float a = float(i) * 2.39996323 + rot;
        float r = sqrt((float(i) + 0.5) / float(TAPS));
        vec2 o = vec2(cos(a), sin(a)) * r * spread;
        float w = exp(-2.0 * r * r);
        acc += wallAt(screenPx + o, lod) * w;
        wsum += w;
    }
    return acc / wsum;
}

void main()
{
    vec2 p  = qt_TexCoord0 * size;
    vec2 hs = size * 0.5;
    vec2 q  = p - hs;
    float r = min(radius, min(hs.x, hs.y));

    float sd  = roundBox(q, hs, r);             // < 0: trong viên kính
    float cov = clamp(0.5 - sd, 0.0, 1.0);      // khử răng cưa ở mép
    if (cov <= 0.0) { fragColor = vec4(0.0); return; }

    // khoảng cách tới mép và hướng ra ngoài của mép
    float t = max(-sd, 0.0);
    vec2 d2 = abs(q) - (hs - r);
    vec2 sg = vec2(q.x >= 0.0 ? 1.0 : -1.0, q.y >= 0.0 ? 1.0 : -1.0);
    vec2 m  = max(d2, 0.0);
    vec2 g  = (length(m) > 1e-4) ? normalize(m) * sg
                                 : ((d2.x > d2.y) ? vec2(sg.x, 0.0) : vec2(0.0, sg.y));

    // mép cong kiểu "squircle": càng sát mép càng dốc
    float bz = max(bezel, 1.0);
    float u  = clamp(t / bz, 0.0, 1.0);
    float om = 1.0 - u;
    float slope = min((om * om * om) / pow(max(1.0 - om * om * om * om, 1e-3), 0.75), 7.0);
    vec3 n = normalize(vec3(g * slope, 1.0));

    // ánh sáng từ phía trên bên trái
    vec2 L = normalize(vec2(-0.55, -0.83));
    float facing = dot(g, L);
    float spec = pow(max(facing, 0.0), 1.6) + 0.5 * pow(max(-facing, 0.0), 2.2);
    float hair = exp(-t / 1.1);                 // đường sáng mảnh sát mép
    float wide = exp(-t / 5.0);                 // quầng sáng rộng hơn
    float men  = exp(-pow((t - bz * 0.5) / (bz * 0.2 + 1.0), 2.0));   // vệt sáng thứ hai bên trong mép
    float edgeHi = (hair * (0.16 + 0.70 * spec) + wide * 0.08 * (0.3 + spec) + men * 0.05 * (0.35 + spec)) * rim;

    // viền sáng theo con trỏ
    float gd = length(p - glowPos);
    edgeHi += glowAmt * (hair * 0.9 + wide * 0.25) * exp(-gd * gd / (2.0 * 90.0 * 90.0));

    // mép dưới phía trong hơi tối: kính có độ dày
    float shade = 1.0 - 0.10 * exp(-t / 6.0) * clamp(g.y, 0.0, 1.0);
    float sheen = (1.0 - clamp(p.y / size.y, 0.0, 1.0)) * 0.03;      // phần trên sáng hơn một chút

    float gn = (hash12(gl_FragCoord.xy) + hash12(gl_FragCoord.xy * 1.7 + 17.0) - 1.0) * 0.012;

    // ── lớp chất liệu: màu kính trong suốt một phần ──
    float a0 = tint.a;
    vec3 c0 = tint.rgb * shade + sheen;
    vec4 matl = vec4(c0 * a0, a0);
    matl.rgb += vec3(edgeHi + gn * a0);
    matl.a = clamp(matl.a + edgeHi, 0.0, 1.0);

    vec4 col = matl;
    if (refractAmt > 0.001) {
        // ── lớp khúc xạ: tia đi thẳng vào tấm kính chiết suất ~1,5 ──
        vec3 rd = refract(vec3(0.0, 0.0, -1.0), n, 1.0 / 1.5);
        vec2 disp = rd.xy / max(-rd.z, 0.2) * thickness;
        vec2 sp = screenRect.xy + p;
        float lod = mix(1.0, blurLod, smoothstep(0.0, bz, t));     // mép sắc hơn, ruột mờ hơn
        float spread = mix(2.0, exp2(blurLod) * 1.2, smoothstep(0.0, bz, t));
        vec3 bg;
        bg.r = blurred(sp + disp * (1.0 + dispersion), lod, spread).r;
        bg.g = blurred(sp + disp, lod, spread).g;
        bg.b = blurred(sp + disp * (1.0 - dispersion), lod, spread).b;
        // sắc độ đậm hơn một chút như kính thật
        float l = dot(bg, vec3(0.2126, 0.7152, 0.0722));
        bg = mix(vec3(l), bg, 1.18);
        vec3 c1 = mix(bg, tint.rgb, a0) * shade + sheen + edgeHi + gn;
        col = mix(matl, vec4(clamp(c1, 0.0, 1.0), 1.0), refractAmt);
    }

    fragColor = col * cov * qt_Opacity;
}
