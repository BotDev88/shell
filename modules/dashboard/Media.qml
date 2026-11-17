pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Sylvie media tab ("Sylvie RECORDS", design/Sylvie OS Interactive.dc.html): a 250px record with
// grooves and an orange "Sylvie RECORDS" label that spins while playing; beside it the play state
// in gold, the title (Josefin Sans 700 italic), artist · album, a seekable progress bar, times and
// prev / play-pause / next. Follows the active MPRIS player.
Item {
    id: root

    required property ScreenState screenState

    readonly property var player: Players.active
    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property real progress: player?.length ? Math.min(1, (player.position % player.length) / player.length) : 0
    readonly property string stateLine: {
        if (!player)
            return Tr.tr("STANDING BY");
        const state = player.isPlaying ? Tr.tr("PLAYING") : Tr.tr("PAUSED");
        const n = player.metadata?.["xesam:trackNumber"];
        return n ? `${state} · ${Tr.tr("TRACK %1").arg(String(n).padStart(2, "0"))}` : `${state} · ${Players.getIdentity(player).toUpperCase()}`;
    }

    function fmt(secs: real): string {
        if (!secs || secs < 0)
            return "0:00";
        const s = Math.floor(secs);
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    implicitWidth: 852
    implicitHeight: 266

    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    // the record
    Item {
        id: record

        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 262
        height: 262

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colours.tPalette.m3surfaceContainer
        }

        Item {
            id: disc

            anchors.centerIn: parent
            width: 250
            height: 250

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colours.palette.m3surfaceContainerLowest
            }

            // grooves
            Repeater {
                model: 18

                Rectangle {
                    required property int index

                    anchors.centerIn: parent
                    width: 240 - index * 8
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Colours.tPalette.m3surfaceContainer
                    visible: width > 104
                }
            }

            // label
            Rectangle {
                anchors.centerIn: parent
                width: 96
                height: 96
                radius: 48
                color: Colours.palette.m3primary

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Sylvie"
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 14, weight: Font.Bold, italic: true })
                        color: Colours.palette.m3onPrimary
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "RECORDS"
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 7, weight: Font.Medium, letterSpacing: 1.4 })
                        color: Colours.palette.m3onPrimary
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: Colours.palette.m3surface
                    }
                }
            }

            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 6000
                loops: Animation.Infinite
                running: root.player?.isPlaying ?? false
            }
        }
    }

    Column {
        anchors.left: record.right
        anchors.right: parent.right
        anchors.leftMargin: 24
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        StyledText {
            text: root.stateLine
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.Medium, letterSpacing: 2.5 })
            color: Colours.palette.m3secondary
        }

        StyledText {
            width: parent.width
            text: root.player?.trackTitle || Tr.tr("Nothing playing")
            elide: Text.ElideRight
            font: Qt.font({ family: "Josefin Sans", pixelSize: 50, weight: Font.Bold, italic: true })
        }

        StyledText {
            width: parent.width
            text: root.player ? [root.player.trackArtist, root.player.trackAlbum].filter(s => s).join(" · ").toUpperCase() : Tr.tr("THE AIRWAVES ARE QUIET")
            elide: Text.ElideRight
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12, weight: Font.Medium, letterSpacing: 2.4 })
            color: root.dim
        }

        // seekable progress bar
        Item {
            width: parent.width
            height: 18

            Rectangle {
                id: track

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Colours.palette.m3outlineVariant

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 3
                    color: Colours.palette.m3primary
                }
            }

            Rectangle {
                visible: !!root.player
                x: track.width * root.progress - 8
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                radius: 8
                color: Colours.palette.m3onSurface
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: event => {
                    if (root.player?.length)
                        root.player.position = Math.max(0, Math.min(1, event.x / width)) * root.player.length;
                }
            }
        }

        Item {
            width: parent.width
            height: elapsed.implicitHeight

            StyledText {
                id: elapsed

                text: root.fmt(root.player?.position ?? 0)
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11 })
                color: root.dim
            }

            StyledText {
                anchors.right: parent.right
                text: root.fmt(root.player?.length ?? 0)
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11 })
                color: root.dim
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18

            Transport {
                anchors.verticalCenter: parent.verticalCenter
                icon: "skip_previous"
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
            }

            Item {
                width: 64
                height: 64

                Rectangle {
                    anchors.fill: parent
                    radius: 32
                    color: Colours.palette.m3primary
                    opacity: root.player?.canTogglePlaying ? 1 : 0.5
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.player?.isPlaying ? "pause" : "play_arrow"
                    fill: 1
                    color: Colours.palette.m3onPrimary
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.2).build()
                }

                StateLayer {
                    radius: 32
                    color: Colours.palette.m3onPrimary
                    disabled: !(root.player?.canTogglePlaying ?? false)
                    onClicked: root.player?.togglePlaying()
                }
            }

            Transport {
                anchors.verticalCenter: parent.verticalCenter
                icon: "skip_next"
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
            }
        }
    }

    component Transport: Item {
        id: transport

        property string icon

        signal clicked

        width: 44
        height: 44
        opacity: enabled ? 1 : 0.4

        MaterialIcon {
            anchors.centerIn: parent
            text: transport.icon
            fontStyle: Tokens.font.icon.builders.extraLarge.build()
        }

        StateLayer {
            radius: 22
            disabled: !transport.enabled
            onClicked: transport.clicked()
        }
    }
}
