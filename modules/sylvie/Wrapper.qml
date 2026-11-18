pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

// Sylvie's chat drawer: grows out of the bar on the left, full height, like the sidebar does on
// the right. Opened by the orb, by Super+Alt+Space, or `caelestia shell drawers toggle sylvie`.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.sylvie
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.leftMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: 440
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: Tokens.padding.large
        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
