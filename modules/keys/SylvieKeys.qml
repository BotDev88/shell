pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Sylvie keybindings panel (Super+K): every binding, grouped and searchable, read from
// ~/.local/state/sylvie/keybindings.json (written by sylvie-keys.lua when Hyprland starts, so it
// always matches the real bindings). Type to search, Esc closes. Also `caelestia shell keys toggle`.
Scope {
    id: root

    property bool open
    property var rows: []
    readonly property string file: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/sylvie/keybindings.json`

    IpcHandler {
        function toggle(): void {
            root.open = !root.open;
        }

        function open(): void {
            root.open = true;
        }

        target: "keys"
    }

    FileView {
        path: root.file
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.rows = JSON.parse(text());
            } catch (e) {
                root.rows = [];
            }
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: Qt.alpha(Colours.palette.m3scrim, 0.45)
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "sylvie-keys"

            MouseArea {
                anchors.fill: parent
                onClicked: root.open = false
            }

            StyledRect {
                id: card

                anchors.centerIn: parent
                width: Math.min(parent.width - 120, 980)
                height: Math.min(parent.height - 100, 700)
                radius: 30
                color: Colours.palette.m3surface

                MouseArea {
                    anchors.fill: parent // swallow clicks
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        StyledText {
                            text: Tr.tr("Know your keys")
                            font: Qt.font({ family: "Josefin Sans", pixelSize: 30, weight: Font.Bold, italic: true })
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: Tr.tr("SUPER = THE WINDOWS KEY · ESC CLOSES")
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, weight: Font.Medium, letterSpacing: 2 })
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // search pill
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: 24
                        color: Colours.palette.m3surfaceContainer
                        border.width: 2
                        border.color: Colours.palette.m3primary

                        MaterialIcon {
                            id: searchIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: "search"
                            color: Colours.palette.m3primary
                        }

                        TextInput {
                            id: search

                            anchors.left: searchIcon.right
                            anchors.right: parent.right
                            anchors.leftMargin: 12
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            focus: true
                            color: Colours.palette.m3onSurface
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 15, weight: Font.Medium })
                            Keys.onEscapePressed: root.open = false
                            Component.onCompleted: forceActiveFocus()

                            StyledText {
                                visible: !search.text
                                text: Tr.tr("Search: screenshot, browser, workspace...")
                                font: search.font
                                color: Colours.palette.m3onSurfaceVariant
                                opacity: 0.7
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: groups.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        GridLayout {
                            id: groups

                            width: parent.width
                            columns: 2
                            columnSpacing: 24
                            rowSpacing: 18

                            Repeater {
                                model: {
                                    const q = search.text.trim().toLowerCase();
                                    const hit = r => !q || r.desc.toLowerCase().includes(q) || r.group.toLowerCase().includes(q) || r.keys.join(" ").toLowerCase().includes(q);
                                    const order = [];
                                    const by = {};
                                    for (const r of root.rows.filter(hit)) {
                                        if (!by[r.group]) {
                                            by[r.group] = [];
                                            order.push(r.group);
                                        }
                                        by[r.group].push(r);
                                    }
                                    return order.map(g => ({ name: g, rows: by[g] }));
                                }

                                ColumnLayout {
                                    id: group

                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 6

                                    StyledText {
                                        text: group.modelData.name.toUpperCase()
                                        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, weight: Font.DemiBold, letterSpacing: 2.2 })
                                        color: Colours.palette.m3secondary
                                    }

                                    Repeater {
                                        model: group.modelData.rows

                                        RowLayout {
                                            id: line

                                            required property var modelData

                                            Layout.fillWidth: true
                                            spacing: 10

                                            StyledText {
                                                Layout.fillWidth: true
                                                text: line.modelData.desc
                                                elide: Text.ElideRight
                                                font: Qt.font({ family: "Josefin Sans", pixelSize: 15, weight: Font.DemiBold })
                                            }

                                            Row {
                                                spacing: 6

                                                Repeater {
                                                    // first two key combos, each as chips
                                                    model: line.modelData.keys.slice(0, 2)

                                                    Row {
                                                        id: combo

                                                        required property string modelData

                                                        spacing: 3

                                                        Repeater {
                                                            model: combo.modelData.split("+").map(k => k.trim()).filter(k => k)

                                                            Rectangle {
                                                                required property string modelData

                                                                implicitWidth: chip.implicitWidth + 12
                                                                implicitHeight: 22
                                                                radius: 6
                                                                color: Colours.palette.m3surfaceContainerHigh
                                                                border.width: 1
                                                                border.color: Colours.palette.m3outlineVariant

                                                                StyledText {
                                                                    id: chip

                                                                    anchors.centerIn: parent
                                                                    text: parent.modelData.replace(/^SUPER_L$/i, "Super tap").replace(/^Return$/i, "↵").toUpperCase()
                                                                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 9.5, weight: Font.DemiBold })
                                                                    color: Colours.palette.m3onSurface
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
