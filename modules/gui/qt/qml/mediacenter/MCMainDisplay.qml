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
import org.videolan.medialib 0.1
import org.videolan.vlc 0.1

import "qrc:///style/"
import "qrc:///qml/"
import "qrc:///utils/" as Utils
import "qrc:///playlist/" as PL

Utils.NavigableFocusScope {
    id: root

    //name and properties of the tab to be initially loaded
    property string view: ""
    property var viewProperties: ({})

    Component {
        id: musicComp
        MCMusicDisplay {}
    }

    Component {
        id: videoComp
        MCVideoDisplay {}
    }

    Component {
        id: networkComp
        MCNetworkDisplay {}
    }

    readonly property var pageModel: [
        {
            displayText: qsTr("Video"),
            icon: VLCIcons.topbar_video,
            name: "video",
            component: videoComp
        }, {
            displayText: qsTr("Music"),
            icon: VLCIcons.topbar_music,
            name: "music",
            component: musicComp
        }, {
            displayText: qsTr("Network"),
            icon: VLCIcons.topbar_network,
            name: "network",
            component: networkComp
        }
    ]

    property var tabModel: ListModel {
        id: tabModelid
        Component.onCompleted: {
            pageModel.forEach(function(e) {
                append({
                   displayText: e.displayText,
                   icon: e.icon,
                   name: e.name,
               })
            })
        }
    }

    Rectangle {
        color: VLCStyle.colors.bg
        anchors.fill: parent

        Utils.NavigableFocusScope {
            focus: true
            id: medialibId
            anchors.fill: parent
            onActionRight: rootWindow.playlistVisible = true

            ColumnLayout {
                id: column
                anchors.fill: parent

                Layout.minimumWidth: VLCStyle.minWidthMediacenter
                spacing: 0

                /* Source selection*/
                BannerSources {
                    id: sourcesBanner

                    Layout.preferredHeight: height
                    Layout.minimumHeight: height
                    Layout.maximumHeight: height
                    Layout.fillWidth: true

                    focus: true
                    model: root.tabModel

                    onItemClicked: {
                        sourcesBanner.subTabModel = undefined

                        var name = root.tabModel.get(index).name
                        stackView.replace(root.pageModel[index].component)
                        history.push(["mc", name], History.Stay)

                        subTabModel = stackView.currentItem.tabModel
                        sortModel = stackView.currentItem.sortModel
                        contentModel = stackView.currentItem.contentModel

                        selectedIndex = index
                    }

                    onSubItemClicked: {
                        subSelectedIndex = index
                        stackView.currentItem.loadIndex(index)
                        sortModel = stackView.currentItem.sortModel
                        contentModel = stackView.currentItem.contentModel
                    }

                    onActionDown: stackView.focus = true
                    onActionLeft: root.actionLeft(index)
                    onActionRight: root.actionRight(index)
                    onActionUp: root.actionUp(index)
                    onActionCancel: root.actionCancel(index)
                }

                Utils.StackViewExt {
                    id: stackView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Component.onCompleted: {
                        var found = stackView.loadView(root.pageModel, root.view, root.viewProperties)
                        sourcesBanner.subTabModel = stackView.currentItem.tabModel
                        sourcesBanner.sortModel = stackView.currentItem.sortModel
                        sourcesBanner.contentModel = stackView.currentItem.contentModel
                        // Restore sourcesBanner state
                        sourcesBanner.selectedIndex = pageModel.findIndex(function (e) {
                            return e.name === root.view
                        })
                        if (stackView.currentItem.pageModel !== undefined)
                            sourcesBanner.subSelectedIndex = stackView.currentItem.pageModel.findIndex(function (e) {
                                return e.name === stackView.currentItem.view
                            })
                    }

                    Utils.Drawer {
                        z: 1
                        id: playlist
                        anchors {
                            top: parent.top
                            right: parent.right
                            bottom: parent.bottom
                        }
                        focus: false
                        expandHorizontally: true

                        state: (rootWindow.playlistDocked && rootWindow.playlistVisible) ? "visible" : "hidden"
                        onVisibleChanged: {
                            if (playlist.visible)
                                playlist.forceActiveFocus()
                        }
                        component: Rectangle {
                            color: VLCStyle.colors.setColorAlpha(VLCStyle.colors.banner, 0.9)
                            width: root.width/3
                            height: playlist.height

                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: false
                                hoverEnabled: true
                                preventStealing: true
                                onWheel: event.accepted = true

                                PL.PlaylistListView {
                                    id: playlistView
                                    focus: true
                                    anchors.fill: parent
                                    onActionLeft: playlist.closeAndFocus(stackView.currentItem)
                                    onActionCancel: playlist.closeAndFocus(stackView.currentItem)
                                    onActionUp: playlist.closeAndFocus(sourcesBanner)
                                }
                            }
                        }
                        function closeAndFocus(item){
                            if (!item)
                                return

                            rootWindow.playlistVisible = false
                            item.forceActiveFocus()
                        }
                    }
                }
            }

            Connections {
                target: stackView.currentItem
                ignoreUnknownSignals: true

                onActionUp: sourcesBanner.focus = true
                onActionCancel: sourcesBanner.focus = true

                onActionLeft:   medialibId.actionLeft(index)
                onActionRight:  medialibId.actionRight(index)
                onActionDown:   medialibId.actionDown(index)
            }
        }

    }
}
