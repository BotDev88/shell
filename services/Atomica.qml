pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Atomica: the current release theme (atomica-themes). `label` is e.g. "7.0 GEIGER" for the lock
// screen and dashboard; it follows `atomica-theme set` live (it watches ~/.config/atomica/theme).
Singleton {
    id: root

    property string slug: "astro"
    property var release: ({ version: "1.0", codename: "Astro" })
    readonly property string label: `${release.version} ${String(release.codename).toUpperCase()}`
    property var releases: []
    // the wallpaper sylvie-wallpaper last set (a video can't be shown as a still: fallback below)
    property string wallpaper: ""
    readonly property string themeWallpaper: `/usr/share/backgrounds/atomica/${slug}/01.jpg`

    function update(): void {
        const r = root.releases.find(x => x.slug === root.slug);
        if (r)
            root.release = r;
    }

    onSlugChanged: update()

    FileView {
        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/atomica/theme`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.slug = text().trim() || "astro"
    }

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/sylvie/wallpaper`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }

    FileView {
        path: "/usr/share/atomica/themes.json"
        printErrors: false
        onLoaded: {
            try {
                root.releases = JSON.parse(text()).releases;
                root.update();
            } catch (e) {}
        }
    }
}
