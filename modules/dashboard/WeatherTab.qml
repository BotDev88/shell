pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils

// Sylvie weather tab (design/Sylvie OS Interactive.dc.html): a 300px tile with the big
// temperature, condition icon in gold, "<condition> over <city>", humidity, wind, sunrise and
// sunset; beside it a five-day forecast in a hairline frame (day, icon, high, low).
RowLayout {
    id: root

    readonly property color dim: Colours.palette.m3onSurfaceVariant
    readonly property var days: (Weather.forecast ?? []).slice(0, 5)

    function iconColour(icon: string): color {
        if (/sunny|clear/.test(icon))
            return Colours.palette.m3secondary;
        if (/rain|thunder|snow|grain|weather_hail|ac_unit/.test(icon))
            return Colours.palette.m3tertiary;
        if (/partly/.test(icon))
            return Colours.palette.m3secondary;
        return root.dim;
    }

    spacing: 12

    Component.onCompleted: Weather.reload()

    StyledRect {
        Layout.preferredWidth: 300
        Layout.fillHeight: true
        implicitHeight: now.implicitHeight + 44
        color: Colours.tPalette.m3surfaceContainer
        radius: 20

        ColumnLayout {
            id: now

            anchors.fill: parent
            anchors.margins: 22
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: Weather.cc ? Weather.formatTemp(Weather.cc.tempC, true) : "--°"
                    font: Qt.font({ family: "Josefin Sans", pixelSize: 84, weight: Font.Bold, italic: true })
                }

                MaterialIcon {
                    text: Weather.icon
                    color: root.iconColour(Weather.icon)
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(2.2).build()
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.city ? Tr.tr("%1 over %2").arg(Weather.description).arg(Weather.city) : Weather.description
                wrapMode: Text.WordWrap
                font: Qt.font({ family: "Josefin Sans", pixelSize: 18, weight: Font.DemiBold })
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                columns: 2
                rowSpacing: 6
                columnSpacing: 12

                Fact {
                    text: Tr.tr("HUMIDITY %1%").arg(Weather.humidity)
                }
                Fact {
                    text: Tr.tr("WIND %1 KM/H").arg(Math.round(Weather.windSpeed))
                }
                Fact {
                    text: Tr.tr("SUNRISE %1").arg(Weather.sunrise)
                }
                Fact {
                    text: Tr.tr("SUNSET %1").arg(Weather.sunset)
                }
            }
        }
    }

    // forecast
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 540
        radius: 20
        color: "transparent"
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            Repeater {
                model: root.days

                Item {
                    id: day

                    required property var modelData
                    required property int index

                    readonly property string icon: Icons.getWeatherIcon(modelData.weatherCode)

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 108

                    Rectangle {
                        visible: day.index > 0
                        width: 1
                        height: parent.height
                        color: Colours.palette.m3outlineVariant
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Tr.formatDateTime(new Date(day.modelData.date), "ddd").toUpperCase()
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, weight: Font.Medium, letterSpacing: 2.2 })
                            color: root.dim
                        }

                        MaterialIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: day.icon
                            color: root.iconColour(day.icon)
                            fontStyle: Tokens.font.icon.builders.extraLarge.build()
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.formatTemp(day.modelData.maxTempC, true)
                            font: Qt.font({ family: "Josefin Sans", pixelSize: 26, weight: Font.Bold, italic: true })
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Weather.formatTemp(day.modelData.minTempC, true)
                            font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11 })
                            color: root.dim
                        }
                    }
                }
            }

            StyledText {
                visible: root.days.length === 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Tr.tr("NO FORECAST YET")
                font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, letterSpacing: 2.2 })
                color: root.dim
            }
        }
    }

    component Fact: StyledText {
        Layout.fillWidth: true
        font: Qt.font({ family: "IBM Plex Mono", pixelSize: 11, letterSpacing: 0.9 })
        color: root.dim
    }
}
