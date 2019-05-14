import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

import org.videolan.vlc 0.1

import "qrc:///style/"
import "qrc:///utils/" as Utils

Popup {
    id: ratePopup
    property int tickCount: 5

    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnReleaseOutside
    parent: rateBtn
    x: Math.round((parent.width - width) / 2)
    y: Math.round(-height)
    onAboutToShow: function () {
        controlBarView.noAutoHide = true
    }

    onAboutToHide: function () {
        controlBarView.noAutoHide = false
    }
    background: Rectangle {
        color: VLCStyle.colors.bgAlt
    }

    ColumnLayout {

        Layout.preferredWidth: 140 * VLCStyle.scale
        ColumnLayout {
            spacing: 0
            RowLayout {
                Slider {
                    id: rateSlider
                    focus: true

                    focusPolicy: "StrongFocus"
                    KeyNavigation.down: rateNormalBtn
                    Layout.preferredHeight: 10 * VLCStyle.scale
                    Layout.preferredWidth: 140 * VLCStyle.scale
                    to: 2
                    from: 0
                    value: player.rate
                    onMoved: function () {
                        player.setRate(rateSlider.value)
                    }
                    property int barHeight: 5

                    background: Rectangle {
                        width: rateSlider.availableWidth
                        color: "transparent"

                        Rectangle {
                            width: rateSlider.visualPosition * parent.width
                            height: rateSlider.barHeight
                            color: rateSlider.activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.bgHover
                            radius: rateSlider.barHeight
                        }
                    }

                    handle: Rectangle {
                        visible: rateSlider.activeFocus
                        x: (rateSlider.visualPosition * rateSlider.availableWidth) - width / 2
                        y: (rateSlider.barHeight - width) / 2
                        implicitWidth: VLCStyle.margin_small
                        implicitHeight: VLCStyle.margin_small
                        radius: VLCStyle.margin_small
                        color: VLCStyle.colors.accent
                    }
                }
            }
            RowLayout {
                spacing: (availableWidth / (tickCount - 1)) - (1 * VLCStyle.scale)
                Repeater {
                    id: ticksRptr
                    model: tickCount
                    Rectangle {
                        color: VLCStyle.colors.textInactive
                        width: 1 * VLCStyle.scale
                        height: 3 * VLCStyle.scale
                        y: ticksRptr.height
                    }
                }
            }
        }
        RowLayout {
            Button {
                id: rateSlowerBtn
                checked: true

                focusPolicy: "StrongFocus"
                KeyNavigation.right: rateNormalBtn
                Layout.preferredWidth: 26 * VLCStyle.scale
                Layout.preferredHeight: 16 * VLCStyle.scale
                text: VLCIcons.slower
                font.family: VLCIcons.fontFamily
                onClicked: player.slower()
                background: Rectangle {
                    color: "transparent"
                }
                palette {
                    buttonText: activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.text
                }
            }
            Item {
                Layout.fillWidth: true
            }

            Button {
                id: rateNormalBtn
                focusPolicy: "StrongFocus"
                KeyNavigation.right: rateFasterBtn
                Layout.preferredWidth: 26 * VLCStyle.scale
                Layout.preferredHeight: 16 * VLCStyle.scale
                text: "1x"
                onClicked: player.normalRate()
                background: Rectangle {
                    color: "transparent"
                }
                palette {
                    buttonText: activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.text
                }
            }
            Item {
                Layout.fillWidth: true
            }

            Button {
                id: rateFasterBtn
                focusPolicy: "StrongFocus"
                Layout.preferredWidth: 26 * VLCStyle.scale
                Layout.preferredHeight: 16 * VLCStyle.scale
                text: VLCIcons.faster
                font.family: VLCIcons.fontFamily
                onClicked: player.faster()
                background: Rectangle {
                    color: "transparent"
                }
                palette {
                    buttonText: activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.text
                }
            }
        }
    }
}
