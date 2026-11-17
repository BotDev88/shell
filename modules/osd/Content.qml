pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Sylvie OSD (design/Sylvie OS Shell.dc.html 1d): vertical pills side by side, each with its value
// on top, a 30px walnut track that fills from the bottom (volume orange, brightness gold, with a
// small ink notch at the level) and the icon below. Drag, click or scroll a pill to change it.
Item {
    id: root

    required property Brightness.Monitor monitor
    required property ScreenState screenState

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted
    required property real brightness

    readonly property real maxVolume: GlobalConfig.services.maxVolume

    implicitWidth: row.implicitWidth + 34 + CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large)
    implicitHeight: 340

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 20
        spacing: 16

        VPill {
            value: root.volume / root.maxVolume
            label: Math.round(root.volume * 100)
            icon: Icons.getVolumeIcon(root.volume, root.muted)
            accent: Colours.palette.m3primary
            onMoved: v => Audio.setVolume(v * root.maxVolume)
            onStep: up => up ? Audio.incrementVolume() : Audio.decrementVolume()
        }

        VPill {
            visible: Config.osd.enableMicrophone && (!Config.osd.enableBrightness || !root.screenState.session)
            value: root.sourceVolume / root.maxVolume
            label: Math.round(root.sourceVolume * 100)
            icon: Icons.getMicVolumeIcon(root.sourceVolume, root.sourceMuted)
            accent: Colours.palette.m3tertiary
            onMoved: v => Audio.setSourceVolume(v * root.maxVolume)
            onStep: up => up ? Audio.incrementSourceVolume() : Audio.decrementSourceVolume()
        }

        VPill {
            visible: Config.osd.enableBrightness && !!root.monitor
            value: root.brightness
            label: Math.round(root.brightness * 100)
            icon: "light_mode"
            accent: Colours.palette.m3secondary
            onMoved: v => root.monitor?.setBrightness(Math.max(0.05, v))
            onStep: up => root.monitor?.setBrightness(root.monitor.brightness + (up ? 1 : -1) * GlobalConfig.services.brightnessIncrement)
        }
    }

    component VPill: Column {
        id: pill

        property real value
        property int label
        property string icon
        property color accent

        signal moved(real value)
        signal step(bool up)

        readonly property real v: Math.max(0, Math.min(1, value))

        spacing: 12
        height: 340 - 44

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pill.label
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.DemiBold })
        }

        Rectangle {
            id: track

            anchors.horizontalCenter: parent.horizontalCenter
            width: 30
            height: pill.height - 24 - 24 - 12 * 2
            radius: 15
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.max(parent.width, parent.height * pill.v)
                radius: 15
                color: pill.accent
                visible: pill.v > 0

                Behavior on height {
                    Anim {}
                }
            }

            // notch at the level
            Rectangle {
                x: 9
                y: Math.min(parent.height - 21, parent.height - Math.max(parent.width, parent.height * pill.v) + 15)
                width: 12
                height: 3
                radius: 2
                color: Colours.palette.m3surface
                visible: pill.v > 0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function set(y: real): void {
                    pill.moved(Math.max(0, Math.min(1, 1 - y / height)));
                }

                onPressed: event => set(event.y)
                onPositionChanged: event => {
                    if (pressed)
                        set(event.y);
                }
                onWheel: event => pill.step(event.angleDelta.y > 0)
            }
        }

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pill.icon
            color: pill.accent
            fontStyle: Tokens.font.icon.builders.medium.build()
        }
    }
}
