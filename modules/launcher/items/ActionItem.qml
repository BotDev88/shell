import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Sylvie: an action row in Launch Control (">wallpaper", ">lock"...; layout in LauncherRow).
LauncherRow {
    id: root

    required property var modelData
    required property var list

    name: modelData?.name ?? ""
    desc: modelData?.desc ?? ""
    iconName: modelData?.icon ?? ""

    onActivated: root.modelData?.onClicked(root.list)
}
