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

import org.videolan.medialib 0.1

import "qrc:///utils/" as Utils
import "qrc:///dialogs/" as DG
import "qrc:///style/"

Utils.ExpandGridView {
    id: expandableGV
    signal gridItemClicked(int key,int modifier,variant delegateModelItem)
    signal gridItemContextButtonClicked(Item menuParent,variant delegateModelItem)
    signal gridItemSelectedChanged(bool selected,Item item)

    property Item currentItem: Item{}

    activeFocusOnTab:true
    anchors.fill: parent

    property real expandDelegateImplicitHeight: parent.height
    property real expandDelegateWidth: parent.width

    property real gridDelegatePictureWidth: VLCStyle.video_normal_width
    property real gridDelegatePictureHeight: VLCStyle.video_normal_height


    gridDelegate: Utils.GridItem {
        property variant delegateModelItem: ({
                                                 model: ({}),
                                                 itemsIndex: 0,
                                                 inSelected: false
                                             })

        image: delegateModelItem.model.thumbnail || VLCStyle.noArtCover
        title: delegateModelItem.model.title || qsTr("Unknown title")
        selected: expandableGV.activeFocus && (delegateModelItem.inSelected || contextButtonDown )
        infoLeft: delegateModelItem.model.duration
        resolution: delegateModelItem.model.resolution
        channel: delegateModelItem.model.channel
        isVideo: true
        isNew: delegateModelItem.model.playcount < 1
        progress: delegateModelItem.model.position > 0 ? delegateModelItem.model.position : 0
        shiftX: expandableGV.isSingleRow ? 0 : expandableGV.shiftX(delegateModelItem.model.index)
        pictureWidth: expandableGV.gridDelegatePictureWidth
        pictureHeight: expandableGV.gridDelegatePictureHeight

        onItemClicked : expandableGV.gridItemClicked(key,modifier, delegateModelItem)

        onPlayClicked: medialib.addAndPlay( delegateModelItem.model.id )
        onAddToPlaylistClicked : medialib.addToPlaylist( delegateModelItem.model.id )
        onContextMenuButtonClicked: expandableGV.gridItemContextButtonClicked(menuParent,delegateModelItem)
        onSelectedChanged:expandableGV.gridItemSelectedChanged(selected,this)
    }
    expandDelegate:  Rectangle {
        id: expandRect
        property int currentId: -1
        property var model : ({})
        property alias currentItemY: expandRect.y
        property alias currentItemHeight: expandRect.height
        implicitHeight: expandableGV.expandDelegateImplicitHeight
        width: expandableGV.expandDelegateWidth

        color: "transparent"
        Rectangle{
            id:arrowRect
            x: expandableGV.expanderItem.x + (expandableGV.expanderItem.shiftX/2) + (expandableGV.cellWidth/2)
            y: -(width/2)
            width: VLCStyle.icon_normal
            height: VLCStyle.icon_normal
            color: VLCStyle.colors.text
            rotation: 45
            visible: !expandableGV.isAnimating
        }
        Rectangle{
            height: parent.height
            width: parent.width
            clip: true
            color: VLCStyle.colors.text
            x: expandableGV.contentX

            Rectangle {
                color: "transparent"
                height: parent.height
                anchors {
                    left:parent.left
                    right:parent.right
                }


                Image {
                    id: img
                    anchors.left: parent.left
                    anchors.leftMargin: VLCStyle.margin_large
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.cover_large
                    height: VLCStyle.cover_large
                    fillMode:Image.PreserveAspectFit

                    source: model.thumbnail || ""
                }
                Column{
                    id: infoCol
                    height: childrenRect.height
                    anchors.left:img.right
                    anchors.leftMargin: VLCStyle.margin_normal
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: VLCStyle.margin_small
                    width: 300 * VLCStyle.scale
                    Text{
                        id: newtxt
                        font.pixelSize: VLCStyle.fontSize_normal
                        font.weight: Font.ExtraBold
                        text: "NEW"
                        color: VLCStyle.colors.accent
                        visible: model.playcount < 1
                    }
                    Column{
                        width: parent.width
                        spacing: VLCStyle.margin_xsmall
                        Text{
                            id: title
                            wrapMode: Text.WordWrap
                            font.pixelSize: VLCStyle.fontSize_large
                            font.weight: Font.ExtraBold
                            text: model.title
                            color: VLCStyle.colors.bg
                            width: parent.width
                        }
                        Text {
                            id: time
                            text: model.duration
                            color: VLCStyle.colors.textInactive
                            font.pixelSize: VLCStyle.fontSize_small
                        }
                    }

                    Button {
                        id: playBtn
                        hoverEnabled: true
                        width: VLCStyle.icon_xlarge
                        height: VLCStyle.icon_medium
                        background: Rectangle{
                            color: playBtn.pressed? "#000": VLCStyle.colors.accent
                            width: parent.width
                            height: parent.height
                            radius: playBtn.width/3
                        }
                        contentItem:Item{
                            implicitWidth: childrenRect.width
                            implicitHeight: childrenRect.height
                            anchors.centerIn: playBtn

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                id: icon
                                text:  playBtn.fontIcon
                                font.family: VLCIcons.fontFamily
                                font.pixelSize: parent.height
                                color: playBtn.pressed || playBtn.hovered?  VLCStyle.colors.bg : VLCStyle.colors.bgAlt
                            }


                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: icon.right
                                text: playBtn.text
                                font: playBtn.font
                                color: playBtn.pressed || playBtn.hovered? VLCStyle.colors.bg : VLCStyle.colors.bgAlt

                            }
                        }


                        property string fontIcon: VLCIcons.play

                        text: qsTr("Play Video")
                        onClicked: medialib.addAndPlay( model.id )
                    }
                }

                Column{
                    anchors.left: infoCol.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: childrenRect.height

                    Text {
                        id: fileName
                        text:"File Name: " + model.title; color: VLCStyle.colors.textInactive
                    }


                    Text {
                        id: path
                        text:"Path: " + model.mrl; color: VLCStyle.colors.textInactive
                    }

                    Text {text:"Length: " + model.duration; color: VLCStyle.colors.textInactive}
                    Text {text:"File size: "; color: VLCStyle.colors.textInactive}

                    Text {
                        id: timesPlayed
                        text:"Times played: " + model.playcount; color: VLCStyle.colors.textInactive
                    }

                    Column {
                        Text {text:"Video track:" + model.videoDesc; color: VLCStyle.colors.textInactive}
                        Text {text:"Audio track:" + model.audioDesc; color: VLCStyle.colors.textInactive}
                    }
                }


                Rectangle{
                    anchors.right: parent.right
                    width: 300 * VLCStyle.scale
                    height: parent.height
                    color: VLCStyle.colors.text

                    Column{
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }

                        spacing: VLCStyle.margin_normal
                        Repeater {
                            id:reptr
                            anchors.fill: parent
                            model: ListModel {
                                ListElement {
                                    label: "Rename Video"
                                    ic: "🍕"
                                }
                                ListElement {
                                    label: "Enqueue"
                                    ic: "🍕"
                                }
                                ListElement {
                                    label: "Share"
                                    ic: "🍕"
                                }
                                ListElement {
                                    label: "Delete"
                                    ic: "🗑"
                                }
                            }
                            delegate: Button {
                                id: reptrBtn
                                hoverEnabled: true
                                width: reptr.width
                                background: Rectangle{
                                    color: pressed? "#000": VLCStyle.colors.text
                                    width: parent.width
                                    height: parent.height
                                    radius: 3
                                }
                                contentItem: Item{
                                    implicitWidth: childrenRect.width
                                    implicitHeight: childrenRect.height

                                    Label {
                                        id: icon
                                        text:  reptrBtn.fontIcon
                                        font: VLCIcons.fontFamily
                                        verticalAlignment: Text.AlignVCenter
                                        color: pressed || hovered? VLCStyle.colors.accent : VLCStyle.colors.bgAlt
                                    }


                                    Label {
                                        anchors.left: icon.right
                                        anchors.leftMargin: VLCStyle.margin_normal
                                        text: reptrBtn.text
                                        font: reptrBtn.font
                                        verticalAlignment: Text.AlignVCenter
                                        color: pressed || hovered? VLCStyle.colors.accent : VLCStyle.colors.bgAlt
                                    }
                                }


                                text: label
                                property string fontIcon: ic
                                onClicked: reptr.handleClick(index)
                            }
                            function handleClick(index){
                                switch(index){
                                case 1:medialib.addToPlaylist( expandRect.model.id )
                                    break

                                default:
                                    console.log("you clicked on an unhandled index:",index)
                                }
                            }
                        }
                    }
                }


            }
            Button {
                id: closeBtn
                hoverEnabled: true
                width: VLCStyle.icon_medium
                height: VLCStyle.icon_medium
                anchors.right: parent.right
                background: Rectangle{
                    color: closeBtn.pressed? "#000": VLCStyle.colors.text
                    width: parent.width
                    height: parent.height
                    radius: 3
                }
                contentItem:Label {
                    text: closeBtn.text
                    font: VLCIcons.fontFamily
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: closeBtn.pressed || closeBtn.hovered? VLCStyle.colors.accent : VLCStyle.colors.bgAlt
                }

                text: "X"
                onClicked: expandableGV.retract()
            }

        }

    }

    cellWidth: (VLCStyle.video_normal_width) + VLCStyle.margin_large
    cellHeight: (VLCStyle.video_normal_height) + VLCStyle.margin_xlarge + VLCStyle.margin_normal

    onSelectAll: expandableGV.model.selectAll()
    onSelectionUpdated: expandableGV.model.updateSelection( keyModifiers, oldIndex, newIndex )
    onActionAtIndex: expandableGV.model.actionAtIndex(index)

}
