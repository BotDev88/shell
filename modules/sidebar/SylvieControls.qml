pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.components
import qs.services

// Sylvie sidebar controls (design/Sylvie OS Shell.dc.html 1c): four toggle pills (Wi-Fi,
// Bluetooth, Quiet hours, Dusk light) in a 2x2 grid, then a walnut card with draggable volume
// (orange) and brightness (gold) sliders. A pill that's on is filled orange with ink text.
ColumnLayout {
    id: root

    required property ScreenState screenState

    readonly property var monitor: Brightness.getMonitorForScreen(screenState.modelData)
    readonly property var btDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
    property bool duskOn

    spacing: 16

    // Dusk light = hyprsunset (warm screen). Poll its state while the sidebar is open.
    Process {
        id: duskCheck

        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => root.duskOn = code === 0
    }

    Timer {
        running: root.screenState.sidebar
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: duskCheck.running = true
    }

    function toggleDusk(): void {
        if (duskOn)
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        else
            Quickshell.execDetached(["hyprsunset", "-t", "4000"]);
        duskOn = !duskOn;
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 8
        columnSpacing: 8

        Pill {
            icon: Nmcli.wifiEnabled ? "wifi" : "wifi_off"
            label: Tr.tr("Wi-Fi")
            sub: !Nmcli.wifiEnabled ? Tr.tr("OFF") : Nmcli.active ? Nmcli.active.ssid : Tr.tr("NOT CONNECTED")
            on: Nmcli.wifiEnabled
            onClicked: Nmcli.toggleWifi()
        }

        Pill {
            icon: "bluetooth"
            label: Tr.tr("Bluetooth")
            sub: !Bluetooth.defaultAdapter ? Tr.tr("NO ADAPTER") : !Bluetooth.defaultAdapter.enabled ? Tr.tr("OFF") : root.btDevice ? root.btDevice.name : Tr.tr("ON")
            on: Bluetooth.defaultAdapter?.enabled ?? false
            onClicked: {
                const adapter = Bluetooth.defaultAdapter;
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            }
        }

        Pill {
            icon: "do_not_disturb_on"
            label: Tr.tr("Quiet hours")
            sub: PersistentState.doNotDisturb ? Tr.tr("ON") : Tr.tr("OFF")
            on: PersistentState.doNotDisturb
            onClicked: PersistentState.doNotDisturb = !PersistentState.doNotDisturb
        }

        Pill {
            icon: "wb_twilight"
            label: Tr.tr("Dusk light")
            sub: root.duskOn ? Tr.tr("ON · 4000K") : Tr.tr("OFF")
            on: root.duskOn
            onClicked: root.toggleDusk()
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: sliders.implicitHeight + 28
        radius: 20
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: sliders

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Slider {
                icon: Audio.muted ? "volume_off" : "volume_up"
                value: Audio.volume
                accent: Colours.palette.m3primary
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.sink?.audio && (Audio.sink.audio.muted = !Audio.sink.audio.muted)
            }

            Slider {
                visible: !!root.monitor
                icon: "light_mode"
                value: root.monitor?.brightness ?? 0
                accent: Colours.palette.m3secondary
                onMoved: v => root.monitor?.setBrightness(Math.max(0.05, v))
            }
        }
    }

    component Pill: StyledRect {
        id: pill

        property string icon
        property string label
        property string sub
        property bool on

        signal clicked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 52
        radius: 26
        color: on ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

        readonly property color fg: on ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

        StateLayer {
            radius: pill.radius
            color: pill.fg
            onClicked: pill.clicked()
        }

        MaterialIcon {
            id: pillIcon

            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: pill.icon
            color: pill.on ? pill.fg : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.medium.build()
        }

        Column {
            anchors.left: pillIcon.right
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                width: parent.width
                text: pill.label
                elide: Text.ElideRight
                font: Qt.font({ family: "Josefin Sans", pixelSize: 14, weight: Font.DemiBold })
                color: pill.fg
            }

            StyledText {
                width: parent.width
                text: pill.sub.toUpperCase()
                elide: Text.ElideRight
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 9.5, weight: Font.Medium })
                color: pill.on ? pill.fg : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    // icon | 8px track with a filled part and an 18px cream knob | value (0-100)
    component Slider: RowLayout {
        id: slider

        property string icon
        property real value
        property color accent

        signal moved(real value)
        signal iconClicked

        readonly property real v: Math.max(0, Math.min(1, value))

        Layout.fillWidth: true
        spacing: 12

        MaterialIcon {
            text: slider.icon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.medium.build()

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: slider.iconClicked()
            }
        }

        Item {
            id: trackArea

            Layout.fillWidth: true
            implicitHeight: 22

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 8
                radius: 4
                color: Colours.palette.m3outlineVariant

                Rectangle {
                    width: parent.width * slider.v
                    height: parent.height
                    radius: 4
                    color: slider.accent
                }
            }

            Rectangle {
                x: trackArea.width * slider.v - 9
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: Colours.palette.m3onSurface
                border.width: 3
                border.color: Colours.tPalette.m3surfaceContainer
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function set(x: real): void {
                    slider.moved(Math.max(0, Math.min(1, x / width)));
                }

                onPressed: event => set(event.x)
                onPositionChanged: event => {
                    if (pressed)
                        set(event.x);
                }
                onWheel: event => slider.moved(Math.max(0, Math.min(1, slider.v + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }

        StyledText {
            Layout.preferredWidth: 24
            horizontalAlignment: Text.AlignRight
            text: Math.round(slider.v * 100)
            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium })
        }
    }
}
