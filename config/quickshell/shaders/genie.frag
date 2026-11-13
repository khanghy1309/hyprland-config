#version 440
// Tô ảnh chụp cửa sổ lên lưới của genie.vert. Khối uniform phải giống hệt bên genie.vert.
// Bo góc theo cửa sổ thật (ảnh chụp của Hyprland là hình chữ nhật), đoạn cuối mờ dần để đầu nhọn không thành sợi.
//
// Dựng lại sau khi sửa:  /usr/lib/qt6/bin/qsb --qt6 -o genie.frag.qsb genie.frag
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec4 win;
    vec4 target;
    float radius;
};

layout(binding = 1) uniform sampler2D source;

void main()
{
    vec4 c = texture(source, qt_TexCoord0);
    // bo góc trong toạ độ của cửa sổ gốc
    vec2 hs = win.zw * 0.5;
    vec2 q = qt_TexCoord0 * win.zw - hs;
    float r = min(radius, min(hs.x, hs.y));
    vec2 d = abs(q) - (hs - r);
    float sd = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
    float cov = clamp(0.5 - sd, 0.0, 1.0);
    float tail = 1.0 - smoothstep(0.80, 1.0, progress) * 0.85;
    fragColor = c * cov * tail * qt_Opacity;
}
