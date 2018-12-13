#!/sbin/sh

<<LICENSE
  Copyright (C) 2016-2018  ale5000
  This file was created by ale5000 (ale5000-git on GitHub).

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version, w/ zip exception.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
LICENSE

if [[ -z "$INSTALLER" ]]; then
  ui_debug()
  {
    echo "$1"
  }

  delete_recursive()
  {
    if test -e "$1"; then
      ui_debug "Deleting '$1'..."
      rm -rf "$1" || ui_debug "Failed to delete files/folders"
    fi
  }

  delete_recursive_wildcard()
  {
    for filename in "$@"; do
      if test -e "$filename"; then
        ui_debug "Deleting '$filename'...."
        rm -rf "$filename" || ui_debug "Failed to delete files/folders"
      fi
    done
  }

  ui_debug 'Uninstalling...'

  SYS_PATH='/system'
  PRIVAPP_PATH="${SYS_PATH}/app"
  if [[ -d "${SYS_PATH}/priv-app" ]]; then PRIVAPP_PATH="${SYS_PATH}/priv-app"; fi
fi

DELETE_LIST="
${SYS_PATH}/etc/default-permissions/google-sync-permissions.xml

${PRIVAPP_PATH}/CalendarGooglePrebuilt/
${PRIVAPP_PATH}/CalendarGooglePrebuilt.apk

${PRIVAPP_PATH}/GoogleBackupTransport/
${PRIVAPP_PATH}/GoogleBackupTransport.apk
${PRIVAPP_PATH}/GoogleBackupTransport.odex

${PRIVAPP_PATH}/GoogleContactsSyncAdapter/
${PRIVAPP_PATH}/GoogleContactsSyncAdapter.apk
${PRIVAPP_PATH}/GoogleContactsSyncAdapter.odex

${PRIVAPP_PATH}/GoogleCalendarSyncAdapter/
${PRIVAPP_PATH}/GoogleCalendarSyncAdapter.apk
${PRIVAPP_PATH}/GoogleCalendarSyncAdapter.odex

${SYS_PATH}/app/GoogleBackupTransport/
${SYS_PATH}/app/GoogleBackupTransport.apk
${SYS_PATH}/app/GoogleBackupTransport.odex

${SYS_PATH}/app/GoogleContactsSyncAdapter/
${SYS_PATH}/app/GoogleContactsSyncAdapter.apk
${SYS_PATH}/app/GoogleContactsSyncAdapter.odex

${SYS_PATH}/app/GoogleCalendarSyncAdapter/
${SYS_PATH}/app/GoogleCalendarSyncAdapter.apk
${SYS_PATH}/app/GoogleCalendarSyncAdapter.odex
"

rm -rf ${DELETE_LIST}  # Filenames cannot contain spaces

if [[ -z "$INSTALLER" ]]; then
  ui_debug 'Done.'
fi
