#version 440
// Thông báo tan thành bụi khi xoá: tấm thẻ vỡ thành những hạt rất nhỏ bay lên phía trên bên phải rồi tan,
// theo một làn sóng quét từ trái sang phải. Vùng vẽ rộng hơn tấm thẻ (thêm `pad` ở bên phải và phía trên)
// để bụi có chỗ bay.
//
// Cách vẽ: mỗi điểm ảnh tự hỏi "hạt nào đang bay tới chỗ mình?" — đoán vị trí gốc rồi chỉnh lại vài lần
// (đường bay của mỗi hạt chỉ phụ thuộc vị trí gốc của nó), sau đó lấy màu của hạt đó ở tấm thẻ gốc.
// Dựng lại sau khi sửa:  /usr/lib/qt6/bin/qsb --qt6 -o dust.frag.qsb dust.frag
// Ý tưởng từ dust.frag của MacShell (github.com/0-ss/MacShell, giấy phép MIT).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;     // 0 = nguyên vẹn, 1 = tan hết
    vec2 cardSize;      // cỡ tấm thẻ (px)
    vec2 pad;           // chỗ thêm cho bụi: bên phải (x) và phía trên (y), px
};

layout(binding = 1) uniform sampler2D source;   // ảnh của cả vùng vẽ (thẻ nằm ở (0, pad.y))

const float S = 3.0;    // cỡ một hạt (px)

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Mỗi hạt thuộc một trong G nhóm (chọn ngẫu nhiên theo ô). Trong một nhóm, lúc bắt đầu bay và đường bay
// đổi mượt theo vị trí, nên với từng nhóm có thể lần ngược "hạt nào bay tới đây" một cách chắc chắn.
const int G = 4;
int groupOf(vec2 cell) { return int(floor(hash12(cell) * float(G))); }

float lifeAt(vec2 o, int g)
{
    float x = o.x / cardSize.x;
    float start = 0.5 * x + 0.06 * float(g) + 0.04 * sin(o.y * 0.07 + float(g));
    return clamp((progress - start) / 0.42, 0.0, 1.0);
}
vec2 driftAt(vec2 o, float l, int g)
{
    float fg = float(g);
    vec2 dir = normalize(vec2(1.0, -0.55 - 0.18 * fg - 0.25 * sin(o.x * 0.013 + fg)));
    float travel = (0.45 + 0.14 * fg + 0.12 * sin(o.y * 0.05 + o.x * 0.011)) * min(pad.x, pad.y * 1.6);
    float wob = sin(l * 5.0 + fg * 1.7 + o.x * 0.02) * 5.0 * l;
    return dir * travel * pow(l, 1.4) + vec2(-dir.y, dir.x) * wob;
}

void main()
{
    vec2 area = cardSize + pad;
    vec2 p = qt_TexCoord0 * area;
    vec2 c = p - vec2(0.0, pad.y);              // toạ độ trong tấm thẻ

    vec4 col = vec4(0.0);
    // phần thẻ chưa vỡ
    if (c.x >= 0.0 && c.y >= 0.0 && c.x < cardSize.x && c.y < cardSize.y) {
        vec2 cell = floor(c / S);
        vec2 ctr = (cell + 0.5) * S;
        if (lifeAt(ctr, groupOf(cell)) <= 0.0) col = texture(source, qt_TexCoord0);
    }
    // với từng nhóm: lần ngược vị trí gốc rồi xem quanh đó có hạt nào của nhóm phủ lên điểm này không
    for (int g = 0; g < G; ++g) {
        vec2 o = c;
        for (int i = 0; i < 4; ++i) o = c - driftAt(o, lifeAt(o, g), g);
        vec2 base = floor(o / S);
        for (int dy = -1; dy <= 1; ++dy)
        for (int dx = -1; dx <= 1; ++dx) {
            vec2 cell = base + vec2(dx, dy);
            if (cell.x < 0.0 || cell.y < 0.0 || cell.x * S >= cardSize.x || cell.y * S >= cardSize.y) continue;
            if (groupOf(cell) != g) continue;
            vec2 ctr = (cell + 0.5) * S;
            float l = lifeAt(ctr, g);
            if (l <= 0.0) continue;
            vec2 at = ctr + driftAt(ctr, l, g);
            float rad = S * 0.62 * (1.0 - 0.5 * l);
            float d = length(c - at);
            if (d < rad) {
                vec4 sc = texture(source, (ctr + vec2(0.0, pad.y)) / area);
                float a = (1.0 - smoothstep(rad - 0.8, rad, d)) * pow(1.0 - l, 1.2);
                col = max(col, sc * a);
            }
        }
    }
    fragColor = col * qt_Opacity;
}
