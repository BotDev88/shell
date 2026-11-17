pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    // Sylvie: the stock Sylvie wallpaper is the fallback
    readonly property string fallback: "/usr/share/backgrounds/sylvie/w02.jpg"
    // Sylvie: display names for the stock wallpapers (design/tokens.json)
    readonly property var sylvieNames: ({ w02: "Sunburst", w03: "Poolside", w04: "Rocket", w05: "Prototype 7", w06: "Skyline", w07: "Control Room", w08: "Bloom", w10: "Sylvie" })

    // { num: "08", name: "Bloom" } for a wallpaper path
    function displayInfo(path: string): var {
        const base = String(path).split("/").pop().replace(/\.[^.]+$/, "");
        const m = base.match(/^w(\d+)$/);
        return { num: m ? m[1].padStart(2, "0") : "", name: sylvieNames[base] ?? base.replace(/[-_]+/g, " ") };
    }

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        // Sylvie: pick here so the choice also goes through sylvie-wallpaper
        const others = list.filter(w => w.path !== actualCurrent);
        if (others.length > 0)
            setWallpaper(others[Math.floor(Math.random() * others.length)].path);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        // Sylvie: sylvie-wallpaper paints it (awww for images/GIFs, mpvpaper for video); caelestia
        // records it and, with the dynamic scheme, regenerates the colours
        Quickshell.execDetached(["sylvie-wallpaper", "set", path]);
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images | FileSystemModel.Videos
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
