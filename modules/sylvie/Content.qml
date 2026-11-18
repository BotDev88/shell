pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Sylvie's chat panel (approved mockup "Sylvie Orb and Chat", 18 Nov 2026): avatar, name and her
// state on top; the conversation; the brain chip with this month's spend, then the ask pill.
// Esc closes it. Action cards (Amber / Red) arrive with her tools (Phase 6, step 5).
Item {
    id: root

    required property ScreenState screenState

    readonly property color walnut: Colours.palette.m3surface
    readonly property color tile: Colours.palette.m3surfaceContainer
    readonly property color well: Colours.palette.m3surfaceContainerHigh
    readonly property color hair: Colours.palette.m3outlineVariant
    readonly property color cream: Colours.palette.m3onSurface
    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property color orange: Colours.palette.m3primary
    readonly property color gold: Colours.palette.m3secondary
    readonly property color rose: Colours.palette.m3error
    property string spend

    focus: true
    Keys.onEscapePressed: screenState.sylvie = false

    function opened(): void {
        field.forceActiveFocus();
        Sylvie.refreshStatus();
        usageProc.running = true;
    }

    Component.onCompleted: opened()

    Connections {
        function onSylvieChanged(): void {
            if (root.screenState.sylvie)
                root.opened();
        }

        target: root.screenState
    }

    // this month's spend for the brain she's using, from the Switchboard's meter
    Process {
        id: usageProc

        command: ["sylvie-switchboard", "usage"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const row = JSON.parse(text).providers.find(p => p.id === Sylvie.provider);
                    if (!row || row.id === "ollama")
                        root.spend = row ? qsTr("FREE · ON THIS COMPUTER") : "";
                    else if (row.budgetUsd)
                        root.spend = qsTr("$%1 OF $%2 THIS MONTH").arg(row.spentUsd.toFixed(2)).arg(row.budgetUsd.toFixed(0));
                    else
                        root.spend = qsTr("$%1 THIS MONTH").arg(row.spentUsd.toFixed(2));
                } catch (e) {}
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 22
        anchors.bottomMargin: 18
        spacing: 16

        // ---- header ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // avatar: an orange ring around Sylvie's portrait
            Item {
                implicitWidth: 46
                implicitHeight: 46

                Rectangle {
                    anchors.fill: parent
                    radius: 23
                    color: root.orange
                }

                ClipRect {
                    anchors.centerIn: parent
                    width: 42
                    height: 42
                    radius: 21

                    Image {
                        anchors.fill: parent
                        source: Quickshell.shellPath("assets/sylvie-avatar.png")
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                StyledText {
                    text: "Sylvie"
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 24, weight: Font.Bold, italic: true })
                }

                StyledText {
                    text: {
                        switch (Sylvie.state) {
                        case "listening":
                            return qsTr("● LISTENING · MIC ON");
                        case "thinking":
                            return qsTr("THINKING…");
                        case "speaking":
                            return qsTr("SPEAKING");
                        case "offline":
                            return qsTr("SERVICE NOT RUNNING");
                        default:
                            return qsTr("STANDING BY");
                        }
                    }
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10.5, letterSpacing: 2 })
                    color: Sylvie.state === "listening" ? root.gold : Sylvie.state === "thinking" || Sylvie.state === "speaking" ? root.orange : Sylvie.state === "offline" ? root.rose : root.dim
                }
            }

            RoundButton {
                visible: Sylvie.messages.length > 0
                icon: "refresh"
                label: qsTr("Start a new conversation")
                onClicked: Sylvie.clear()
            }

            RoundButton {
                icon: "close"
                label: qsTr("Close chat")
                onClicked: root.screenState.sylvie = false
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: root.hair
        }

        // ---- the conversation ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 40
                visible: Sylvie.messages.length === 0
                spacing: 8

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("What shall we work on, operator?")
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 19, weight: Font.DemiBold, italic: true })
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: Sylvie.online ? qsTr("Ask me anything. I can't operate the computer yet, but I can explain how.") : qsTr("My service isn't running. Start it with: systemctl --user start sylvied")
                    font: Qt.font({ family: "IBM Plex Sans", pixelSize: 13 })
                    color: root.dim
                }
            }

            ListView {
                id: list

                anchors.fill: parent
                clip: true
                spacing: 14
                model: Sylvie.messages
                onCountChanged: Qt.callLater(positionViewAtEnd)
                onContentHeightChanged: if (atYEnd || Sylvie.busy) Qt.callLater(positionViewAtEnd)

                delegate: Item {
                    id: msg

                    required property var modelData
                    readonly property bool mine: modelData.role === "user"

                    width: ListView.view.width
                    implicitHeight: bubble.implicitHeight

                    Rectangle {
                        id: bubble

                        anchors.right: msg.mine ? parent.right : undefined
                        anchors.left: msg.mine ? undefined : parent.left
                        width: msg.mine ? Math.min(body.implicitWidth + 28, parent.width * 0.8) : parent.width * 0.94
                        implicitHeight: col.implicitHeight + (msg.mine ? 20 : 0)
                        radius: 18
                        topRightRadius: 18
                        bottomRightRadius: msg.mine ? 4 : 18
                        color: msg.mine ? root.well : "transparent"

                        ColumnLayout {
                            id: col

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: msg.mine ? 14 : 0
                            anchors.rightMargin: msg.mine ? 14 : 0
                            spacing: 4

                            StyledText {
                                id: body

                                Layout.fillWidth: true
                                text: msg.modelData.pending && !msg.modelData.text ? "· · ·" : msg.modelData.text
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                                font: Qt.font({ family: "IBM Plex Sans", pixelSize: 14.5 })
                                lineHeight: 1.18
                                color: msg.modelData.error ? root.rose : msg.modelData.pending && !msg.modelData.text ? root.orange : root.cream
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: !!msg.modelData.note
                                text: msg.modelData.note ?? ""
                                wrapMode: Text.Wrap
                                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10 })
                                color: root.dim
                            }
                        }
                    }
                }
            }
        }

        // ---- brain chip + spend ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Sylvie.brainLabel !== ""

            Rectangle {
                implicitWidth: brain.implicitWidth + 20
                implicitHeight: 22
                radius: 11
                color: "transparent"
                border.width: 1
                border.color: root.hair

                StyledText {
                    id: brain

                    anchors.centerIn: parent
                    text: Sylvie.brainLabel
                    font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, letterSpacing: 1.4 })
                }
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.spend
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 10, letterSpacing: 1.4 })
                color: root.dim
            }
        }

        // ---- the ask pill ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 26
            color: "transparent"
            border.width: 2
            border.color: field.activeFocus ? root.orange : root.hair

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                RoundButton {
                    icon: "mic"
                    label: qsTr("Talking to Sylvie arrives with her voice")
                    enabled: false
                    filled: false
                }

                TextInput {
                    id: field

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: root.cream
                    selectionColor: root.orange
                    selectedTextColor: root.walnut
                    font: Qt.font({ family: "IBM Plex Sans", pixelSize: 14 })
                    onAccepted: send.clicked()

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !field.text
                        text: qsTr("Ask Sylvie…")
                        font: Qt.font({ family: "IBM Plex Sans", pixelSize: 14 })
                        color: root.dim
                    }
                }

                RoundButton {
                    id: send

                    icon: "arrow_forward"
                    label: qsTr("Send")
                    filled: true
                    enabled: field.text.trim().length > 0 && !Sylvie.busy
                    onClicked: {
                        Sylvie.ask(field.text);
                        field.text = "";
                    }
                }
            }
        }
    }

    // 40px round icon button; `filled` = orange with ink icon (ink on orange, never cream on orange)
    component RoundButton: Rectangle {
        id: rb

        property string icon
        property string label
        property bool filled

        signal clicked

        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: filled ? root.orange : "transparent"
        border.width: filled ? 0 : 1
        border.color: root.hair
        opacity: enabled ? 1 : 0.45

        Accessible.role: Accessible.Button
        Accessible.name: label

        StateLayer {
            radius: rb.radius
            color: rb.filled ? Colours.palette.m3onPrimary : root.cream
            disabled: !rb.enabled
            onClicked: rb.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: rb.icon
            color: rb.filled ? Colours.palette.m3onPrimary : root.cream
        }
    }
}
