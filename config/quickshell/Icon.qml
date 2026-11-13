import QtQuick
import QtQuick.Shapes

// Biểu tượng nét mảnh vẽ từ đường SVG (khung 24×24), không phụ thuộc bộ icon hệ thống.
//   Icon { path: Icons.wifi; size: 18; color: Theme.fg }
Item {
    id: icon

    property string path: ""
    property real size: 18
    property color color: Theme.fg
    property real stroke: 1.9
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: icon.filled ? "transparent" : icon.color
            fillColor: icon.filled ? icon.color : "transparent"
            strokeWidth: icon.filled ? 0 : icon.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.path }
        }
    }
}
