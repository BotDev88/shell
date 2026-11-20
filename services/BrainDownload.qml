pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// The local brain's download (sylvie-core's sylvie-brain-get). It runs on its own, so it carries on
// when the Welcome tour or the Switchboard closes; this follows its progress file for the
// Switchboard card and the bar's download badge.
Singleton {
    id: root

    // idle | install | start | download | done | error | cancelled
    property string stage: "idle"
    property string text
    property string model
    property real percent
    property real completed
    property real total
    property real speed
    property int eta: -1
    property real updated

    // a run that stopped writing for 15 minutes died (logout, crash): don't show it as running
    readonly property bool active: (stage === "install" || stage === "start" || stage === "download") && Date.now() / 1000 - updated < 900
    // a percentage only once Ollama reports sizes; before that the bar just moves
    readonly property bool measured: stage === "download" && total > 0

    readonly property string detail: {
        if (!measured)
            return "";
        const parts = [`${Math.floor(percent)}%`];
        if (speed > 0)
            parts.push(`${(speed / 1e6).toFixed(1)} MB/s`);
        if (eta >= 0)
            parts.push(eta >= 60 ? qsTr("%1 min left").arg(Math.ceil(eta / 60)) : qsTr("%1 s left").arg(eta));
        return parts.join(" · ");
    }

    function start(name: string): void {
        startProc.command = ["sylvie-brain-get", "start", name];
        startProc.running = true;
    }

    function cancel(): void {
        cancelProc.running = true;
    }

    Process {
        id: startProc
    }

    Process {
        id: cancelProc

        command: ["sylvie-brain-get", "cancel"]
    }

    // the file is replaced whole on every update, which a file watcher can lose track of: look
    // again every second while a download runs (every few seconds otherwise)
    Timer {
        interval: root.active ? 1000 : 4000
        running: true
        repeat: true
        onTriggered: progressFile.reload()
    }

    FileView {
        id: progressFile

        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/sylvie/brain-get.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.stage = s.stage ?? "idle";
                root.text = s.text ?? "";
                root.model = s.model ?? "";
                root.percent = s.percent ?? 0;
                root.completed = s.completed ?? 0;
                root.total = s.total ?? 0;
                root.speed = s.speed ?? 0;
                root.eta = s.eta ?? -1;
                root.updated = s.updated ?? 0;
            } catch (e) {}
        }
    }
}
