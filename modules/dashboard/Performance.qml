pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

// Sylvie performance tab (design/Sylvie OS Shell.dc.html 1d): four half-circle dials (CPU, GPU,
// memory, temperature in gold) and a numbered disk table whose bars turn gold when a disk is
// three-quarters full.
ColumnLayout {
    id: root

    readonly property color tile: Colours.tPalette.m3surfaceContainer
    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property bool hasGpu: Gpu.type !== GpuType.None

    spacing: 12

    ServiceRef {
        service: Cpu
    }

    ServiceRef {
        service: Gpu
    }

    ServiceRef {
        service: Memory
    }

    ServiceRef {
        service: Storage
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Dial {
            value: Cpu.percentage
            text: Strings.percentOne(Cpu.percentage)
            label: "CPU · LOAD"
        }

        Dial {
            value: root.hasGpu ? Gpu.percentage : 0
            text: root.hasGpu ? Strings.percentOne(Gpu.percentage) : "--"
            label: !root.hasGpu ? "GPU · NONE" : Gpu.percentage < 0.05 ? "GPU · IDLE" : "GPU · BUSY"
        }

        Dial {
            value: Memory.percentage
            text: Strings.percentOne(Memory.percentage)
            label: `MEMORY · ${Units.formatBytes(Memory.used * 1024).toUpperCase()}`
        }

        Dial {
            // no sensor (e.g. in a VM) reads as 0 or NaN: show "--"
            readonly property bool known: !isNaN(Cpu.temperature) && Cpu.temperature > 0
            value: known ? Math.min(1, Cpu.temperature / 100) : 0
            text: known ? Units.formatSensorTemp(Cpu.temperature) : "--"

            label: "TEMP · CPU"
            accent: Colours.palette.m3secondary
        }
    }

    // disk table
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: disks.implicitHeight + 2
        radius: 18
        color: "transparent"
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        Column {
            id: disks

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1

            Repeater {
                model: Storage.disks

                Item {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property real frac: modelData.total > 0 ? modelData.used / modelData.total : 0

                    width: disks.width
                    height: 44

                    Rectangle {
                        visible: row.index > 0
                        width: parent.width
                        height: 1
                        color: Colours.palette.m3outlineVariant
                    }

                    StyledText {
                        id: num

                        width: 56
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: String(row.index + 1).padStart(2, "0")
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12, italic: true })
                        color: root.dim
                    }

                    Rectangle {
                        x: 56
                        width: 1
                        height: parent.height
                        color: Colours.palette.m3outlineVariant
                    }

                    StyledText {
                        x: 56 + 16
                        width: 144
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.mount
                        elide: Text.ElideMiddle
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12 })
                    }

                    StyledText {
                        x: 56 + 160
                        anchors.verticalCenter: parent.verticalCenter
                        text: Units.formatKibUsage(row.modelData.used, row.modelData.total).toUpperCase()
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12 })
                        color: root.dim
                    }

                    Rectangle {
                        anchors.right: pct.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 220
                        height: 6
                        radius: 3
                        color: Colours.palette.m3outlineVariant

                        Rectangle {
                            width: parent.width * row.frac
                            height: parent.height
                            radius: 3
                            color: row.frac >= 0.75 ? Colours.palette.m3secondary : Colours.palette.m3primary
                        }
                    }

                    StyledText {
                        id: pct

                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        horizontalAlignment: Text.AlignRight
                        text: `${Math.round(row.frac * 100)}%`
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12 })
                    }
                }
            }
        }
    }

    // half-circle gauge: thick arc (track + value), tick ring, cream needle and hub
    component Dial: StyledRect {
        id: dial

        property real value
        property string text
        property string label
        property color accent: Colours.palette.m3primary
        readonly property real v: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

        Layout.fillWidth: true
        Layout.preferredWidth: 204 // (852 - 3 gaps) / 4
        implicitHeight: gauge.height + 20 + 16 + 6 + valueText.implicitHeight + 6 + labelText.implicitHeight + 4
        color: root.tile
        radius: 20

        Item {
            id: gauge

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            width: 150
            height: 80
            clip: true

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Colours.palette.m3outlineVariant
                    strokeWidth: 14
                    capStyle: ShapePath.FlatCap

                    PathAngleArc {
                        centerX: 75
                        centerY: 75
                        radiusX: 68
                        radiusY: 68
                        startAngle: 180
                        sweepAngle: 180
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: dial.accent
                    strokeWidth: 14
                    capStyle: ShapePath.FlatCap

                    PathAngleArc {
                        centerX: 75
                        centerY: 75
                        radiusX: 68
                        radiusY: 68
                        startAngle: 180
                        sweepAngle: 180 * dial.v

                        Behavior on sweepAngle {
                            Anim {}
                        }
                    }
                }
            }

            // tick ring (every 18 degrees)
            Repeater {
                model: 11

                Rectangle {
                    required property int index

                    x: 75 - width / 2
                    y: 75 - 51
                    width: 2
                    height: 6
                    color: Colours.palette.m3outlineVariant
                    transform: Rotation {
                        origin.x: 1
                        origin.y: 51
                        angle: -90 + index * 18
                    }
                }
            }

            // needle
            Rectangle {
                x: 75 - 1
                y: 75 - 5 - 62
                width: 2
                height: 62
                radius: 1
                color: Colours.palette.m3onSurface
                transform: Rotation {
                    origin.x: 1
                    origin.y: 62
                    angle: -90 + 180 * dial.v

                    Behavior on angle {
                        Anim {}
                    }
                }
            }

            Rectangle {
                x: 75 - 10
                y: 75 - 10
                width: 20
                height: 20
                radius: 10
                color: Colours.palette.m3onSurface
                border.width: 3
                border.color: root.tile
            }
        }

        StyledText {
            id: valueText

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: gauge.bottom
            anchors.topMargin: 10
            text: dial.text
            font: Qt.font({ family: "Josefin Sans", pixelSize: 32, weight: Font.Bold, italic: true })
        }

        StyledText {
            id: labelText

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: valueText.bottom
            anchors.topMargin: 6
            text: dial.label
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 1.8 })
            color: root.dim
        }
    }
}
