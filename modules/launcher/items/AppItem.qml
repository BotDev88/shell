import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

// Sylvie: an app row in Launch Control (layout in LauncherRow).
LauncherRow {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState

    name: modelData?.name ?? ""
    desc: (modelData?.comment || modelData?.genericName || modelData?.name) ?? ""
    iconSource: Quickshell.iconPath(modelData?.icon, "image-missing")
    favourite: modelData ? Strings.testRegexList(GlobalConfig.launcher.favouriteApps, modelData.id) : false

    onActivated: {
        Apps.launch(root.modelData);
        root.screenState.launcher = false;
    }
}
