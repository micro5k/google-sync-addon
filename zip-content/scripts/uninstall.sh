#!/sbin/sh
# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

# shellcheck disable=SC3010 # In POSIX sh, [[ ]] is undefined

list_app_filenames()
{
cat <<'EOF'
EOF
}

list_app_data_to_remove()
{
cat <<'EOF'
com.google.android.syncadapters.contacts
com.google.android.syncadapters.calendar
com.google.android.backuptransport
EOF
}

uninstall_list()
{
cat <<'EOF'
GoogleContactsSyncAdapter|com.google.android.syncadapters.contacts
GoogleCalendarSyncAdapter|com.google.android.syncadapters.calendar
CalendarGooglePrebuilt|com.google.android.calendar
GoogleBackupTransport|com.google.android.backuptransport
EOF
}

framework_uninstall_list()
{
cat <<'EOF'
EOF
}

if [[ -z "${INSTALLER}" ]]; then
  ui_debug()
  {
    echo "$1"
  }

  delete_recursive()
  {
    if test -e "$1"; then
      ui_debug "Deleting '$1'..."
      rm -rf -- "$1" || ui_debug "Failed to delete files/folders"
    fi
  }

  delete()
  {
    for filename in "${@?}"; do
      if test -e "${filename?}"; then
        ui_debug "Deleting '${filename?}'...."
        rm -rf -- "${filename:?}" || ui_debug 'Failed to delete files/folders'
      fi
    done
  }

  ui_debug 'Uninstalling...'

  SYS_PATH='/system'
  PRIVAPP_PATH="${SYS_PATH}/app"
  if [[ -d "${SYS_PATH}/priv-app" ]]; then PRIVAPP_PATH="${SYS_PATH}/priv-app"; fi
fi

INTERNAL_MEMORY_PATH='/sdcard0'
if [[ -e '/mnt/sdcard' ]]; then INTERNAL_MEMORY_PATH='/mnt/sdcard'; fi

uninstall_list | while IFS='|' read -r FILENAME INTERNAL_NAME _; do
  if test -n "${INTERNAL_NAME}"; then
    delete_recursive "${SYS_PATH}/etc/permissions/${INTERNAL_NAME}.xml"
    delete_recursive "${SYS_PATH}/etc/sysconfig/sysconfig-${INTERNAL_NAME}.xml"
    delete_recursive "${PRIVAPP_PATH}/${INTERNAL_NAME}"
    delete_recursive "${PRIVAPP_PATH}/${INTERNAL_NAME}.apk"
    delete_recursive "${SYS_PATH}/app/${INTERNAL_NAME}"
    delete_recursive "${SYS_PATH}/app/${INTERNAL_NAME}.apk"
    delete "/data/app/${INTERNAL_NAME}"-*
    delete "/mnt/asec/${INTERNAL_NAME}"-*

    # Legacy xml paths
    delete_recursive "${SYS_PATH}/etc/default-permissions/${INTERNAL_NAME:?}-permissions.xml"
    # Other installers
    delete_recursive "${SYS_PATH}/etc/permissions/privapp-permissions-${INTERNAL_NAME:?}.xml"
    delete_recursive "${SYS_PATH}/etc/default-permissions/default-permissions-${INTERNAL_NAME:?}.xml"

    # App libs
    delete /data/app-lib/"${INTERNAL_NAME:?}"-*

    # Dalvik cache
    delete /data/dalvik-cache/*/data@app@"${INTERNAL_NAME:?}"-*@classes*
    delete /data/dalvik-cache/data@app@"${INTERNAL_NAME:?}"-*@classes*
  fi
  if test -n "${FILENAME}"; then
    delete_recursive "${PRIVAPP_PATH}/${FILENAME}"
    delete_recursive "${PRIVAPP_PATH}/${FILENAME}.apk"
    delete_recursive "${PRIVAPP_PATH}/${FILENAME}.odex"
    delete_recursive "${SYS_PATH}/app/${FILENAME}"
    delete_recursive "${SYS_PATH}/app/${FILENAME}.apk"
    delete_recursive "${SYS_PATH}/app/${FILENAME}.odex"

    delete_recursive "${SYS_PATH}/system_ext/priv-app/${FILENAME}"
    delete_recursive "${SYS_PATH}/system_ext/app/${FILENAME}"
    delete_recursive "/system_ext/priv-app/${FILENAME}"
    delete_recursive "/system_ext/app/${FILENAME}"

    delete_recursive "${SYS_PATH}/product/priv-app/${FILENAME}"
    delete_recursive "${SYS_PATH}/product/app/${FILENAME}"
    delete_recursive "/product/priv-app/${FILENAME}"
    delete_recursive "/product/app/${FILENAME}"

    delete_recursive "${SYS_PATH}/vendor/priv-app/${FILENAME}"
    delete_recursive "${SYS_PATH}/vendor/app/${FILENAME}"
    delete_recursive "/vendor/priv-app/${FILENAME}"
    delete_recursive "/vendor/app/${FILENAME}"

    # Current xml paths
    delete_recursive "${SYS_PATH}/etc/permissions/privapp-permissions-${FILENAME:?}.xml"
    delete_recursive "${SYS_PATH}/etc/default-permissions/default-permissions-${FILENAME:?}.xml"
    # Legacy xml paths
    delete_recursive "${SYS_PATH}/etc/default-permissions/${FILENAME:?}-permissions.xml"

    # Dalvik cache
    delete /data/dalvik-cache/*/system@priv-app@"${FILENAME}"[@\.]*@classes*
    delete /data/dalvik-cache/*/system@app@"${FILENAME}"[@\.]*@classes*
    delete /data/dalvik-cache/system@priv-app@"${FILENAME}"[@\.]*@classes*
    delete /data/dalvik-cache/system@app@"${FILENAME}"[@\.]*@classes*
  fi
done
STATUS="$?"; if test "${STATUS}" -ne 0; then exit "${STATUS}"; fi

framework_uninstall_list | while IFS='|' read -r INTERNAL_NAME _; do
  if test -n "${INTERNAL_NAME}"; then
    delete_recursive "${SYS_PATH}/etc/permissions/${INTERNAL_NAME}.xml"
    delete_recursive "${SYS_PATH}/framework/${INTERNAL_NAME}.jar"
    delete_recursive "${SYS_PATH}/framework/${INTERNAL_NAME}.odex"
    delete "${SYS_PATH}/framework/oat"/*/"${INTERNAL_NAME}.odex"
  fi
