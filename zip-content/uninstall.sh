#!/sbin/sh
# shellcheck disable=SC3010

# SC3010: In POSIX sh, [[ ]] is undefined

# SPDX-FileCopyrightText: (c) 2016-2019, 2021 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

if [[ -z "${INSTALLER}" ]]; then
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
      if test -e "${filename}"; then
        ui_debug "Deleting '${filename}'...."
        rm -rf "${filename:?}" || ui_debug "Failed to delete files/folders"
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

if [[ -z "${INSTALLER}" ]]; then
  ui_debug 'Done.'
fi
