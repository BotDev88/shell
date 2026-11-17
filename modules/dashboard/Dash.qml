pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.dashboard.dash

// Sylvie dashboard tab (design/Sylvie OS Shell.dc.html 1a). Three columns of walnut tiles:
//   left:   profile (Sylvie's avatar, name, PROTOTYPE 7, uptime) and a weather mini tile
//   centre: big clock with the sparkle and the date between orange speed lines; now playing
//   right:  month calendar
RowLayout {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker // kept for Content.qml; the avatar is Sylvie's

    readonly property color tile: Colours.tPalette.m3surfaceContainer
    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property font monoLabel: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 1.6 })

    spacing: 12

    // ---- left column ----
    ColumnLayout {
        Layout.preferredWidth: 190
        Layout.fillHeight: true
        spacing: 12

        Tile {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: profile.implicitHeight + 36

            ColumnLayout {
                id: profile

                anchors.centerIn: parent
                spacing: 10

                // avatar: 76px, orange ring, walnut gap, hairline outer ring
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 88
                    implicitHeight: 88

                    Rectangle {
                        anchors.centerIn: parent
                        width: 88
                        height: 88
                        radius: 44
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 80
                        height: 80
                        radius: 40
                        color: Colours.palette.m3primary
                    }

                    ClipRect {
                        anchors.centerIn: parent
                        width: 76
                        height: 76
                        radius: 38

                        Image {
                            anchors.fill: parent
                            source: Quickshell.shellPath("assets/sylvie-avatar.png")
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    text: "Sylvie"
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 24, weight: Font.Bold, italic: true })
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: `PROTOTYPE 7\n${Tr.trCtx("UP %1", "system uptime").arg(root.uptimeText())}`
                    lineHeight: 1.5
                    font: root.monoLabel
                    color: root.dim
                }
            }
        }

        Tile {
            Layout.fillWidth: true
            implicitHeight: 104

            Component.onCompleted: Weather.reload()

            StyledText {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 16
                text: Weather.cc ? Weather.formatTemp(Weather.cc.tempC, true) : "--°"
                font: Qt.font({ family: "Josefin Sans", pixelSize: 38, weight: Font.Bold, italic: true })
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                text: Weather.icon
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                text: `${Weather.description.toUpperCase()}\n${(Weather.city || Tr.tr("Locating...")).toUpperCase()}`
                lineHeight: 1.4
                elide: Text.ElideRight
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 1.2 })
                color: root.dim
            }
        }
    }

    // ---- centre column ----
    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: 386
        spacing: 12

        Tile {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // faint orbit behind the clock
            Shape {
                x: -40
                y: 20
                width: 420
                height: 160
                opacity: 0.5
                rotation: -12
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Colours.palette.m3outlineVariant
                    strokeWidth: 2
                    fillColor: "transparent"

                    PathAngleArc {
                        centerX: 210
                        centerY: 80
                        radiusX: 200
                        radiusY: 52
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }

            Rectangle {
                x: 380
                y: 40
                width: 10
                height: 10
                radius: 5
                color: Colours.palette.m3secondary
                opacity: 0.5
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    StyledText {
                        text: `${Time.hourStr}:${Time.minuteStr}`
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 96, weight: Font.Bold, italic: true, letterSpacing: -2 })
                    }

                    Sparkle {
                        size: 22
                        y: 10
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    SpeedLines {
                        anchors.verticalCenter: parent.verticalCenter
                        rightAligned: true
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Time.format("dddd · d MMM yyyy").toUpperCase()
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11.5, weight: Font.Medium, letterSpacing: 3.4 })
                    }

                    SpeedLines {
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        SylvieMediaStrip {
            Layout.fillWidth: true
            tile: root.tile
            dim: root.dim
        }
    }

    // ---- right column ----
    Tile {
        Layout.preferredWidth: 252
        Layout.fillHeight: true
        implicitHeight: calendar.implicitHeight + 32

        SylvieCalendar {
            id: calendar

            anchors.fill: parent
            anchors.margins: 16
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            screenState: root.screenState
        }
    }

    function uptimeText(): string {
        // SysInfo.uptimeShort looks like "4h, 12m" or "2d, 3h"; show it as "04H 12M"
        const parts = (SysInfo.uptimeShort || "").match(/\d+\s*[a-z]+/gi) ?? [];
        return parts.slice(0, 2).map(p => {
            const m = p.match(/(\d+)\s*([a-z]+)/i);
            return `${m[1].padStart(2, "0")}${m[2][0].toUpperCase()}`;
        }).join(" ") || "--";
    }

    component Tile: StyledRect {
        color: root.tile
        radius: 20
    }

    component Sparkle: Shape {
        id: sparkle

        property real size: 16

        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Colours.palette.m3primary
            scale: Qt.size(sparkle.size / 24, sparkle.size / 24)

            PathSvg {
                path: "M12 0L13.6 10.4L24 12L13.6 13.6L12 24L10.4 13.6L0 12L10.4 10.4Z"
            }
        }
    }

    // three orange "speed lines" (40, 30, 20px) either side of the date
    component SpeedLines: Column {
        property bool rightAligned

        spacing: 3

        Repeater {
            model: [40, 30, 20]

            Rectangle {
                required property int modelData

                x: parent.rightAligned ? 40 - modelData : 0
                width: modelData
                height: 2
                color: Colours.palette.m3primary
            }
        }
    }
}
