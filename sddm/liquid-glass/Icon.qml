import QtQuick
import QtQuick.Shapes

// Biểu tượng nét mảnh từ đường SVG (khung 24×24)
Item {
    id: icon
    property string path: ""
    property real size: 18
    property color color: "#f3f6f6"
    property real stroke: 1.9

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: icon.color
            fillColor: "transparent"
            strokeWidth: icon.stroke
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.path }
        }
    }
}
