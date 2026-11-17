pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Sylvie clock (design/SylvieBar.dc.html): hours over minutes in Josefin Sans 700 italic, split by
// a 5px orange dot, with a 22px hairline divider above and below.
Item {
    id: root

    readonly property font clockFont: Qt.font({ family: "Josefin Sans", pixelSize: 19, weight: Font.Bold, italic: true })

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Hairline {}

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.hourStr
                font: root.clockFont
                color: Colours.palette.m3onSurface
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 5
                implicitHeight: 5
                radius: 2.5
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.minuteStr
                font: root.clockFont
                color: Colours.palette.m3onSurface
            }

            Loader {
                Layout.alignment: Qt.AlignHCenter
                asynchronous: true
                active: Units.twelveHourClock
                visible: active

                sourceComponent: StyledText {
                    text: Time.amPmStr.toUpperCase()
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 9, letterSpacing: 1.5 })
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        Hairline {}
    }

    component Hairline: Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 22
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }
}
