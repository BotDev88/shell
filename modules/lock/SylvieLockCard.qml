pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

// Sylvie lock card (design/Sylvie OS Shell.dc.html 1e), bottom right of the lock screen:
// "SYLVIE OS" between orange speed lines, the big clock, the long date, a hairline, the avatar with
// "Welcome back, <first name>" and "PROTOTYPE 7 · LOCKED", and a cream password pill with a key
// icon and an orange arrow. The pill shakes and Sylvie answers when the password is wrong.
// Below: a weather chip and a now-playing chip with play/pause.
ColumnLayout {
    id: root

    required property var lock // LockSurface
    readonly property var pam: lock.pam
    property string realName

    readonly property string firstName: (realName.split(",")[0].trim().split(" ")[0]) || SysInfo.user || "operator"
    readonly property string message: {
        if (pam.passwd.active)
            return Tr.tr("CHECKING YOUR CREDENTIALS...");
        if (pam.state === 3) // Pam.Failed
            return Tr.tr("That isn't the password I have on file, darling.");
        if (pam.state === 2) // Pam.MaxTries
            return Tr.tr("Too many tries, darling. Give me a moment.");
        if (pam.state === 1) // Pam.Error
            return Tr.tr("Something went sideways. Try again?");
        if (pam.fprint.active)
            return Tr.tr("TOUCH THE SENSOR, OR TYPE YOUR PASSWORD");
        return "";
    }

    spacing: 12
    width: 540

    Process {
        running: true
        command: ["getent", "passwd", SysInfo.user]
        stdout: StdioCollector {
            onStreamFinished: root.realName = (text.split(":")[4] ?? "").trim()
        }
    }

    // ---- the card ----
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + 34 + 30
        radius: 32
        color: Colours.palette.m3surface

        ColumnLayout {
            id: card

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 34
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            spacing: 16

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                SpeedLines {
                    anchors.verticalCenter: parent.verticalCenter
                    rightAligned: true
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SYLVIE OS"
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium, letterSpacing: 4 })
                    color: Colours.palette.m3secondary
                }

                SpeedLines {
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                text: `${Time.hourStr}:${Time.minuteStr}`
                font: Qt.font({ family: "Josefin Sans", pixelSize: 128, weight: Font.Bold, italic: true, letterSpacing: -2.5 })
                lineHeight: 0.85
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.format("dddd · d MMMM yyyy").toUpperCase()
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12, weight: Font.Medium, letterSpacing: 3.6 })
                color: Colours.palette.m3onSurfaceVariant
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Item {
                    implicitWidth: 52
                    implicitHeight: 52

                    Rectangle {
                        anchors.fill: parent
                        radius: 26
                        color: Colours.palette.m3primary
                    }

                    ClipRect {
                        anchors.centerIn: parent
                        width: 48
                        height: 48
                        radius: 24

                        Image {
                            id: face

                            anchors.fill: parent
                            source: `${Quickshell.env("HOME")}/.face`
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Image {
                            anchors.fill: parent
                            visible: face.status !== Image.Ready
                            source: Quickshell.shellPath("assets/sylvie-avatar.png")
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }

                ColumnLayout {
                    spacing: 3

                    StyledText {
                        text: Tr.tr("Welcome back, %1").arg(root.firstName)
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 18, weight: Font.DemiBold })
                    }

                    StyledText {
                        text: "PROTOTYPE 7 · LOCKED"
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 1.6 })
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            // password pill: cream, key icon, dots, orange arrow
            StyledRect {
                id: pill

                Layout.fillWidth: true
                implicitHeight: 58
                radius: 29
                color: Colours.palette.m3onSurface

                focus: true
                onActiveFocusChanged: {
                    if (!activeFocus)
                        forceActiveFocus();
                }

                Keys.onPressed: event => {
                    if (root.lock.unlocking)
                        return;
                    root.pam.handleKey(event);
                }

                transform: Translate {
                    id: shake
                }

                SequentialAnimation {
                    id: shakeAnim

                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: 5; duration: 60 }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
                }

                Connections {
                    function onFlashMsg(): void {
                        if (root.pam.state !== 0)
                            shakeAnim.restart();
                    }

                    target: root.pam
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: pill.forceActiveFocus()
                }

                MaterialIcon {
                    id: keyIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.pam.fprint.active ? "fingerprint" : "key"
                    color: Colours.palette.m3surface
                    fontStyle: Tokens.font.icon.builders.medium.build()
                }

                StyledText {
                    anchors.left: keyIcon.right
                    anchors.right: arrow.left
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.pam.buffer.length ? "●".repeat(Math.min(root.pam.buffer.length, 24)) : Tr.tr("PASSWORD")
                    elide: Text.ElideRight
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: root.pam.buffer.length ? 18 : 12, weight: Font.DemiBold, letterSpacing: root.pam.buffer.length ? 5 : 3 })
                    color: Colours.palette.m3surface
                    opacity: root.pam.buffer.length ? 1 : 0.5
                }

                Item {
                    id: arrow

                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46
                    height: 46

                    Rectangle {
                        anchors.fill: parent
                        radius: 23
                        color: Colours.palette.m3primary
                        scale: arrowMouse.pressed ? 0.9 : 1

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: root.pam.passwd.active ? "hourglass_top" : "arrow_forward"
                        color: Colours.palette.m3onPrimary
                        fontStyle: Tokens.font.icon.builders.large.build()
                    }

                    MouseArea {
                        id: arrowMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.pam.buffer.length) root.pam.passwd.start()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                horizontalAlignment: Text.AlignHCenter
                text: root.message
                elide: Text.ElideRight
                font: root.pam.state > 0 ? Qt.font({ family: "Josefin Sans", pixelSize: 15, weight: Font.DemiBold, italic: true }) : Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 1.6 })
                color: root.pam.state > 0 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // ---- chips: weather + now playing ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredWidth: 2
            implicitHeight: 64
            radius: 22
            color: Colours.palette.m3surface

            Component.onCompleted: Weather.reload()

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.icon
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: Weather.cc ? Weather.formatTemp(Weather.cc.tempC, true) : "--°"
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 24, weight: Font.Bold, italic: true })
                    }

                    StyledText {
                        text: Weather.description.toUpperCase()
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 9.5, weight: Font.Medium, letterSpacing: 1.1 })
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.preferredWidth: 3
            implicitHeight: 64
            radius: 22
            color: Colours.palette.m3surface

            readonly property var player: Players.active

            StyledRect {
                id: art

                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 10
                color: Colours.palette.m3surfaceContainerHigh
                clip: true

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: artImg.status !== Image.Ready
                    text: "album"
                    color: Colours.palette.m3onSurfaceVariant
                }

                Image {
                    id: artImg

                    anchors.fill: parent
                    source: Players.getArtUrl(parent.parent.player)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Column {
                anchors.left: art.right
                anchors.right: playBtn.left
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                StyledText {
                    width: parent.width
                    text: parent.parent.player?.trackTitle || Tr.tr("Nothing playing")
                    elide: Text.ElideRight
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 15, weight: Font.DemiBold })
                }

                StyledText {
                    width: parent.width
                    text: (parent.parent.player?.trackArtist || Tr.tr("Quiet airwaves")).toUpperCase()
                    elide: Text.ElideRight
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 9.5, weight: Font.Medium, letterSpacing: 1.1 })
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            MaterialIcon {
                id: playBtn

                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: parent.player?.isPlaying ? "pause_circle" : "play_circle"
                fill: 1
                color: Colours.palette.m3primary
                opacity: parent.player?.canTogglePlaying ? 1 : 0.5
                fontStyle: Tokens.font.icon.builders.large.scale(1.2).build()

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.parent.player?.togglePlaying()
                }
            }
        }
    }

    component SpeedLines: Column {
        property bool rightAligned

        spacing: 4

        Repeater {
            model: [54, 40, 26]

            Rectangle {
                required property int modelData

                x: parent.rightAligned ? 54 - modelData : 0
                width: modelData
                height: 3
                color: Colours.palette.m3primary
            }
        }
    }
}
