#!/sbin/sh

<<LICENSE
  Copyright (C) 2016-2018  ale5000
  This file is part of Google Sync Add-on by @ale5000.

  Google Sync Add-on is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version, w/Google Sync Add-on zip exception.

  Google Sync Add-on is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Google Sync Add-on.  If not, see <http://www.gnu.org/licenses/>.
LICENSE

if [[ -z "$INSTALLER" ]]; then
  ui_msg()
  {
    echo "$1"
  }

  ui_msg 'Uninstalling...'

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
  ui_msg 'Done.'
fi
