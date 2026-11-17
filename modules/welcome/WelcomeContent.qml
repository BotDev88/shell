pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// The Welcome app's pages and the footer (page dots, Back, Next / Finish).
Item {
    id: root

    signal finished

    property int page: 0
    readonly property int pages: 5
    property string realName
    readonly property string firstName: (realName.split(",")[0].trim().split(" ")[0]) || SysInfo.user

    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property color tile: Colours.tPalette.m3surfaceContainer

    focus: true
    Keys.onRightPressed: if (page < pages - 1) page++
    Keys.onLeftPressed: if (page > 0) page--
    Keys.onEscapePressed: finished()

    Process {
        running: true
        command: ["getent", "passwd", SysInfo.user]
        stdout: StdioCollector {
            onStreamFinished: root.realName = (text.split(":")[4] ?? "").trim()
        }
    }

    // ---- header: sparkle + SYLVIE OS · PROTOTYPE 7 ----
    Row {
        id: header

        x: 36
        y: 28
        spacing: 10

        Sparkle {
            anchors.verticalCenter: parent.verticalCenter
            size: 16
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "SYLVIE OS · PROTOTYPE 7"
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium, letterSpacing: 3 })
            color: Colours.palette.m3secondary
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 36
        y: 28
        text: Tr.tr("SKIP FOR NOW")
        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
        color: skipMouse.containsMouse ? Colours.palette.m3primary : root.dim

        MouseArea {
            id: skipMouse

            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.finished()
        }
    }

    // ---- pages ----
    StackLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.margins: 36
        anchors.topMargin: 18
        anchors.bottomMargin: 12
        currentIndex: root.page

        HelloPage {}
        LookPage {}
        KeysPage {}
        AdditionsPage {}
        DonePage {}
    }

    // ---- footer ----
    Item {
        id: footer

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 36
        anchors.bottomMargin: 28
        height: 48

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: root.pages

                Rectangle {
                    required property int index

                    anchors.verticalCenter: parent.verticalCenter
                    width: index === root.page ? 26 : 8
                    height: 8
                    radius: 4
                    color: index === root.page ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                    Behavior on width {
                        Anim {}
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Pill {
                visible: root.page > 0
                text: Tr.tr("BACK")
                onClicked: root.page--
            }

            Pill {
                primary: true
                text: root.page === root.pages - 1 ? Tr.tr("LET'S GO") : Tr.tr("NEXT")
                icon: "arrow_forward"
                onClicked: root.page === root.pages - 1 ? root.finished() : root.page++
            }
        }
    }

    // ================= pages =================

    component HelloPage: Item {
        RowLayout {
            anchors.centerIn: parent
            spacing: 48

            Item {
                implicitWidth: 196
                implicitHeight: 196

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 184
                    height: 184
                    radius: 92
                    color: Colours.palette.m3primary
                }

                ClipRect {
                    anchors.centerIn: parent
                    width: 176
                    height: 176
                    radius: 88

                    Image {
                        anchors.fill: parent
                        source: Quickshell.shellPath("assets/sylvie-avatar.png")
                        fillMode: Image.PreserveAspectCrop
                        mipmap: true
                    }
                }
            }

            ColumnLayout {
                Layout.maximumWidth: 480
                spacing: 14

                StyledText {
                    text: Tr.tr("Hello, %1.").arg(root.firstName)
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 64, weight: Font.Bold, italic: true })
                }

                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: Tr.tr("I'm Sylvie. Prototype 7 is warmed up and ready. Let's pick your look, learn a few keys and add the apps you like. It takes a minute, and you can change all of it later.")
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 18 })
                    color: root.dim
                    lineHeight: 1.25
                }

                Row {
                    Layout.topMargin: 6
                    spacing: 12

                    SpeedLines {
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Tr.tr("TUBES: 6 WARM, 0 FLICKERING")
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.Medium, letterSpacing: 2.2 })
                        color: root.dim
                    }
                }
            }
        }
    }

    component LookPage: ColumnLayout {
        spacing: 18

        PageTitle {
            title: Tr.tr("Choose a horizon")
            sub: Tr.tr("Your wallpaper. The colours follow it if you pick the dynamic scheme later.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 14
            columnSpacing: 14

            Repeater {
                model: Wallpapers.list

                Item {
                    id: wall

                    required property var modelData

                    readonly property bool current: modelData.path === Wallpapers.actualCurrent
                    readonly property var info: Wallpapers.displayInfo(modelData.path)

                    Layout.fillWidth: true
                    implicitHeight: thumb.height + 30

                    Rectangle {
                        anchors.fill: thumb
                        anchors.margins: -6
                        radius: 20
                        color: "transparent"
                        border.width: 3
                        border.color: Colours.palette.m3primary
                        visible: wall.current
                    }

                    ClipRect {
                        id: thumb

                        width: parent.width
                        height: width * 9 / 16
                        radius: 14

                        Image {
                            anchors.fill: parent
                            source: wall.modelData.path
                            sourceSize.width: 320
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Row {
                        anchors.top: thumb.bottom
                        anchors.topMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        StyledText {
                            text: wall.info.num
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, italic: true })
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: wall.info.name
                            font: Qt.font({ family: "Josefin Sans", pixelSize: 14, weight: Font.DemiBold })
                        }
                    }

                    MouseArea {
                        anchors.fill: thumb
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Wallpapers.setWallpaper(wall.modelData.path)
                    }
                }
            }
        }

        Row {
            Layout.topMargin: 4
            spacing: 10

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Tr.tr("CHASSIS")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                color: root.dim
            }

            Pill {
                text: Tr.tr("WALNUT (DARK)")
                icon: "dark_mode"
                primary: !Colours.light
                onClicked: Colours.setMode("dark")
            }

            Pill {
                text: Tr.tr("CREAM (LIGHT)")
                icon: "light_mode"
                primary: Colours.light
                onClicked: Colours.setMode("light")
            }
        }
    }

    component KeysPage: ColumnLayout {
        spacing: 18

        PageTitle {
            title: Tr.tr("Learn the keys")
            sub: Tr.tr("Ten to start with. Super is the Windows key. Super + K shows all of them.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 10
            columnSpacing: 14

            Repeater {
                model: [
                    [["Super", "Return"], Tr.tr("Terminal")],
                    [["Ctrl", "Space"], Tr.tr("Launch Control (apps and > actions)")],
                    [["Super", "Shift", "B"], Tr.tr("Browser")],
                    [["Super", "Shift", "F"], Tr.tr("Files")],
                    [["Super", "1 – 5"], Tr.tr("Switch workspace")],
                    [["Super", "W"], Tr.tr("Close the window")],
                    [["Super", "N"], Tr.tr("Toggles and Transmissions")],
                    [["Super", "Shift", "S"], Tr.tr("Screenshot")],
                    [["Super", "L"], Tr.tr("Lock the screen")],
                    [["Super", "Esc"], Tr.tr("Power menu")]
                ]

                StyledRect {
                    id: keyRow

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 16
                    color: root.tile

                    Row {
                        id: chips

                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: keyRow.modelData[0]

                            Rectangle {
                                required property string modelData

                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: keyText.implicitWidth + 18
                                implicitHeight: 28
                                radius: 8
                                color: Colours.palette.m3surfaceContainerHigh
                                border.width: 1
                                border.color: Colours.palette.m3outlineVariant

                                StyledText {
                                    id: keyText

                                    anchors.centerIn: parent
                                    text: parent.modelData.toUpperCase()
                                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.DemiBold })
                                    color: Colours.palette.m3secondary
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.left: chips.right
                        anchors.right: parent.right
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: keyRow.modelData[1]
                        elide: Text.ElideRight
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 15, weight: Font.DemiBold })
                    }
                }
            }
        }
    }

    component AdditionsPage: ColumnLayout {
        id: addPage

        property var catalog: ({ groups: [], items: [] })
        property var busy: ({}) // id -> last progress line
        property string group: "everyday"

        function reload(): void {
            listProc.running = true;
        }

        spacing: 14

        Component.onCompleted: reload()

        Process {
            id: listProc

            command: ["sylvie-additions", "list", "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        addPage.catalog = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        PageTitle {
            title: Tr.tr("Additions")
            sub: Tr.tr("Optional apps from their official sources. Nothing downloads until you press Install.")
        }

        Row {
            spacing: 8

            Repeater {
                model: addPage.catalog.groups

                Pill {
                    required property var modelData

                    text: modelData.name.toUpperCase()
                    primary: addPage.group === modelData.id
                    onClicked: addPage.group = modelData.id
                }
            }
        }

        // scrolls when a group has more than fits (Everyday has ten)
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: addGrid.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: addGrid

            width: parent.width
            columns: 2
            rowSpacing: 10
            columnSpacing: 14

            Repeater {
                model: addPage.catalog.items.filter(i => i.group === addPage.group)

                StyledRect {
                    id: app

                    required property var modelData

                    readonly property bool working: addPage.busy[modelData.id] !== undefined

                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: 18
                    color: root.tile

                    Rectangle {
                        id: well

                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 44
                        radius: 14
                        color: app.modelData.id === "gaming" ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: app.modelData.icon
                            color: app.modelData.id === "gaming" ? Colours.palette.m3onPrimary : Colours.palette.m3secondary
                            fontStyle: Tokens.font.icon.builders.large.build()
                        }
                    }

                    Column {
                        anchors.left: well.right
                        anchors.right: action.left
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        StyledText {
                            width: parent.width
                            text: app.modelData.name
                            elide: Text.ElideRight
                            font: Qt.font({ family: "Josefin Sans", pixelSize: 16, weight: Font.DemiBold })
                        }

                        StyledText {
                            width: parent.width
                            text: app.working ? addPage.busy[app.modelData.id] : `${app.modelData.desc} · ${app.modelData.size}`
                            elide: Text.ElideRight
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10 })
                            color: app.working ? Colours.palette.m3secondary : root.dim
                        }
                    }

                    Pill {
                        id: action

                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: !app.working && !app.modelData.installed
                        primary: !app.modelData.installed && !app.working
                        text: app.modelData.installed ? Tr.tr("INSTALLED") : app.working ? Tr.tr("WORKING") : Tr.tr("INSTALL")
                        icon: app.modelData.installed ? "check" : app.working ? "hourglass_top" : "download"
                        onClicked: installer.createObject(addPage, { itemId: app.modelData.id })
                    }
                }
            }
        }
        }

        Component {
            id: installer

            Process {
                id: proc

                property string itemId

                function setLine(line: string): void {
                    const b = Object.assign({}, addPage.busy);
                    b[itemId] = line;
                    addPage.busy = b;
                }

                function clearLine(): void {
                    const b = Object.assign({}, addPage.busy);
                    delete b[itemId];
                    addPage.busy = b;
                }

                running: true
                command: ["sylvie-additions", "install", itemId]
                Component.onCompleted: setLine(Tr.tr("Starting..."))
                stdout: SplitParser {
                    onRead: data => {
                        const line = data.trim();
                        if (line)
                            proc.setLine(line.replace(/^[>!]\s*/, ""));
                    }
                }
                onExited: {
                    clearLine();
                    addPage.reload();
                    destroy();
                }
            }
        }
    }

    component DonePage: Item {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Sparkle {
                Layout.alignment: Qt.AlignHCenter
                size: 48
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("All set, %1.").arg(root.firstName)
                font: Qt.font({ family: "Josefin Sans", pixelSize: 56, weight: Font.Bold, italic: true })
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 560
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("Press Ctrl + Space whenever you need something. Come back here any time: type >welcome in Launch Control.")
                font: Qt.font({ family: "Josefin Sans", pixelSize: 18 })
                color: root.dim
            }
        }
    }

    // ================= pieces =================

    component PageTitle: ColumnLayout {
        property string title
        property string sub

        spacing: 6

        StyledText {
            text: parent.title
            font: Qt.font({ family: "Josefin Sans", pixelSize: 34, weight: Font.Bold, italic: true })
        }

        StyledText {
            text: parent.sub
            font: Qt.font({ family: "Josefin Sans", pixelSize: 15 })
            color: root.dim
        }
    }

    component Pill: StyledRect {
        id: pill

        property string text
        property string icon
        property bool primary

        signal clicked

        implicitWidth: pillRow.implicitWidth + 32
        implicitHeight: 40
        radius: 20
        opacity: enabled ? 1 : 0.6
        color: primary ? Colours.palette.m3primary : "transparent"
        border.width: primary ? 0 : 1
        border.color: Colours.palette.m3outlineVariant

        StateLayer {
            radius: pill.radius
            color: pill.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            disabled: !pill.enabled
            onClicked: pill.clicked()
        }

        Row {
            id: pillRow

            anchors.centerIn: parent
            spacing: 8

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.DemiBold, letterSpacing: 1.6 })
                color: pill.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            }

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.icon !== ""
                text: pill.icon
                color: pill.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.builders.small.build()
            }
        }
    }

    component Sparkle: Shape {
        id: sparkle

        property real size: 16

        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Colours.palette.m3primary
            scale: Qt.size(sparkle.size / 24, sparkle.size / 24)

            PathSvg {
                path: "M12 0L13.6 10.4L24 12L13.6 13.6L12 24L10.4 13.6L0 12L10.4 10.4Z"
            }
        }
    }

    component SpeedLines: Column {
        spacing: 3

        Repeater {
            model: [40, 30, 20]

            Rectangle {
                required property int modelData

                width: modelData
                height: 2
                color: Colours.palette.m3primary
            }
        }
    }
}
