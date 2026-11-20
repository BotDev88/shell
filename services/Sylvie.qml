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
    // the mic is open for her wake word ("Sylvie", "Hey Sylvie"; sylvied reports it with the state)
    property bool remoteWake: false
    readonly property bool wakeOn: online && remoteWake
    // a conversation the wake word started: sylvied streams it on the watch connection
    property bool wakeTalk: false
    readonly property bool busy: asker.connected || asker.pending !== "" || wakeTalk

    // [{ role: "user" | "sylvie", text, pending, error, note }
    //  | { role: "confirm", id, text, answer: "" | "yes" | "no" | "expired" }]  (an Amber question)
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

    // push-to-talk: sylvied records until the operator stops talking, transcribes it offline
    // ("heard"), then answers it like a typed question
    function listen(): void {
        if (busy)
            return;
        if (!online) {
            messages = messages.concat([{ role: "sylvie", error: true, text: qsTr("I can't reach my circuits. Sylvie's service isn't running.") }]);
            return;
        }
        messages = messages.concat([{ role: "user", text: qsTr("Listening…"), listening: true }, { role: "sylvie", text: "", pending: true }]);
        asker.pending = JSON.stringify({ op: "listen", session: "panel" });
        asker.connected = true;
        connectTimeout.restart();
    }

    IpcHandler {
        target: "sylvie"

        // `caelestia shell sylvie listen` (Super+Space)
        function listen(): void {
            root.listen();
        }
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

    // the operator's answer to an Amber question; sent on its own connection, since the asking
    // one is busy streaming the reply
    function answer(id: string, yes: bool): void {
        const m = messages.slice();
        const i = m.findIndex(x => x.role === "confirm" && x.id === id);
        if (i < 0 || m[i].answer)
            return;
        m[i] = Object.assign({}, m[i], { answer: yes ? "yes" : "no" });
        messages = m;
        answerSock.pending = JSON.stringify({ op: "answer", id, yes });
        answerSock.connected = true;
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

    // what the watch connection brings besides the state: a wake-word conversation ("session": "panel")
    function wakeEvent(ev: var): void {
        if (ev.type === "wake") {
            wakeTalk = true;
            messages = messages.concat([{ role: "user", text: qsTr("Listening…"), listening: true }, { role: "sylvie", text: "", pending: true }]);
            return;
        }
        if (!wakeTalk)
            return;
        handleEvent(ev);
        if (ev.type === "done" || ev.type === "error")
            wakeTalk = false;
    }

    function handle(line: string): void {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }
        handleEvent(ev);
    }

    function handleEvent(ev: var): void {
        const last = messages[messages.length - 1];
        if (ev.type === "heard") {
            // the "Listening…" bubble becomes what she heard
            const m = messages.slice();
            const i = m.length - 2;
            if (i >= 0 && m[i].role === "user")
                m[i] = { role: "user", text: ev.text || qsTr("(nothing heard)") };
            messages = m;
        } else if (ev.type === "confirm") {
            // the question card goes above the reply she's still writing
            const m = messages.slice();
            m.splice(Math.max(0, m.length - 1), 0, { role: "confirm", id: ev.id, text: ev.text, answer: "" });
            messages = m;
        } else if (ev.type === "confirm_closed") {
            const m = messages.slice();
            const i = m.findIndex(x => x.role === "confirm" && x.id === ev.id);
            if (i >= 0 && !m[i].answer) {
                // answered aloud ("proceed" / "not now"), or nobody answered in time
                m[i] = Object.assign({}, m[i], { answer: ev.yes ? "yes" : ev.how === "timeout" ? "expired" : "no" });
                messages = m;
            }
        } else if (ev.type === "tool") {
            if (ev.app)
                updateLast({ note: qsTr("USING %1…").arg(String(ev.app).toUpperCase()) });
        } else if (ev.type === "text") {
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
                    if (ev.type === "state") {
                        root.remoteState = ev.state;
                        root.remoteWake = ev.wake === true;
                    } else if (ev.session === "panel") {
                        root.wakeEvent(ev);
                    }
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
        id: answerSock

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
            onRead: line => answerSock.connected = false
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
