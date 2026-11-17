import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Sylvie: the power button. A 38px walnut-3 circle with an orange power icon; opens the session
// menu (design/SylvieBar.dc.html).
Item {
    id: root

    required property ScreenState screenState

    readonly property int size: 38

    implicitWidth: size
    implicitHeight: size

    StyledRect {
        anchors.fill: parent
        radius: root.size / 2
        color: Colours.palette.m3surfaceContainerHigh

        StateLayer {
            radius: parent.radius
            color: Colours.palette.m3primary
            onClicked: root.screenState.session = !root.screenState.session
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: "power_settings_new"
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
        }
    }
}
