#!/sbin/sh

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
