pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Sylvie: the shell's line to sylvied (the per-user assistant service, sylvie-assistant package).
// One socket watches her state for the orb; each question opens its own socket and streams the
// reply into `messages`. The chat panel and the orb only read from here.
Singleton {
    id: root

    // idle | listening | thinking | speaking, as sylvied reports it; "offline" when it isn't running
    readonly property string state: watch.connected ? remoteState : "offline"
    property string remoteState: "idle"
    readonly property bool online: watch.connected
    readonly property bool busy: asker.connected || asker.pending !== ""

    // [{ role: "user" | "sylvie", text, pending, error, note }]
    property var messages: []
    // the brain that will actually answer (sylvied's "effective" brain: the local model when the
    // chosen one has no key); `fallback` is "no key", "no brain" or ""
    property string provider
    property string model
    property string fallback
    readonly property string brainLabel: {
        if (!model)
            return "";
        if (fallback === "no brain")
            return qsTr("NO KEY YET · SEE THE SWITCHBOARD");
        const where = provider === "ollama" ? "LOCAL" : "CLOUD";
        const names = {
            "claude-opus-5-5": "CLAUDE OPUS 5.5",
            "claude-sonnet-5-5": "CLAUDE SONNET 5.5",
            "claude-haiku-5-5": "CLAUDE HAIKU 5.5",
            "claude-fable-5-2": "CLAUDE FABLE 5.2"
        };
        return `${names[model] ?? model.toUpperCase()} · ${where}`;
    }

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/sylvie/sylvied.sock`

    function ask(text: string): void {
        const t = text.trim();
        if (!t || busy)
            return;
        if (!online) {
            messages = messages.concat([{ role: "user", text: t }, { role: "sylvie", error: true, text: qsTr("I can't reach my circuits. Sylvie's service isn't running.") }]);
            return;
        }
        messages = messages.concat([{ role: "user", text: t }, { role: "sylvie", text: "", pending: true }]);
        asker.pending = JSON.stringify({ op: "ask", text: t, session: "panel" });
        asker.connected = true;
        connectTimeout.restart();
    }

    // a socket that never connects reports nothing, so give up on it after a moment
    Timer {
        id: connectTimeout

        interval: 3000
        onTriggered: {
            if (asker.pending && !asker.connected) {
                asker.pending = "";
                root.updateLast({ pending: false, error: true, text: qsTr("I can't reach my circuits. Sylvie's service isn't running.") });
            }
        }
    }

    function clear(): void {
        messages = [];
        oneShot(JSON.stringify({ op: "reset", session: "panel" }));
    }

    function refreshStatus(): void {
        oneShot(JSON.stringify({ op: "status" }));
    }

    function oneShot(line: string): void {
        statusSock.pending = line;
        statusSock.connected = true;
    }

    function updateLast(change: var): void {
        const m = messages.slice();
        if (!m.length || m[m.length - 1].role !== "sylvie")
            return;
        m[m.length - 1] = Object.assign({}, m[m.length - 1], change);
        messages = m;
    }

    function handle(line: string): void {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }
        const last = messages[messages.length - 1];
        if (ev.type === "text") {
            updateLast({ text: (last?.text ?? "") + ev.text });
        } else if (ev.type === "done") {
            provider = ev.provider;
            model = ev.model;
            fallback = ev.fallback ?? "";
            const note = ev.fallback === "offline" ? qsTr("Answered by the local model: you're offline.") : ev.fallback === "no key" ? qsTr("Answered by the local model: there's no key for that brain.") : "";
            updateLast({ pending: false, note });
            asker.connected = false;
        } else if (ev.type === "error") {
            updateLast({ pending: false, error: true, text: ev.message });
            asker.connected = false;
        }
    }

    // state for the orb: one long-lived "watch" connection, retried while sylvied is down
    Socket {
        id: watch

        path: root.socketPath
        connected: true
        onConnectedChanged: {
            if (connected) {
                write('{"op":"watch"}\n');
                flush();
                root.refreshStatus();
            }
        }
        parser: SplitParser {
            onRead: line => {
                try {
                    const ev = JSON.parse(line);
                    if (ev.type === "state")
                        root.remoteState = ev.state;
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: !watch.connected
        onTriggered: watch.connected = true
    }

    // one question at a time; the reply streams in line by line
    Socket {
        id: asker

        property string pending

        path: root.socketPath
        onConnectedChanged: {
            if (connected && pending) {
                write(pending + "\n");
                flush();
                pending = "";
            } else if (!connected && pending) {
                pending = "";
                root.updateLast({ pending: false, error: true, text: qsTr("I can't reach my circuits. Sylvie's service isn't running.") });
            }
        }
        parser: SplitParser {
            onRead: line => root.handle(line)
        }
    }

    Socket {
        id: statusSock

        property string pending

        path: root.socketPath
        onConnectedChanged: {
            if (connected && pending) {
                write(pending + "\n");
                flush();
                pending = "";
            }
        }
        parser: SplitParser {
            onRead: line => {
                try {
                    const ev = JSON.parse(line);
                    if (ev.type === "status") {
                        root.provider = ev.provider ?? "";
                        root.model = ev.model ?? "";
                        root.fallback = ev.fallback ?? "";
                    }
                } catch (e) {}
                statusSock.connected = false;
            }
        }
    }
}
