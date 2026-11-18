import QtQuick
import QtQuick.Shapes

//
Shape {
    id: corner

    property string side: "left"
    property color fill: "#000000"
    property real r: 12

    width: corner.r
    height: corner.r
    clip: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: corner.fill
        strokeWidth: 0
        strokeColor: "transparent"

        startX: corner.side === "left" ? 0 : corner.r
        startY: 0

        PathLine { x: corner.side === "left" ? corner.r : 0; y: 0 }
        PathLine { x: corner.side === "left" ? corner.r : 0; y: corner.r }
        PathArc {
            x: corner.side === "left" ? 0 : corner.r
            y: 0
            radiusX: corner.r
            radiusY: corner.r
            useLargeArc: false
            direction: corner.side === "left" ? PathArc.Counterclockwise
                                              : PathArc.Clockwise
        }
    }
}
