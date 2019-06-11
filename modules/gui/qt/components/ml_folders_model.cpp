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

#include "ml_folders_model.hpp"
#include <cassert>

MlFoldersModel::MlFoldersModel(vlc_medialibrary_t *p_ml,QObject *parent)
    : QAbstractListModel(parent)
    ,m_ml(p_ml),
      m_ml_event_handle( nullptr, [this](vlc_ml_event_callback_t* cb ) {
             assert( m_ml != nullptr );
             vlc_ml_event_unregister_callback( m_ml, cb );
         })
{
    assert(p_ml);
    update();
}

int MlFoldersModel::rowCount(QModelIndex const & ) const
{
    qInfo("rowCount: %d",m_mrls.count());
    return m_mrls.count();
}
int MlFoldersModel::columnCount(QModelIndex const & ) const
{
    return 3;
}

QVariant MlFoldersModel::data(const QModelIndex &index,
                              int role) const {
    if (!index.isValid())
        return {};
    switch (role)
    {
    case Qt::DisplayRole :
        if (index.column() == 1)
            return QVariant::fromValue(QUrl::fromUserInput(m_mrls[index.row()]).toDisplayString(QUrl::RemovePassword | QUrl::PreferLocalFile | QUrl::NormalizePathSegments) );
        break;
    case CustomCheckBoxRole :
        return (index.row() %2) ? //TODO: if mrl banned?
                    Qt::Checked : Qt::Unchecked;
        break;
    default :
        return {};
    }
}

void MlFoldersModel::removeAt(int index)
{
    qInfo("removing at index: %d",index);
    vlc_ml_remove_folder(m_ml,m_mrls[index].toStdString().c_str());
    update();
}

void MlFoldersModel::add(QString mrl)
{
    qInfo("adding folder: %s",mrl.toStdString().c_str());
    vlc_ml_add_folder(m_ml, mrl.toStdString().c_str());
    update();
}

void MlFoldersModel::update()
{
     qInfo("updating model");
    beginResetModel();

    m_ml_event_handle.reset( vlc_ml_event_register_callback( m_ml, onMlEvent, this ) );

    m_mrls.clear();
    vlc_ml_entry_point_list_t * entrypoints;
    vlc_ml_list_folder (m_ml, &entrypoints);
    for (int i=0;i<entrypoints->i_nb_items;i++)
        m_mrls.append(entrypoints->p_items[i].psz_mrl);

    endResetModel();
}

Qt::ItemFlags MlFoldersModel::flags (const QModelIndex & index) const {
    Qt::ItemFlags defaultFlags = QAbstractListModel::flags(index);
    if (index.isValid()){
        return defaultFlags;
    }
    return defaultFlags;
}

bool MlFoldersModel::setData(const QModelIndex &index,
                                const QVariant &value, int role){
    if(!index.isValid())
        return false;

    else if(role == CustomCheckBoxRole){
        if(value.toBool())
            vlc_ml_unban_folder(m_ml,m_mrls[index.row()].toStdString().c_str());
        else
            vlc_ml_ban_folder(m_ml,m_mrls[index.row()].toStdString().c_str());
    }
    else if(role == CustomRemoveRole){
        qInfo("should remove index: %d",index.row());
        removeAt(index.row());
    }

    return true;
}
void MlFoldersModel::onMlEvent( void* data, const vlc_ml_event_t* event )
{
    auto self = static_cast<MlFoldersModel*>(data);
    self->onMlEvent(event);
}

void MlFoldersModel::onMlEvent( const vlc_ml_event_t* event )
{
    qInfo("onMLEvent");
    if ( event->i_type != VLC_ML_EVENT_DISCOVERY_COMPLETED ) // TODO: this needs to be entry_point_(added / removed events)
        return;

    qInfo("VLC_ML_EVENT_DISCOVERY_COMPLETED");
    vlc_ml_event_unregister_from_callback( m_ml, m_ml_event_handle.release() );
    emit onMLDiscoveryCompleted();
}
