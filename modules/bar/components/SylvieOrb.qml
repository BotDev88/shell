import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services

// Sylvie: the orb under the logo (approved mockup "Sylvie Orb and Chat", 18 Nov 2026).
// idle = dim core · listening = gold pulse + mic badge (the mic-on state is always visible) ·
// thinking = an orange arc orbiting · speaking = orange ripples · offline = hollow, dim.
// Click: open or close the chat drawer.
Item {
    id: root

    readonly property string state: Sylvie.state
    readonly property int size: 44
    readonly property color gold: Colours.palette.m3secondary
    readonly property color orange: Colours.palette.m3primary

    implicitWidth: size + 2
    implicitHeight: size + 2

    Rectangle {
        id: body

        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: width / 2
        color: Colours.palette.m3surfaceContainer
        border.width: 1.5
        border.color: root.state === "listening" ? root.gold : root.state === "speaking" ? root.orange : Colours.palette.m3outlineVariant
        scale: mouse.pressed ? 0.92 : mouse.containsMouse ? 1.05 : 1

        Behavior on scale {
            Anim {}
        }

        // listening: two gold rings pulse outwards; speaking: two orange ripples
        Repeater {
            model: 2

            Rectangle {
                id: ring

                required property int index
                readonly property bool on: root.state === "listening" || root.state === "speaking"

                anchors.centerIn: parent
                width: parent.width
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: root.state === "listening" ? root.gold : root.orange
                visible: on
                opacity: 0

                SequentialAnimation {
                    running: ring.on
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: ring.index * (root.state === "listening" ? 800 : 650)
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: ring
                            property: "scale"
                            from: root.state === "listening" ? 0.7 : 0.45
                            to: root.state === "listening" ? 1.55 : 1.35
                            duration: root.state === "listening" ? 1600 : 1300
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: ring
                            property: "opacity"
                            from: 0.9
                            to: 0
                            duration: root.state === "listening" ? 1600 : 1300
                        }
                    }
                }
            }
        }

        // thinking: an orange quarter-arc orbiting the core
        Shape {
            id: arc

            anchors.fill: parent
            visible: root.state === "thinking"
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: root.orange
                strokeWidth: 2.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: arc.width / 2
                    centerY: arc.height / 2
                    radiusX: arc.width / 2 - 1.5
                    radiusY: arc.height / 2 - 1.5
                    startAngle: -90
                    sweepAngle: 100
                }
            }

            RotationAnimation on rotation {
                running: arc.visible
                from: 0
                to: 360
                duration: 1100
                loops: Animation.Infinite
            }
        }

        Rectangle {
            id: core

            anchors.centerIn: parent
            width: 14
            height: 14
            radius: 7
            color: root.state === "listening" ? root.gold : root.state === "idle" || root.state === "offline" ? Colours.palette.m3onSurface : root.orange
            opacity: root.state === "idle" ? 0.35 : root.state === "offline" ? 0 : 1

            Behavior on color {
                CAnim {}
            }
        }

        // offline (sylvied isn't running): a hollow, dim core
        Rectangle {
            visible: root.state === "offline"
            anchors.centerIn: parent
            width: 14
            height: 14
            radius: 7
            color: "transparent"
            border.width: 1.5
            border.color: Colours.palette.m3onSurfaceVariant
        }
    }

    // mic badge: the microphone is on
    Rectangle {
        visible: root.state === "listening"
        anchors.right: body.right
        anchors.bottom: body.bottom
        anchors.margins: -3
        width: 18
        height: 18
        radius: 9
        color: root.gold
        border.width: 2
        border.color: Colours.palette.m3surface

        MaterialIcon {
            anchors.centerIn: parent
            text: "mic"
            color: Colours.palette.m3surface
            font.pointSize: 8
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.sylvie = !screenState.sylvie;
        }
    }
}
