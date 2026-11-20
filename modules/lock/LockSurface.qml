pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

// Atomica lock screen (design/Sylvie OS Shell.dc.html 1e): the current wallpaper under a
// light walnut wash, the lock card bottom right, and session buttons (power off, restart, sleep,
// log out) bottom left. Fades and rises in on lock; fades out on unlock.
WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running
    // the current wallpaper (Atomica theme); the theme's first one if that can't be shown
    readonly property string lockWallpaper: Atomica.wallpaper || Atomica.themeWallpaper

    contentItem.Config.screen: screen?.name ?? ""
    contentItem.Tokens.screen: screen?.name ?? ""

    color: "transparent"

    Connections {
        function onUnlock(): void {
            unlockAnim.start();
        }

        target: root.lock
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: card
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
            Anim {
                target: card
                property: "anchors.bottomMargin"
                to: 40
            }
            Anim {
                target: session
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                type: Anim.StandardLarge
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    ParallelAnimation {
        id: initAnim

        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
        Anim {
            target: card
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
        Anim {
            target: card
            property: "anchors.bottomMargin"
            to: 70
            type: Anim.StandardLarge
        }
        Anim {
            target: session
            property: "opacity"
            to: 1
            type: Anim.StandardLarge
        }
    }

    Item {
        id: background

        anchors.fill: parent
        opacity: 0

        Image {
            id: sylvieWall

            anchors.fill: parent
            source: root.lockWallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        // fallback: the theme's first wallpaper (e.g. when the current one is a video)
        Image {
            anchors.fill: parent
            visible: sylvieWall.status === Image.Error
            source: visible ? Atomica.themeWallpaper : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3surface, 0.28)
        }
    }

    SylvieLockCard {
        id: card

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 70
        anchors.bottomMargin: 20
        opacity: 0
        visible: Config.lock.enabled

        lock: root

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1
            shadowVerticalOffset: 20
            shadowColor: Qt.alpha("black", 0.35)
        }
    }

    Row {
        id: session

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 40
        anchors.bottomMargin: 36
        spacing: 10
        opacity: 0

        SessionButton {
            icon: "power_settings_new"
            colour: Colours.palette.m3primary
            command: Config.session.commands.shutdown
        }
        SessionButton {
            icon: "restart_alt"
            command: Config.session.commands.reboot
        }
        SessionButton {
            icon: "bedtime"
            command: ["suspend"]
        }
        SessionButton {
            icon: "logout"
            command: Config.session.commands.logout
        }
    }

    component SessionButton: StyledRect {
        id: button

        property string icon
        property color colour: Colours.palette.m3onSurface
        property list<string> command

        implicitWidth: 52
        implicitHeight: 52
        radius: 18
        color: Colours.palette.m3surface

        StateLayer {
            radius: button.radius
            color: button.colour
            onClicked: {
                if (!SessionManager.exec(button.command))
                    Quickshell.execDetached(button.command);
            }
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            color: button.colour
            fontStyle: Tokens.font.icon.builders.medium.build()
        }
    }
}
