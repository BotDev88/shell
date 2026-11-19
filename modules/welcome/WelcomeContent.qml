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

    // pages to show, in order: the first-login tour, or a single page opened directly
    property list<string> order: ["hello", "look", "keys", "switchboard", "additions", "done"]
    readonly property list<string> allPages: ["hello", "look", "keys", "switchboard", "additions", "done", "updates"]
    property int page: 0
    readonly property int pages: order.length
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
            text: `ATOMICA · ${Atomica.label}`
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
        currentIndex: root.allPages.indexOf(root.order[root.page] ?? "hello")

        HelloPage {}
        LookPage {}
        KeysPage {}
        SwitchboardPage {}
        AdditionsPage {}
        DonePage {}
        UpdatesPage {}
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
            visible: root.pages > 1

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
                text: root.page < root.pages - 1 ? Tr.tr("NEXT") : root.pages > 1 ? Tr.tr("LET'S GO") : Tr.tr("CLOSE")
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

                    SylvieFace {
                        anchors.fill: parent
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
                    text: Tr.tr("I'm Sylvie, and Atomica is warmed up and ready. Let's pick your look, learn a few keys and add the apps you like. It takes a minute, and you can change all of it later.")
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

    component SwitchboardPage: ColumnLayout {
        id: sb

        property var status: ({ settings: {}, providers: [], ollamaInstalled: false })
        property var hw: ({ ramGb: 0, vramGb: 0, gpus: [], suggestion: { size: "none", model: "" } })
        property string busyLine
        readonly property var current: status.providers.find(p => p.id === status.settings.provider) ?? null
        property var usage: ({ month: "", providers: [] })
        readonly property var usageRow: usage.providers.find(p => p.id === status.settings.provider) ?? null

        function refresh(): void {
            statusProc.running = true;
            loadUsage(false);
        }

        // --refresh asks the providers for account totals, only where an admin key (OpenRouter: its key) is saved
        function loadUsage(fetch: bool): void {
            if (usageProc.running)
                return;
            usageProc.command = fetch ? ["sylvie-switchboard", "usage", "--refresh"] : ["sylvie-switchboard", "usage"];
            usageProc.running = true;
        }

        function run(cmd: list<string>): void {
            runner.createObject(sb, { command: cmd });
        }

        spacing: 14

        Component.onCompleted: {
            statusProc.running = true;
            loadUsage(true);
            hwProc.running = true;
        }

        Process {
            id: usageProc

            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        sb.usage = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        // admin key through stdin, like the API key below
        Process {
            id: adminKeyProc

            property string key

            stdinEnabled: true
            command: ["sylvie-switchboard", "admin-key", "set", sb.status.settings.provider ?? "anthropic"]
            stdout: SplitParser {
                onRead: data => {
                    if (data.trim())
                        sb.busyLine = data.trim().replace(/^[>!]\s*/, "");
                }
            }
            onStarted: {
                write(key);
                stdinEnabled = false;
                key = "";
            }
            onExited: {
                stdinEnabled = true;
                statusProc.running = true;
                sb.loadUsage(true);
            }
        }

        Process {
            id: statusProc

            command: ["sylvie-switchboard", "status"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        sb.status = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        Process {
            id: hwProc

            command: ["sylvie-switchboard", "hardware"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        sb.hw = JSON.parse(text);
                    } catch (e) {}
                }
            }
        }

        Component {
            id: runner

            Process {
                running: true
                stdout: SplitParser {
                    onRead: data => {
                        if (data.trim())
                            sb.busyLine = data.trim().replace(/^[>!]\s*/, "");
                    }
                }
                onExited: {
                    sb.refresh();
                    destroy();
                }
            }
        }

        // stores the typed key through stdin, so it never shows up in a process list
        Process {
            id: keyProc

            property string key

            stdinEnabled: true
            command: ["sylvie-switchboard", "key", "set", sb.status.settings.provider ?? "anthropic"]
            onStarted: {
                write(key);
                stdinEnabled = false;
                key = "";
            }
            onExited: {
                stdinEnabled = true;
                sb.refresh();
            }
        }

        PageTitle {
            title: Tr.tr("The Switchboard")
            sub: Tr.tr("Which AI Sylvie talks to. Keys go in the system keyring, never in a file.")
        }

        Row {
            spacing: 8

            Repeater {
                model: sb.status.providers

                Pill {
                    required property var modelData

                    text: modelData.name.toUpperCase()
                    icon: modelData.hasKey ? "check" : ""
                    primary: sb.status.settings.provider === modelData.id
                    onClicked: sb.run(["sylvie-switchboard", "set", "provider", modelData.id])
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: !!sb.current && sb.current.id !== "ollama"

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 48
                radius: 24
                color: root.tile
                border.width: keyField.activeFocus ? 2 : 1
                border.color: keyField.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                MaterialIcon {
                    id: keyIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "key"
                    color: Colours.palette.m3primary
                }

                TextInput {
                    id: keyField

                    anchors.left: keyIcon.right
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    color: Colours.palette.m3onSurface
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 14 })
                    onAccepted: saveKey.clicked()

                    StyledText {
                        visible: !keyField.text
                        text: sb.current?.hasKey ? Tr.tr("A key is stored. Paste a new one to replace it.") : Tr.tr("Paste your %1 API key").arg(sb.current?.name ?? "")
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 13 })
                        color: root.dim
                    }
                }
            }

            Pill {
                id: saveKey

                primary: keyField.text.length > 0
                enabled: keyField.text.length > 0 && !keyProc.running
                text: Tr.tr("SAVE KEY")
                icon: "lock"
                onClicked: {
                    keyProc.key = keyField.text;
                    keyField.text = "";
                    keyProc.running = true;
                }
            }

            Pill {
                visible: sb.current?.hasKey ?? false
                text: Tr.tr("FORGET")
                onClicked: sb.run(["sylvie-switchboard", "key", "remove", sb.current.id])
            }
        }

        Row {
            spacing: 8

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                text: Tr.tr("MODEL")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                color: root.dim
            }

            Repeater {
                model: sb.current?.models ?? []

                Pill {
                    required property string modelData

                    text: modelData
                    primary: sb.status.settings.model === modelData
                    onClicked: sb.run(["sylvie-switchboard", "set", "model", modelData])
                }
            }
        }

        Row {
            spacing: 8

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                text: Tr.tr("PERMISSIONS")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                color: root.dim
            }

            Repeater {
                model: [["ask", Tr.tr("ASK FIRST")], ["green-auto", Tr.tr("SAFE THINGS WITHOUT ASKING")], ["never", Tr.tr("NEVER ACT")]]

                Pill {
                    required property var modelData

                    text: modelData[1]
                    primary: sb.status.settings.permissions === modelData[0]
                    onClicked: sb.run(["sylvie-switchboard", "set", "permissions", modelData[0]])
                }
            }
        }

        // local AI
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: localRow.implicitHeight + 28
            radius: 18
            color: root.tile

            RowLayout {
                id: localRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                spacing: 14

                MaterialIcon {
                    text: "memory"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.builders.large.build()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    StyledText {
                        text: Tr.tr("Local brain (optional)")
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 16, weight: Font.DemiBold })
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: {
                            if (sb.busyLine)
                                return sb.busyLine;
                            if (sb.hw.suggestion.size === "none")
                                return Tr.tr("%1 GB RAM: a bit light for running a brain here. Use a cloud key instead.").arg(sb.hw.ramGb);
                            const gpu = sb.hw.vramGb > 0 ? Tr.tr(", %1 GB graphics").arg(sb.hw.vramGb) : "";
                            return Tr.tr("Private and offline: answers stay on this computer. %1 GB RAM%2: %3 fits (Ollama comes with it).").arg(sb.hw.ramGb).arg(gpu).arg(sb.hw.suggestion.model);
                        }
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5 })
                        color: sb.busyLine ? Colours.palette.m3secondary : root.dim
                    }
                }

                Pill {
                    visible: sb.hw.suggestion.size !== "none"
                    primary: true
                    text: Tr.tr("DOWNLOAD %1").arg(sb.hw.suggestion.model.toUpperCase())
                    icon: "download"
                    // one click: Ollama first if it isn't there (Additions installs and starts it,
                    // asking for the password), then the model
                    onClicked: sb.run(["sh", "-c", 'command -v ollama >/dev/null || sylvie-additions install ollama || exit 1; '
                        + 'for i in $(seq 30); do ollama list >/dev/null 2>&1 && break; sleep 1; done; '
                        + 'echo "> downloading $0 (about 1.4 GB for qwen3:1.7b)"; ollama pull "$0"', sb.hw.suggestion.model])
                }
            }
        }

        UsageCard {
            Layout.fillWidth: true
            visible: !!sb.usageRow
            row: sb.usageRow
            month: sb.usage.month
            onSaveAdminKey: key => {
                adminKeyProc.key = key;
                adminKeyProc.running = true;
            }
            onRemoveAdminKey: sb.run(["sylvie-switchboard", "admin-key", "remove", sb.usageRow.id])
            onSaveBudget: amount => sb.run(["sylvie-switchboard", "set", "budget", sb.usageRow.id, amount === "" ? "none" : amount])
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // This month's usage for one provider: Sylvie's own meter, the account's totals, the budget bar.
    component UsageCard: StyledRect {
        id: uc

        property var row
        property string month
        property string editing // "", "admin" or "budget"

        signal saveAdminKey(string key)
        signal removeAdminKey
        signal saveBudget(string amount)

        readonly property bool adminCapable: row?.id === "anthropic" || row?.id === "openai"
        readonly property color barColour: (row?.percent ?? 0) >= 100 ? Colours.palette.m3error : (row?.percent ?? 0) >= 80 ? Colours.palette.m3secondary : Colours.palette.m3primary

        function tok(n: real): string {
            if (n >= 1e6)
                return (n / 1e6).toFixed(1) + "M";
            if (n >= 1e3)
                return Math.round(n / 1e3) + "K";
            return String(n);
        }
        function usd(v: real): string {
            return "$" + Number(v).toFixed(2);
        }
        function monthName(): string {
            const p = month.split("-");
            return p.length === 2 ? new Date(+p[0], +p[1] - 1, 1).toLocaleDateString(Qt.locale(), "MMMM").toUpperCase() : "";
        }
        function localLine(): string {
            const l = row?.local;
            if (!l)
                return "";
            const t = tok(l.inputTokens + l.outputTokens);
            if (row.id === "ollama")
                return Tr.tr("%1 tokens · free").arg(t);
            return Tr.tr("%1 tokens · %2%3").arg(t).arg(l.costExact ? "" : "≈ ").arg(usd(l.costUsd));
        }
        function accountLine(): string {
            if (!row)
                return "";
            if (row.id === "google")
                return Tr.tr("Account totals not available for Gemini");
            if (row.id === "ollama")
                return Tr.tr("Runs on this computer, so it's free");
            if (adminCapable && !row.hasAdminKey)
                return Tr.tr("Add an admin key to see the whole account");
            if (row.id === "openrouter" && !row.hasKey)
                return Tr.tr("Add your key to see the whole account");
            const a = row.account;
            if (a?.error === "HTTP 401" || a?.error === "HTTP 403")
                return (row.id === "openrouter" ? Tr.tr("%1 refused the key (%2). Check it, or replace it.") : Tr.tr("%1 refused the admin key (%2). Check it, or remove it.")).arg(row.name).arg(a.error);
            if (!a || a.costUsd === null || a.costUsd === undefined)
                return a?.error ? Tr.tr("Couldn't reach %1 (%2)").arg(row.name).arg(a.error) : Tr.tr("Asking %1...").arg(row.name);
            const t = a.tokens === null || a.tokens === undefined ? "" : Tr.tr("%1 tokens · ").arg(tok(a.tokens));
            const when = a.updated ? Tr.tr(" · UPDATED %1").arg(a.updated.substr(11, 5)) : "";
            const err = a.error ? Tr.tr(" · couldn't refresh (%1)").arg(a.error) : "";
            return t + usd(a.costUsd) + when + err;
        }

        implicitHeight: ucCol.implicitHeight + 28
        radius: 18
        color: root.tile

        ColumnLayout {
            id: ucCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 18
            anchors.rightMargin: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                MaterialIcon {
                    text: "monitoring"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.builders.large.build()
                }

                StyledText {
                    text: Tr.tr("Usage · %1").arg(uc.monthName().toLowerCase().replace(/^./, c => c.toUpperCase()))
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 16, weight: Font.DemiBold })
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: !uc.row ? "" : uc.row.budgetUsd ? Tr.tr("%1 of %2 budget · %3%").arg(uc.usd(uc.row.spentUsd)).arg(uc.usd(uc.row.budgetUsd)).arg(uc.row.percent) : Tr.tr("%1 this month").arg(uc.usd(uc.row.spentUsd))
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 13, weight: Font.DemiBold })
                    color: uc.row?.budgetUsd ? uc.barColour : Colours.palette.m3onSurface
                }

                Pill {
                    visible: uc.adminCapable && uc.editing === ""
                    text: uc.row?.hasAdminKey ? Tr.tr("REMOVE ADMIN KEY") : Tr.tr("ADD ADMIN KEY")
                    onClicked: uc.row?.hasAdminKey ? uc.removeAdminKey() : (uc.editing = "admin")
                }

                Pill {
                    visible: uc.row?.id !== "ollama" && uc.editing === ""
                    text: Tr.tr("SET BUDGET")
                    onClicked: uc.editing = "budget"
                }
            }

            // budget bar
            Rectangle {
                Layout.fillWidth: true
                visible: !!uc.row?.budgetUsd
                implicitHeight: 6
                radius: 3
                color: Colours.palette.m3outlineVariant

                Rectangle {
                    width: parent.width * Math.min(1, (uc.row?.percent ?? 0) / 100)
                    height: parent.height
                    radius: 3
                    color: uc.barColour
                }
            }

            GridLayout {
                Layout.fillWidth: true
                visible: uc.editing === ""
                columns: 2
                columnSpacing: 14
                rowSpacing: 3

                StyledText {
                    text: Tr.tr("SYLVIE (THIS MACHINE)")
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                    color: root.dim
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: uc.localLine()
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11 })
                }
                StyledText {
                    text: Tr.tr("WHOLE ACCOUNT")
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                    color: root.dim
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: uc.accountLine()
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11 })
                    color: uc.row?.account?.error ? root.dim : Colours.palette.m3onSurface
                }
            }

            // admin key / budget entry
            RowLayout {
                Layout.fillWidth: true
                visible: uc.editing !== ""
                spacing: 12

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 20
                    color: Colours.palette.m3surface
                    border.width: ucField.activeFocus ? 2 : 1
                    border.color: ucField.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                    TextInput {
                        id: ucField

                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: uc.editing === "admin" ? TextInput.Password : TextInput.Normal
                        inputMethodHints: uc.editing === "budget" ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                        color: Colours.palette.m3onSurface
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 13 })
                        onAccepted: ucSave.clicked()
                        onVisibleChanged: if (visible) forceActiveFocus()

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !ucField.text
                            text: uc.editing === "admin" ? Tr.tr("Paste your %1 admin key (from the console's admin keys page)").arg(uc.row?.name ?? "") : Tr.tr("Monthly budget in dollars, e.g. 30 (leave empty for none)")
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 12 })
                            color: root.dim
                        }
                    }
                }

                Pill {
                    id: ucSave

                    primary: true
                    enabled: uc.editing === "budget" || ucField.text.length > 0
                    text: Tr.tr("SAVE")
                    icon: uc.editing === "admin" ? "lock" : "check"
                    onClicked: {
                        if (uc.editing === "admin")
                            uc.saveAdminKey(ucField.text);
                        else
                            uc.saveBudget(ucField.text.trim().replace(/^\$/, ""));
                        ucField.text = "";
                        uc.editing = "";
                    }
                }

                Pill {
                    text: Tr.tr("CANCEL")
                    onClicked: {
                        ucField.text = "";
                        uc.editing = "";
                    }
                }
            }
        }
    }

    component UpdatesPage: ColumnLayout {
        id: up

        property var state: null
        property string line
        property bool working

        function check(): void {
            line = Tr.tr("Checking...");
            checkProc.running = true;
        }

        spacing: 16

        Component.onCompleted: check()

        Process {
            id: checkProc

            command: ["sylvie-updates", "check"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        up.state = JSON.parse(text);
                    } catch (e) {}
                    up.line = "";
                }
            }
        }

        Process {
            id: applyProc

            command: ["sylvie-updates", "apply"]
            stdout: SplitParser {
                onRead: data => {
                    if (data.trim())
                        up.line = data.trim().replace(/^[>!]\s*/, "");
                }
            }
            onExited: {
                up.working = false;
                up.check();
            }
        }

        PageTitle {
            title: Tr.tr("Updates")
            sub: Tr.tr("From the official Arch repositories and Flathub. Each system update takes a snapshot first.")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: [["system_update", Tr.tr("System"), up.state ? up.state.official : -1], ["apps", Tr.tr("Flatpak apps"), up.state ? up.state.flatpak : -1]]

                StyledRect {
                    id: countTile

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 110
                    radius: 20
                    color: root.tile

                    MaterialIcon {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 18
                        text: countTile.modelData[0]
                        color: Colours.palette.m3secondary
                        fontStyle: Tokens.font.icon.builders.large.build()
                    }

                    StyledText {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        text: countTile.modelData[2] < 0 ? "--" : String(countTile.modelData[2])
                        font: Qt.font({ family: "Josefin Sans", pixelSize: 48, weight: Font.Bold, italic: true })
                    }

                    StyledText {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 18
                        text: countTile.modelData[1].toUpperCase()
                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.Medium, letterSpacing: 2 })
                        color: root.dim
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            visible: up.state?.rebootNeeded ?? false
            implicitHeight: 64
            radius: 18
            color: Colours.palette.m3primary

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: Tr.tr("A new kernel is installed. Restart to start using it.")
                font: Qt.font({ family: "Josefin Sans", pixelSize: 16, weight: Font.DemiBold })
                color: Colours.palette.m3onPrimary
            }

            Pill {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Tr.tr("RESTART")
                icon: "restart_alt"
                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: up.line || (up.state && up.state.official + up.state.flatpak === 0 ? Tr.tr("Everything's up to date, darling.") : "")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11 })
                color: up.working ? Colours.palette.m3secondary : root.dim
            }

            Pill {
                text: Tr.tr("CHECK AGAIN")
                icon: "refresh"
                enabled: !up.working && !checkProc.running
                onClicked: up.check()
            }

            Pill {
                primary: true
                text: up.working ? Tr.tr("UPDATING") : Tr.tr("UPDATE NOW")
                icon: up.working ? "hourglass_top" : "download"
                enabled: !up.working && !!up.state && up.state.official + up.state.flatpak > 0
                onClicked: {
                    up.working = true;
                    applyProc.running = true;
                }
            }
        }

        Item {
            Layout.fillHeight: true
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
