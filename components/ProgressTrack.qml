import QtQuick
import qs.services

// A thin pill-shaped progress bar. measured: fills to `value` (0-1); otherwise a short segment
// slides back and forth (something is happening, the size isn't known yet).
Rectangle {
    id: root

    property bool measured
    property real value

    implicitHeight: 6
    radius: height / 2
    color: Colours.palette.m3surfaceContainerHighest
    clip: true

    Rectangle {
        visible: root.measured
        height: parent.height
        radius: parent.radius
        width: Math.max(parent.height, parent.width * Math.min(1, Math.max(0, root.value)))
        color: Colours.palette.m3primary

        Behavior on width {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: runner

        visible: !root.measured
        height: parent.height
        radius: parent.radius
        width: parent.width * 0.28
        color: Colours.palette.m3primary

        SequentialAnimation on x {
            running: runner.visible && root.visible
            loops: Animation.Infinite

            NumberAnimation {
                from: -runner.width
                to: root.width
                duration: 1300
                easing.type: Easing.InOutSine
            }
        }
    }
}
