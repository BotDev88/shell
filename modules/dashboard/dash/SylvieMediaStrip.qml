pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Sylvie now-playing strip for the dashboard tab: 58px art, title (Josefin Sans 600), artist
// (IBM Plex Mono), a thin orange progress bar with a cream knob, times, and prev / play-pause
// (orange disc) / next. Follows the active MPRIS player.
StyledRect {
    id: root

    property color tile
    property color dim

    readonly property var player: Players.active
    readonly property real progress: player?.length ? Math.min(1, (player.position % player.length) / player.length) : 0

    function fmt(secs: real): string {
        if (!secs || secs < 0)
            return "0:00";
        const s = Math.floor(secs);
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    color: tile
    radius: 20
    implicitHeight: 82

    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    // album art, or a striped placeholder
    StyledRect {
        id: art

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        width: 58
        height: 58
        radius: 14
        color: Colours.palette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
        clip: true

        MaterialIcon {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready
            text: "album"
            color: root.dim
            fontStyle: Tokens.font.icon.builders.large.build()
        }

        ClipRect {
            anchors.fill: parent
            radius: 14

            Image {
                id: artImage

                anchors.fill: parent
                source: Players.getArtUrl(root.player)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }

    Column {
        anchors.left: art.right
        anchors.right: controls.left
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Column {
            width: parent.width
            spacing: 3

            StyledText {
                width: parent.width
                text: (root.player?.trackTitle || Tr.tr("Nothing playing"))
                elide: Text.ElideRight
                font: Qt.font({ family: "Josefin Sans", pixelSize: 17, weight: Font.DemiBold })
            }

            StyledText {
                width: parent.width
                text: (root.player?.trackArtist || Tr.tr("The airwaves are quiet")).toUpperCase()
                elide: Text.ElideRight
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, letterSpacing: 1 })
                color: root.dim
            }
        }

        // progress bar
        Item {
            width: parent.width
            height: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Colours.palette.m3outlineVariant

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 2
                    color: Colours.palette.m3primary
                }
            }

            Rectangle {
                visible: !!root.player
                x: parent.width * root.progress - 6
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: Colours.palette.m3onSurface
            }
        }

        Item {
            width: parent.width
            height: elapsed.implicitHeight

            StyledText {
                id: elapsed

                text: root.fmt(root.player?.position ?? 0)
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10 })
                color: root.dim
            }

            StyledText {
                anchors.right: parent.right
                text: root.fmt(root.player?.length ?? 0)
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10 })
                color: root.dim
            }
        }
    }

    Row {
        id: controls

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Control {
            icon: "skip_previous"
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player?.previous()
        }

        Item {
            width: 40
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Colours.palette.m3primary
                opacity: root.player?.canTogglePlaying ? 1 : 0.5
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: root.player?.isPlaying ? "pause" : "play_arrow"
                fill: 1
                color: Colours.palette.m3onPrimary
                fontStyle: Tokens.font.icon.builders.large.build()
            }

            StateLayer {
                radius: 20
                color: Colours.palette.m3onPrimary
                disabled: !(root.player?.canTogglePlaying ?? false)
                onClicked: root.player?.togglePlaying()
            }
        }

        Control {
            icon: "skip_next"
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player?.next()
        }
    }

    component Control: Item {
        id: control

        property string icon

        signal clicked

        width: 32
        height: 40
        opacity: enabled ? 1 : 0.4

        MaterialIcon {
            anchors.centerIn: parent
            text: control.icon
            color: root.dim
            fontStyle: Tokens.font.icon.builders.large.build()
        }

        StateLayer {
            radius: 16
            disabled: !control.enabled
            onClicked: control.clicked()
        }
    }
}
