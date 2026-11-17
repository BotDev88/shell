import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

// Sylvie: the logo button. A 38px orange disc with a cream four-point sparkle, a walnut inner
// ring and a thin orange outer ring (design/SylvieBar.dc.html). Opens the launcher.
Item {
    id: root

    readonly property int size: 38

    implicitWidth: size + 4
    implicitHeight: size + 4

    // outer ring: 1.5px orange, just outside the disc
    Rectangle {
        anchors.centerIn: parent
        width: root.size + 3
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1.5
        border.color: Colours.palette.m3primary
    }

    // the disc, with a 2px walnut inner ring
    Rectangle {
        id: disc

        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: root.size / 2
        color: Colours.palette.m3primary
        border.width: 2
        border.color: Colours.palette.m3surface

        scale: mouse.pressed ? 0.92 : mouse.containsMouse ? 1.05 : 1

        Behavior on scale {
            Anim {}
        }

        // four-point sparkle, 22px (same path as the mockup's SVG, 24-unit box)
        Shape {
            anchors.centerIn: parent
            width: 22
            height: 22
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: Colours.palette.m3onSurface
                scale: Qt.size(22 / 24, 22 / 24)

                PathSvg {
                    path: "M12 0L13.6 10.4L24 12L13.6 13.6L12 24L10.4 13.6L0 12L10.4 10.4Z"
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.launcher = !screenState.launcher;
        }
    }
}
