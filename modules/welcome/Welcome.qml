pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Sylvie OS Welcome app (Phase 5): opens once on the first login, and any time with
// `caelestia shell welcome open` or `>welcome` in the launcher.
// Pages: Hello → Look (wallpaper + dark/light) → Learn the keys → Additions (incl. the Gaming
// switch) → All set. Additions are installed with sylvie-additions (official sources only;
// nothing is downloaded until you press Install).
Scope {
    id: root

    property bool open
    property list<string> order: ["hello", "look", "keys", "switchboard", "additions", "done"]
    property int lastNotified: 0
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/sylvie`
    readonly property string doneFile: `${stateDir}/welcomed`

    function show(): void {
        order = ["hello", "look", "keys", "switchboard", "additions", "done"];
        open = true;
    }

    function showPage(name: string): void {
        open = false;
        order = [name];
        open = true;
    }

    function finish(): void {
        markDone.running = true;
        open = false;
    }

    // first login: open unless we've been through it before
    FileView {
        path: root.doneFile
        printErrors: false
        onLoadFailed: firstRun.start()
    }

    Timer {
        id: firstRun

        interval: 2500 // let the desktop settle first
        onTriggered: root.show()
    }

    Process {
        id: markDone

        command: ["sh", "-c", `mkdir -p '${root.stateDir}' && touch '${root.doneFile}'`]
    }

    IpcHandler {
        function open(): void {
            root.show();
        }

        // one page on its own: switchboard, additions, keys, look, updates
        function page(name: string): void {
            root.showPage(name);
        }

        target: "welcome"
    }

    // Updates: check 10 minutes after login, then every 6 hours; remind once per new batch
    Timer {
        interval: 6 * 60 * 60 * 1000
        repeat: true
        running: true
        onTriggered: updCheck.running = true
    }

    Timer {
        interval: 10 * 60 * 1000
        running: true
        onTriggered: updCheck.running = true
    }

    Process {
        id: updCheck

        command: ["sylvie-updates", "check"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const st = JSON.parse(text);
                    const n = st.official + st.flatpak;
                    if (n > root.lastNotified)
                        Quickshell.execDetached(["notify-send", "-a", "Sylvie", "-i", "system-software-update", Tr.tr("Updates waiting"), Tr.tr("%1 updates are ready. Type >updates in Launch Control when it suits you.").arg(n)]);
                    root.lastNotified = n;
                } catch (e) {}
            }
        }
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            id: win

            title: Tr.tr("Welcome to Sylvie OS")
            color: Colours.palette.m3surface
            implicitWidth: 980
            implicitHeight: 640
            minimumSize.width: 860
            minimumSize.height: 600

            onVisibleChanged: if (!visible) root.open = false

            WelcomeContent {
                anchors.fill: parent
                order: root.order
                onFinished: root.order.length > 1 ? root.finish() : (root.open = false)
            }
        }
    }
}
