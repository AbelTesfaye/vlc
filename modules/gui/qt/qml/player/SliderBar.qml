/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

import "qrc:///style/"

Slider {
    id: control
    anchors.margins: VLCStyle.margin_xxsmall
    property bool _isHold: false
    property bool _isSeekPointsShown: true

    Keys.onRightPressed: player.jumpFwd()
    Keys.onLeftPressed: player.jumpBwd()

    Timer {
        id: seekpointTimer
        running: player.hasChapters && !control.hovered && _isSeekPointsShown
        interval: 3000
        onTriggered: control._isSeekPointsShown = false
    }

    Item {
        y: -35 * VLCStyle.scale
        id: timeTooltip
        x: location - (timeIndicatorRect.width / 2)
        visible: control.hovered

        property real location: 0
        property real position: location/control.width

        Rectangle {
            width: 10 * VLCStyle.scale
            height: 10 * VLCStyle.scale

            anchors.horizontalCenter: timeIndicatorRect.horizontalCenter
            anchors.verticalCenter: timeIndicatorRect.bottom

            rotation: 45
            color: VLCStyle.colors.bgAlt
        }

        Rectangle {
            id: timeIndicatorRect
            width: childrenRect.width
            height: 20 * VLCStyle.scale
            color: VLCStyle.colors.bgAlt

            Text {
                text: player.length.scale(timeTooltip.position).toString() +
                      (player.hasChapters ?
                           " - " + player.chapters.getNameAtPosition(timeTooltip.position) : "")
                color: VLCStyle.colors.text
            }
        }
    }

    Connections {

        /* only update the control position when the player position actually change, this avoid the slider
         * to jump around when clicking
         */
        target: player
        enabled: !_isHold
        onPositionChanged: control.value = player.position
    }

    height: control.barHeight + VLCStyle.fontHeight_normal + VLCStyle.margin_xxsmall * 2
    implicitHeight: control.barHeight + VLCStyle.fontHeight_normal + VLCStyle.margin_xxsmall * 2

    topPadding: 0
    leftPadding: 0
    bottomPadding: 0
    rightPadding: 0

    stepSize: 0.01

    property int barHeight: 5

    background: Rectangle {
        id: sliderRect
        width: control.availableWidth
        implicitHeight: control.implicitHeight
        height: implicitHeight
        color: "transparent"

        MouseArea {
            id:sliderRectMouseArea
            anchors.fill: parent
            hoverEnabled: true
            property bool isEntered: false

            onPressed: function (event) {
                control.focus = true
                control._isHold = true
                control.value = event.x / control.width
                player.position = control.value
            }

            onReleased: control._isHold = false

            onPositionChanged: function (event) {
                if (pressed && (event.x <= control.width)) {
                    control.value = event.x / control.width
                    player.position = control.value
                }
                timeTooltip.location = event.x
            }

            onEntered: {
                if(player.hasChapters)
                    control._isSeekPointsShown = true
            }

            onExited: {
                if(player.hasChapters)
                    seekpointTimer.restart()
            }
        }

        Rectangle {
            id: progressRect
            width: control.visualPosition * parent.width
            height: control.barHeight
            color: control.activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.bgHover
            radius: control.barHeight
        }

        Rectangle {
            id: bufferRect
            property int bufferAnimWidth: 100 * VLCStyle.scale
            property int bufferAnimPosition: 0
            property int bufferFrames: 1000
            property alias animateLoading: loadingAnim.running

            height: control.barHeight
            opacity: 0.4
            color: VLCStyle.colors.buffer
            radius: control.barHeight

            states: [
                State {
                    name: "buffering not started"
                    when: player.buffering === 0
                    PropertyChanges {
                        target: bufferRect
                        width: bufferAnimWidth
                        visible: true
                        x: (bufferAnimPosition / bufferFrames) * (parent.width - bufferAnimWidth)
                        animateLoading: true
                    }
                },
                State {
                    name: "time to start playing known"
                    when: player.buffering < 1
                    PropertyChanges {
                        target: bufferRect
                        width: player.buffering * parent.width
                        visible: true
                        x: 0
                        animateLoading: false
                    }
                },
                State {
                    name: "playing from buffer"
                    when: player.buffering === 1
                    PropertyChanges {
                        target: bufferRect
                        width: player.buffering * parent.width
                        visible: false
                        x: 0
                        animateLoading: false
                    }
                }
            ]

            SequentialAnimation on bufferAnimPosition {
                id: loadingAnim
                loops: Animation.Infinite
                PropertyAnimation {
                    from: 0.0
                    to: bufferRect.bufferFrames
                    duration: 2000
                    easing.type: "OutBounce"
                }
                PauseAnimation {
                    duration: 500
                }
                PropertyAnimation {
                    from: bufferRect.bufferFrames
                    to: 0.0
                    duration: 2000
                    easing.type: "OutBounce"
                }
                PauseAnimation {
                    duration: 500
                }
            }
        }

        Text {
            text: player.time.toString()
            color: VLCStyle.colors.text
            font.pixelSize: VLCStyle.fontSize_normal
            anchors {
                bottom: parent.bottom
                bottomMargin: VLCStyle.margin_xxsmall
                left: parent.left
                leftMargin: VLCStyle.margin_xxsmall
            }
        }

        Text {
            text: player.length.toString()
            color: VLCStyle.colors.text
            font.pixelSize: VLCStyle.fontSize_normal
            anchors {
                bottom: parent.bottom
                bottomMargin: VLCStyle.margin_xxsmall
                right: parent.right
                rightMargin: VLCStyle.margin_xxsmall
            }
        }

        RowLayout {
            id: seekpointsRow
            spacing: 0
            visible: player.hasChapters
            Repeater {
                id: seekpointsRptr
                model: player.chapters
                Rectangle {
                    id: seekpointsRect

                    property real position: model.position

                    color: VLCStyle.colors.seekpoint
                    width: 1 * VLCStyle.scale
                    height: control.barHeight
                    x: sliderRect.width * seekpointsRect.position
                }
            }


            OpacityAnimator on opacity {
                from: 1
                to: 0
                running: !control._isSeekPointsShown
            }
            OpacityAnimator on opacity{
                from: 0
                to: 1
                running: control._isSeekPointsShown
            }
        }
    }

    handle: Rectangle {
        visible: control.activeFocus
        x: (control.visualPosition * control.availableWidth) - width / 2
        y: (control.barHeight - width) / 2
        implicitWidth: VLCStyle.margin_small
        implicitHeight: VLCStyle.margin_small
        radius: VLCStyle.margin_small
        color: VLCStyle.colors.accent
    }
}
