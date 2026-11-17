pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Sylvie month calendar (dashboard tab): month name in Josefin Sans 700 italic, year in mono,
// weekday initials in orange, today as an orange disc with ink text, weekends in dim cream.
// Scroll to change month; middle-click (or click the month name) goes back to today.
MouseArea {
    id: root

    required property ScreenState screenState

    readonly property date shown: screenState.dashboardDate
    readonly property int month: shown.getMonth()
    readonly property int year: shown.getFullYear()
    readonly property int firstDay: Qt.locale().firstDayOfWeek // 0 = Sunday
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const lead = (first.getDay() - firstDay + 7) % 7;
        const days = new Date(year, month + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < lead; i++)
            out.push(0);
        for (let d = 1; d <= days; d++)
            out.push(d);
        while (out.length % 7 !== 0)
            out.push(0);
        return out;
    }

    implicitHeight: header.height + 12 + grid.implicitHeight

    acceptedButtons: Qt.MiddleButton
    onClicked: root.screenState.dashboardDate = new Date()
    onWheel: wheel => {
        const step = wheel.angleDelta.y > 0 ? -1 : 1;
        root.screenState.dashboardDate = new Date(root.year, root.month + step, 1);
    }

    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        height: monthName.implicitHeight

        StyledText {
            id: monthName

            text: Qt.locale().standaloneMonthName(root.month)
            font: Qt.font({ family: "Josefin Sans", pixelSize: 20, weight: Font.Bold, italic: true })

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.screenState.dashboardDate = new Date()
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.baseline: monthName.baseline
            text: String(root.year)
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium, letterSpacing: 2.2 })
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Grid {
        id: grid

        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 7
        columnSpacing: 2
        rowSpacing: 2

        readonly property real cell: (width - columnSpacing * 6) / 7

        Repeater {
            model: 7

            StyledText {
                required property int index

                width: grid.cell
                height: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.NarrowFormat).toUpperCase()
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.DemiBold })
                color: Colours.palette.m3primary
            }
        }

        Repeater {
            model: root.cells

            Item {
                id: cell

                required property int modelData
                required property int index

                readonly property bool isToday: modelData > 0 && modelData === Time.date.getDate() && root.month === Time.date.getMonth() && root.year === Time.date.getFullYear()
                readonly property int weekday: (root.firstDay + index) % 7
                readonly property bool weekend: weekday === 0 || weekday === 6

                width: grid.cell
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    visible: cell.isToday
                    color: Colours.palette.m3primary
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: cell.modelData > 0
                    text: String(cell.modelData)
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12, weight: Font.Medium })
                    color: cell.isToday ? Colours.palette.m3onPrimary : cell.weekend ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                }
            }
        }
    }
}
