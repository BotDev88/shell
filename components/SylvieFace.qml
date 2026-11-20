import QtQuick
import Quickshell
import qs.services

// Sylvie's animated face (Louis's five expressions, 19 Nov 2026), following her state:
//   idle      smile, with a wink every so often
//   listening smirk
//   thinking  eyes up
//   speaking  talks: smile and laugh in turn
//   offline   smirk, faded
// Two images cross-fade, so a change of face is soft. Size it like an Image.
Item {
    id: root

    property string mood: Sylvie.state
    property bool talking: false   // speaking: which of the two talking faces is up
    property bool winking: false

    readonly property string face: {
        switch (root.mood) {
        case "speaking":
            return root.talking ? "laugh" : "smile";
        case "thinking":
            return "thinking";
        case "listening":
        case "offline":
            return "smirk";
        default:
            return root.winking ? "wink" : "smile";
        }
    }

    function sourceFor(name: string): string {
        return Quickshell.shellPath(`assets/sylvie-face/${name}.png`);
    }

    opacity: root.mood === "offline" ? 0.6 : 1

    // two layers: the new face fades in over the old one
    property bool frontIsA: true
    onFaceChanged: {
        if (frontIsA) {
            b.source = sourceFor(face);
            frontIsA = false;
        } else {
            a.source = sourceFor(face);
            frontIsA = true;
        }
    }

    Image {
        id: a

        anchors.fill: parent
        source: root.sourceFor("smile")
        fillMode: Image.PreserveAspectFit
        mipmap: true
        opacity: root.frontIsA ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.mood === "speaking" ? 70 : 220
            }
        }
    }

    Image {
        id: b

        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        mipmap: true
        opacity: root.frontIsA ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: root.mood === "speaking" ? 70 : 220
            }
        }
    }

    // talking: alternate at a speech-like, slightly uneven pace
    Timer {
        running: root.mood === "speaking"
        repeat: true
        interval: root.talking ? 140 : 210
        onTriggered: root.talking = !root.talking
        onRunningChanged: if (!running) root.talking = false
    }

    // idle: a wink now and then
    Timer {
        running: root.mood === "idle" && !root.winking
        interval: 6000 + Math.floor(Math.random() * 6000)
        onTriggered: root.winking = true
    }
    Timer {
        running: root.winking
        interval: 450
        onTriggered: root.winking = false
    }
}
