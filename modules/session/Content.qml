pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.services

// Sylvie session menu (design/Sylvie OS Interactive.dc.html): five tall tiles in the right-edge
// drawer, LOCK, SLEEP, REBOOT, LOG OUT and SHUT DOWN (orange). Each tile is an icon over a small
// mono label; hover or keyboard focus turns it orange. Up/down (or Tab) to move, Enter to run,
// Esc to close. Opens with Ctrl+Alt+Delete or Super+Escape, or the bar's power button.
Column {
    id: root

    required property ScreenState screenState

    topPadding: 22
    bottomPadding: 22
    leftPadding: 18
    rightPadding: Math.max(20 - Config.border.thickness, 8)
    spacing: 12

    Tile {
        id: lockTile

        icon: "lock"
        label: Tr.tr("LOCK")
        command: ["loginctl", "lock-session"]
        KeyNavigation.down: sleepTile

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onSessionChanged(): void {
                if (root.screenState.session)
                    lockTile.forceActiveFocus();
            }

            target: root.screenState
        }
    }

    Tile {
        id: sleepTile

        icon: "bedtime"
        label: Tr.tr("SLEEP")
        command: ["suspend"]
        KeyNavigation.up: lockTile
        KeyNavigation.down: rebootTile
    }

    Tile {
        id: rebootTile

        icon: "restart_alt"
        label: Tr.tr("REBOOT")
        command: Config.session.commands.reboot
        KeyNavigation.up: sleepTile
        KeyNavigation.down: logoutTile
    }

    Tile {
        id: logoutTile

        icon: "logout"
        label: Tr.tr("LOG OUT")
        command: Config.session.commands.logout
        KeyNavigation.up: rebootTile
        KeyNavigation.down: shutdownTile
    }

    Tile {
        id: shutdownTile

        icon: "power_settings_new"
        label: Tr.tr("SHUT DOWN")
        command: Config.session.commands.shutdown
        primary: true
        KeyNavigation.up: logoutTile
    }

    component Tile: StyledRect {
        id: tile

        property string icon
        property string label
        property list<string> command
        property bool primary

        readonly property bool lit: primary || activeFocus || mouse.containsMouse

        function exec(): void {
            root.screenState.session = false;
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: 80
        implicitHeight: 89
        radius: 22
        color: lit ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

        // focus ring for keyboard use on the always-orange tile
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius + 4
            color: "transparent"
            border.width: 2
            border.color: Colours.palette.m3primary
            visible: tile.primary && tile.activeFocus
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.icon
                color: tile.lit ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.builders.large.scale(1.15).build()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 8.5, weight: Font.Medium, letterSpacing: 1.4 })
                color: tile.lit ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.exec()
        }

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.forceActiveFocus();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab && KeyNavigation.up) {
                KeyNavigation.up.forceActiveFocus();
                event.accepted = true;
            }
        }

        Behavior on color {
            CAnim {}
        }
    }
}
