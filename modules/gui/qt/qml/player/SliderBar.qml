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

import "qrc:///style/"

Slider {
    id: control
    anchors.margins: VLCStyle.margin_xxsmall

    Keys.onRightPressed: player.jumpFwd()
    Keys.onLeftPressed: player.jumpBwd()

    Item {
        id: timeTooltip
        property real location: 0
        property real position: location/control.width

        y: -35 * VLCStyle.scale
        x: location - (timeIndicatorRect.width / 2)
        visible: control.hovered

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
            width: 50 * VLCStyle.scale
            height: 20 * VLCStyle.scale
            color: VLCStyle.colors.bgAlt

            Text {
                anchors.centerIn: parent
                text: (player.length.scale(timeTooltip.position).toString())
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
        width: control.availableWidth
        implicitHeight: control.implicitHeight
        height: implicitHeight
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

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
        }

        Rectangle {
            width: control.visualPosition * parent.width
            height: control.barHeight
            color: control.activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.bgHover
            radius: control.barHeight
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
