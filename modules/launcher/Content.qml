pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

// Sylvie "Launch Control" (design/Sylvie OS Shell.dc.html 1b), top to bottom: header (sparkle,
// title, result count), results in a hairline frame, action chips, and the search pill.
Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: 20
    readonly property int gap: 14
    readonly property int rounding: Tokens.rounding.extraLarge
    readonly property string prefix: GlobalConfig.launcher.actionPrefix
    readonly property int resultCount: list.currentList?.count ?? 0
    readonly property string wallPath: list.showWallpapers ? (list.currentList?.currentItem?.modelData?.path ?? "") : ""
    readonly property var wallInfo: Wallpapers.displayInfo(wallPath)
    property list<color> swatches: []

    // Sylvie: five swatches of the scheme the highlighted wallpaper would generate (preview only)
    Timer {
        id: swatchTimer

        interval: 250
        onTriggered: if (root.wallPath) swatchProc.running = true
    }

    onWallPathChanged: swatchTimer.restart()

    Process {
        id: swatchProc

        command: ["caelestia", "wallpaper", "-p", root.wallPath, ...Wallpapers.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).colours;
                    root.swatches = ["primary", "secondary", "tertiary", "primaryContainer", "surfaceContainer"].filter(k => c[k]).map(k => `#${c[k]}`);
                } catch (e) {
                    root.swatches = [];
                }
            }
        }
    }

    function runChip(name: string): void {
        search.text = name === "wallpaper" ? `${prefix}wallpaper ` : `${prefix}${name}`;
        search.forceActiveFocus();
    }

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: 22 + header.height + gap + listWrapper.height + gap + chips.height + gap + search.height + search.anchors.bottomMargin

    // header: sparkle + "Launch Control" ........ "06 RESULTS"
    Item {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: listWrapper.top
        anchors.leftMargin: root.padding + 6
        anchors.rightMargin: root.padding + 6
        anchors.bottomMargin: root.gap
        height: title.implicitHeight

        Shape {
            id: sparkle

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: Colours.palette.m3primary
                scale: Qt.size(16 / 24, 16 / 24)

                PathSvg {
                    path: "M12 0L13.6 10.4L24 12L13.6 13.6L12 24L10.4 13.6L0 12L10.4 10.4Z"
                }
            }
        }

        StyledText {
            id: title

            anchors.left: sparkle.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: list.showWallpapers ? Tr.tr("Choose a horizon") : Tr.tr("Launch Control")
            font: Qt.font({ family: "Josefin Sans", pixelSize: 20, weight: Font.Bold, italic: true })
            color: Colours.palette.m3onSurface
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: list.showWallpapers && root.swatches.length > 0
            spacing: 12

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Tr.tr("SCHEME FROM WALLPAPER")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                color: Colours.palette.m3onSurfaceVariant
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: root.swatches

                    Rectangle {
                        required property color modelData

                        width: 22
                        height: 22
                        radius: 11
                        color: modelData
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                    }
                }
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !list.showWallpapers
            text: `${String(root.resultCount).padStart(2, "0")} ${root.resultCount === 1 ? Tr.tr("RESULT") : Tr.tr("RESULTS")}`
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.Medium, letterSpacing: 2.1 })
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: chips.top
        anchors.bottomMargin: root.gap

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - header.height - chips.height - root.padding * 2 - root.gap * 3 - 22
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    // action chips: >wallpaper >lock >dashboard >clear
    // wallpaper mode: "08 Bloom" in the middle, key hint on the right (in place of the chips)
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: search.top
        anchors.leftMargin: root.padding + 4
        anchors.rightMargin: root.padding + 4
        anchors.bottomMargin: root.gap
        height: chips.height
        visible: list.showWallpapers

        Row {
            anchors.centerIn: parent
            spacing: 12

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.wallInfo.num !== ""
                text: root.wallInfo.num
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12, weight: Font.Medium, italic: true })
                color: Colours.palette.m3primary
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wallInfo.name
                font: Qt.font({ family: "Josefin Sans", pixelSize: 18, weight: Font.DemiBold })
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Tr.tr("← → BROWSE · ↵ APPLY")
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    Row {
        id: chips

        anchors.left: parent.left
        anchors.bottom: search.top
        anchors.leftMargin: root.padding + 4
        anchors.bottomMargin: root.gap
        spacing: 8
        opacity: list.showWallpapers ? 0 : 1

        Repeater {
            model: ["wallpaper", "lock", "dashboard", "clear"]

            Rectangle {
                id: chip

                required property string modelData

                implicitWidth: chipText.implicitWidth + 20
                implicitHeight: chipText.implicitHeight + 12
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                StyledText {
                    id: chipText

                    anchors.centerIn: parent
                    text: `${root.prefix}${chip.modelData}`
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.Medium })
                    color: Colours.palette.m3onSurfaceVariant
                }

                StateLayer {
                    radius: chip.radius
                    onClicked: root.runChip(chip.modelData)
                }
            }
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.bottomMargin: Math.max(CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding), 10)

        // Sylvie search pill: 54px, walnut-2, 2px orange ring, orange search icon, mono text
        topPadding: 16
        bottomPadding: 16
        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 16, weight: Font.Medium })
        color: Colours.palette.m3onSurface
        placeholderText: ""
        bg.color: Colours.palette.m3surfaceContainer
        bg.border.width: 2
        bg.border.color: Colours.palette.m3primary
        searchIcon.color: Colours.palette.m3primary

        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: !search.text
            text: Tr.tr("TYPE %1 FOR ACTIONS").arg(root.prefix)
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
            color: Colours.palette.m3onSurfaceVariant
        }

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            // Sylvie: ← → browse horizons in wallpaper mode
            if (list.showWallpapers && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                if (event.key === Qt.Key_Left)
                    list.currentList?.decrementCurrentIndex();
                else
                    list.currentList?.incrementCurrentIndex();
                event.accepted = true;
                return;
            }

            // Sylvie: Alt+1..9 picks and runs that row (the key hints on each row)
            if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && !list.showWallpapers) {
                const idx = event.key - Qt.Key_1;
                const view = list.currentList;
                if (view && idx < view.count) {
                    view.currentIndex = idx;
                    search.accepted();
                }
                event.accepted = true;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher)
                    search.text = "";
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
