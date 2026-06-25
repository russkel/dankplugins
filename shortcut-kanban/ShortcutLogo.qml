import QtQuick
import QtQuick.Shapes
import qs.Common

Item {
    id: root
    property color color: Theme.surfaceText
    property real size: 18
    implicitWidth: size
    implicitHeight: size

    Shape {
        id: shape
        width: 1000
        height: 1000
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.width / 1000; yScale: root.height / 1000 }

        ShapePath {
            fillColor: root.color
            strokeWidth: 0
            fillRule: ShapePath.OddEvenFill
            PathSvg {
                path: "M380.781 176.433H830.004L626.623 399.646L826.104 598.544L620.59 824.086L170.004 823.971L374.238 599.823L175.545 401.725L380.781 176.433ZM410.913 636.39L287.815 771.49L546.481 771.554L410.913 636.39ZM608.644 760.375L445.84 598.057L591.698 437.977L754.502 600.307L608.644 760.375ZM555.023 401.411L409.163 561.492L247.144 399.957L392.994 239.852L555.023 401.411ZM589.95 363.077L712.167 228.944H455.423L589.95 363.077Z"
            }
        }
    }
}
