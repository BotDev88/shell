pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property Props props
    required property ScreenState screenState
    readonly property int notifCount: Notifs.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

    anchors.fill: parent

    Component.onCompleted: Notifs.list.forEach(n => n.popup = false)

    // Sylvie header: hairline, "Transmissions" + orange count pill ........ CLEAR ALL
    Item {
        id: title

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        implicitHeight: titleText.implicitHeight + 17

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        StyledText {
            id: titleText

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 4
            text: Tr.tr("Transmissions")
            font: Qt.font({ family: "Josefin Sans", pixelSize: 24, weight: Font.Bold, italic: true })
        }

        Rectangle {
            anchors.left: titleText.right
            anchors.leftMargin: 10
            anchors.verticalCenter: titleText.verticalCenter
            visible: root.notifCount > 0
            implicitWidth: count.implicitWidth + 14
            implicitHeight: count.implicitHeight + 6
            radius: height / 2
            color: Colours.palette.m3primary

            StyledText {
                id: count

                anchors.centerIn: parent
                text: String(root.notifCount).padStart(2, "0")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.DemiBold })
                color: Colours.palette.m3onPrimary
            }
        }

        StyledText {
            id: clearAll

            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.baseline: titleText.baseline
            visible: root.notifCount > 0
            text: Tr.tr("CLEAR ALL")
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.Medium, letterSpacing: 1.7 })
            color: clearMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: clearMouse

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: clearTimer.start()
            }
        }
    }

    ClipRect {
        id: clipRect

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 16

        radius: 20
        color: "transparent"

        Loader {
            asynchronous: true
            anchors.centerIn: parent
            active: opacity > 0
            opacity: root.notifCount > 0 ? 0 : 1

            sourceComponent: ColumnLayout {
                spacing: 12

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "rocket_launch"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("ALL QUIET ON THE LAUNCHPAD")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium, letterSpacing: 2.2 })
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardExtraLarge
                }
            }
        }

        StyledFlickable {
            id: view

            anchors.fill: parent

            flickableDirection: Flickable.VerticalFlick
            contentWidth: width
            contentHeight: notifList.implicitHeight

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: view
            }

            NotifDockList {
                id: notifList

                props: root.props
                screenState: root.screenState
                container: view
            }
        }
    }

    Timer {
        id: clearTimer

        repeat: true
        triggeredOnStart: true
        interval: Math.max(15, Math.min(80, 69.8 - 12.3 * Math.log(Notifs.notClosed.length)))
        onTriggered: {
            const first = Notifs.notClosed[0];
            if (!first) {
                stop();
                return;
            }

            const appName = first.appName;
            let cleared = 0;
            for (const n of Notifs.notClosed.filter(n => n.appName === appName)) {
                n.close();
                cleared++;
                if (cleared > 30) {
                    interval = 5;
                    return;
                }
            }
        }
    }
}
