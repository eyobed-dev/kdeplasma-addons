/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 * SPDX-FileCopyrightText: 2022 Ismael Asensio <isma.af@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtGraphs as Graphs

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.weatherdata as WeatherData

ColumnLayout {
    id: root

    property var futureHours: null
    property var futureHoursPoints: null
    property var metaData: null

    property int invalidUnit: 0
    property int displayTemperatureUnit: 0

    readonly property real minimalSpacing: Kirigami.Units.largeSpacing

    readonly property real preferredGraphHeight: Kirigami.Units.iconSizes.enormous

    readonly property int hoursPerDay: root.futureHoursPoints?.hoursPerDay ?? 0
    readonly property int totalDays: root.futureHoursPoints?.totalDays ?? 0
    readonly property int totalHours: root.futureHoursPoints?.totalHours ?? 0

    readonly property real pointSpacing: forecastFlickable.width / Math.max(1, root.hoursPerDay)

    property int currentIndex: 0

    function scrollToIndex(dayIndex) {
        currentIndex = dayIndex;
        const firstPointIndex = dayIndex * root.hoursPerDay;
        const xPosition = Math.max(0, firstPointIndex * root.pointSpacing);
        const xLastPage = forecastFlickable.contentWidth - forecastFlickable.width;
        forecastFlickable.contentX = Math.min(xPosition, xLastPage);
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        PlasmaComponents.ToolButton {
            Layout.fillHeight: true
            icon.name: "go-previous"
            enabled: root.currentIndex > 0
            onClicked: root.scrollToIndex(root.currentIndex - 1)
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "transparent"

            implicitWidth: forecastFlickable.implicitWidth
            implicitHeight: forecastFlickable.implicitHeight

            Flickable {
                id: forecastFlickable

                anchors.fill: parent

                implicitHeight: contentHeight
                contentWidth: forecastGraph.implicitWidth
                contentHeight: forecastGraph.implicitHeight
                clip: true
                interactive: false

                // On layout resize, re-evaluate the current scroll position.
                // This ensures the view stays on the same logical page and prevents
                // contentX from exceeding the last valid scroll position after pageWidth changes.
                onWidthChanged: root.scrollToIndex(root.currentIndex)

                ForecastGraph {
                    id: forecastGraph
                    anchors.fill: parent
                    anchors.topMargin: root.minimalSpacing
                    anchors.bottomMargin: root.minimalSpacing

                    implicitHeight: root.preferredGraphHeight + root.minimalSpacing * 2
                    implicitWidth: forecastFlickable.width * ((root.totalHours - 1) / root.hoursPerDay) + marginLeft * 2

                    marginLeft: root.pointSpacing / 2
                    marginRight: marginLeft

                    pointsModel: root.futureHoursPoints

                    xSection: WeatherData.FutureHoursPoints.Timestamp
                    ySection: WeatherData.FutureHoursPoints.Temperature

                    currentPointIndex: root.currentIndex * root.hoursPerDay + lineItem.pointNumber

                    toolTipTextFunction: function (pointIndex) {
                        if (!root.futureHours) {
                            return "";
                        }
                        let index = root.futureHours.index(pointIndex, 0);
                        return root.futureHours.data(index, WeatherData.FutureHours.Timestamp);
                    }
                }
            }

            Item {
                id: lineItem

                height: parent.height

                property int pointNumber: {
                    const graphPositionX = hoverHandler.point.position.x - forecastGraph.marginRight;
                    if ((graphPositionX % root.pointSpacing) > (root.pointSpacing / 2) || hoverHandler.point.position.x < (root.pointSpacing / 2)) {
                        return Math.ceil(graphPositionX / root.pointSpacing);
                    } else {
                        return Math.floor(graphPositionX / root.pointSpacing);
                    }
                }

                x: {
                    return pointNumber * root.pointSpacing + forecastGraph.marginRight;
                }

                visible: hoverHandler.hovered

                PlasmaComponents.Label {}

                Rectangle {
                    id: cursorLine
                    width: 1
                    height: parent.height
                    color: Kirigami.Theme.highlightColor
                }
            }

            HoverHandler {
                id: hoverHandler
            }
        }

        PlasmaComponents.ToolButton {
            Layout.fillHeight: true
            icon.name: "go-next"
            enabled: root.currentIndex < root.totalDays - 1
            onClicked: root.scrollToIndex(root.currentIndex + 1)
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
        }
    }

    PlasmaComponents.PageIndicator {
        id: indicator

        count: root.totalDays

        currentIndex: root.currentIndex

        Layout.alignment: Qt.AlignHCenter

        visible: count > 1

        delegate: Rectangle {
            width: Math.round(Kirigami.Units.gridUnit * 0.5)
            height: width
            radius: width / 2

            color: index === indicator.currentIndex ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            opacity: index === indicator.currentIndex ? 1.0 : 0.4

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.scrollToIndex(index);
                }
            }

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.shortDuration
                }
            }
        }
    }
}
