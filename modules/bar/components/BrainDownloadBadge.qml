import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

// Under Sylvie's orb while her local brain downloads (sylvie-brain-get), wherever the Switchboard
// is: a ring that fills with the download (it turns while Ollama installs and starts) and the
// percentage under it. Gone when the download ends; a notification says how it went.
Column {
    id: root

    readonly property real value: BrainDownload.percent / 100

    visible: BrainDownload.active
    spacing: 2

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 30
        height: 30

        Shape {
            id: ring

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // the track
            ShapePath {
                strokeColor: Colours.palette.m3surfaceContainerHighest
                strokeWidth: 2.5
                fillColor: "transparent"

                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 1.5
                    radiusY: ring.height / 2 - 1.5
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            // what's done (or a turning quarter before the size is known)
            ShapePath {
                strokeColor: Colours.palette.m3primary
                strokeWidth: 2.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.width / 2 - 1.5
                    radiusY: ring.height / 2 - 1.5
                    startAngle: -90
                    sweepAngle: BrainDownload.measured ? Math.max(4, 360 * Math.min(1, root.value)) : 90
                }
            }

            RotationAnimation on rotation {
                running: root.visible && !BrainDownload.measured
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
                onStopped: ring.rotation = 0
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: "download"
            color: Colours.palette.m3primary
            font.pointSize: 9
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: BrainDownload.measured
        text: `${Math.floor(BrainDownload.percent)}%`
        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 9, weight: Font.Medium })
        color: Colours.palette.m3onSurfaceVariant
    }
}