done
STATUS="$?"; if test "${STATUS}" -ne 0; then exit "${STATUS}"; fi

list_app_filenames | while read -r FILENAME; do
  if [[ -z "${FILENAME}" ]]; then continue; fi
  delete_recursive "${PRIVAPP_PATH}/${FILENAME}"
  delete_recursive "${PRIVAPP_PATH}/${FILENAME}.apk"
  delete_recursive "${PRIVAPP_PATH}/${FILENAME}.odex"
  delete_recursive "${SYS_PATH}/app/${FILENAME}"
  delete_recursive "${SYS_PATH}/app/${FILENAME}.apk"
  delete_recursive "${SYS_PATH}/app/${FILENAME}.odex"
done

list_app_filenames | while read -r FILENAME; do
  if [[ -z "${FILENAME}" ]]; then continue; fi
  delete /data/dalvik-cache/system@app@"${FILENAME}"[@\.]*@classes*
  delete /data/dalvik-cache/*/system@priv-app@"${FILENAME}"[@\.]*@classes*
  delete /data/dalvik-cache/*/system@app@"${FILENAME}"[@\.]*@classes*
done

list_app_data_to_remove | while read -r FILENAME; do
  if [[ -z "${FILENAME}" ]]; then continue; fi
  delete_recursive "/data/data/${FILENAME}"
  delete '/data/user'/*/"${FILENAME}"
  delete '/data/user_de'/*/"${FILENAME}"
  delete_recursive "${INTERNAL_MEMORY_PATH}/Android/data/${FILENAME}"
done

delete_recursive "${SYS_PATH}"/etc/default-permissions/google-sync-permissions.xml
delete_recursive "${SYS_PATH}"/etc/default-permissions/contacts-calendar-sync.xml

if test -e "${SYS_PATH}/etc/zips"; then rmdir --ignore-fail-on-non-empty -- "${SYS_PATH}/etc/zips"; fi

if [[ -z "${INSTALLER}" ]]; then
  ui_debug 'Done.'
fi
