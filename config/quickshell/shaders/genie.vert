#version 440
// Hiệu ứng "genie" khi thu nhỏ cửa sổ vào dock: cửa sổ bị hút vào biểu tượng của nó như khói vào cây đèn thần.
//
// Ảnh chụp cửa sổ được vẽ trên một lưới nhiều hàng (GridMesh), nên từng hàng co và rơi riêng:
//   - đầu tiên hai bên cửa sổ cong dần về phía biểu tượng, cong nhiều nhất ở phía gần dock
//   - sau đó từng hàng trượt xuống biểu tượng, hàng dưới đi trước, đỉnh cửa sổ theo sau
// progress 0 = cửa sổ ở chỗ cũ, 1 = đã vào hẳn dock. Hiện lại thì chạy ngược.
//
// Dựng lại sau khi sửa:  /usr/lib/qt6/bin/qsb --qt6 -o genie.vert.qsb genie.vert
// Cách chia hai pha học từ genie.vert của MacShell (github.com/0-ss/MacShell, giấy phép MIT).
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec4 win;       // cửa sổ:   x, y, rộng, cao (toạ độ của lớp phủ = toạ độ màn hình)
    vec4 target;    // biểu tượng trên dock, cùng cách ghi
    float radius;   // bo góc cửa sổ (px)
};

void main()
{
    vec2 uv = qt_MultiTexCoord0;
    float p = clamp(progress, 0.0, 1.0);

    float bend = smoothstep(0.0, 0.42, p);      // pha 1: hai bên cong lại
    float fall = smoothstep(0.22, 1.0, p);      // pha 2: các hàng rơi vào dock

    // dock ở dưới cửa sổ: hàng dưới đi trước. Dock ở trên (hiếm) thì hàng trên đi trước.
    bool down = target.y >= win.y;
    float lead = down ? (1.0 - uv.y) : uv.y;
    float rowT = clamp(fall * 1.4 - lead * 0.4, 0.0, 1.0);
    rowT = rowT * rowT * (3.0 - 2.0 * rowT);

    float y0 = win.y + uv.y * win.w;
    float y1 = target.y + uv.y * target.w;
    float y  = mix(y0, y1, rowT);

    // hàng càng gần dock càng bị bóp hẹp: hai bên cửa sổ thành đường cong mềm
    float top = down ? win.y : target.y + target.w;
    float span = max(1.0, down ? (target.y + target.w) - win.y : (win.y + win.w) - target.y);
    float k = clamp((y - top) / span, 0.0, 1.0);
    if (!down) k = 1.0 - k;
    float squeeze = clamp(bend * smoothstep(0.0, 1.0, k) * 0.92 + rowT, 0.0, 1.0);

    float left  = mix(win.x, target.x, squeeze);
    float right = mix(win.x + win.z, target.x + target.z, squeeze);
    float x = mix(left, right, uv.x);

    qt_TexCoord0 = uv;
    gl_Position = qt_Matrix * vec4(x, y, 0.0, 1.0);
}
