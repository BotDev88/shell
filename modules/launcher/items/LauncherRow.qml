import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

// Sylvie launcher row ("Launch Control", design/Sylvie OS Shell.dc.html 1b):
// index | 44px icon well | name (Josefin Sans 600) + description (IBM Plex Mono) | key hint.
// The selected row is filled orange (drawn by the list's highlight) with ink text.
Item {
    id: root

    required property int index
    property string name
    property string desc
    property string iconSource // app icon (image)
    property string iconName // Material Symbols name, used when there is no image
    property bool favourite

    signal activated

    readonly property bool selected: ListView.isCurrentItem
    readonly property color fg: selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
    readonly property font monoFont: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Normal })

    implicitHeight: 64

    anchors.left: parent?.left
    anchors.right: parent?.right

    // hairline between rows, hidden next to the selected row
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colours.palette.m3outlineVariant
        visible: root.index > 0 && !root.selected && root.ListView.view?.currentIndex !== root.index - 1
    }

    StateLayer {
        radius: 0
        color: root.fg
        onClicked: root.activated()
    }

    StyledText {
        id: number

        x: 0
        width: 52
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: String(root.index + 1).padStart(2, "0")
        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12, weight: Font.Medium, italic: true })
        color: root.fg
        opacity: 0.8
    }

    Rectangle {
        id: well

        x: 52 + 14
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44
        radius: 14
        color: root.selected ? Colours.palette.m3onPrimary : Colours.palette.m3surfaceContainerHigh

        IconImage {
            anchors.centerIn: parent
            visible: root.iconSource !== ""
            asynchronous: true
            source: root.iconSource
            implicitSize: 28
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.iconSource === ""
            text: root.iconName
            color: root.selected ? Colours.palette.m3primary : Colours.palette.m3secondary
            fontStyle: Tokens.font.icon.builders.large.build()
        }
    }

    Column {
        anchors.left: well.right
        anchors.leftMargin: 14
        anchors.right: keyHint.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Row {
            spacing: 6
            width: parent.width

            StyledText {
                text: root.name
                font: Qt.font({ family: "Josefin Sans", pixelSize: 17, weight: Font.DemiBold })
                color: root.fg
                elide: Text.ElideRight
                width: Math.min(implicitWidth, parent.width - (fav.visible ? fav.width + 6 : 0))
            }

            MaterialIcon {
                id: fav

                visible: root.favourite
                anchors.verticalCenter: parent.verticalCenter
                text: "favorite"
                fill: 1
                color: root.selected ? Colours.palette.m3onPrimary : Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.builders.small.build()
            }
        }

        StyledText {
            width: parent.width
            text: root.desc
            font: root.monoFont
            color: root.fg
            opacity: 0.78
            elide: Text.ElideRight
        }
    }

    StyledText {
        id: keyHint

        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.selected ? "↵" : root.index < 9 ? `ALT ${root.index + 1}` : ""
        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium })
        color: root.fg
        opacity: 0.8
    }
}
