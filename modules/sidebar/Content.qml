import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Sylvie sidebar (design/Sylvie OS Shell.dc.html 1c): quick toggles and sliders on top, then
// "Transmissions" (notifications) below a hairline.
Item {
    id: root

    required property Props props
    required property ScreenState screenState

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.topMargin: 30
        anchors.bottomMargin: 30
        anchors.rightMargin: 20
        spacing: 16

        SylvieControls {
            Layout.fillWidth: true
            screenState: root.screenState
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            NotifDock {
                objectName: "sidebarNotifications"

                props: root.props
                screenState: root.screenState
            }
        }
    }
}
