import QtQuick
import Caelestia.Config
import Caelestia.Models
import Caelestia.Multimedia
import Caelestia.State
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        // Sylvie: the selected horizon is full size, the rest smaller and dimmed
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.55 : 0);
        opacity = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.7 : 0);
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + Tokens.padding.large * 2

    StateLayer {
        id: stateLayer

        radius: 14
        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ClipRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: 14

        implicitWidth: Tokens.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
        }

        Visual {
            anchors.fill: parent
            source: root.modelData.path
            playing: (root.PathView.isCurrentItem && PersistentState.wallpaperPlaying) || stateLayer.containsMouse
        }
    }

    // Sylvie: orange ring around the selected horizon (3px walnut gap, 3px orange)
    Rectangle {
        anchors.centerIn: image
        width: image.width + 12
        height: image.height + 12
        radius: image.radius + 6
        color: "transparent"
        border.width: 3
        border.color: Colours.palette.m3primary
        opacity: root.PathView.isCurrentItem ? 1 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledText {
        id: label

        visible: false // Sylvie: the name shows under the strip instead

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font: Tokens.font.label.medium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
