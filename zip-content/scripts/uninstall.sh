#!/sbin/sh
# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

# shellcheck disable=SC3010 # In POSIX sh, [[ ]] is undefined

list_app_data_to_remove()
{
  cat << 'EOF'
com.google.android.syncadapters.contacts
com.google.android.syncadapters.calendar
com.google.android.backuptransport
EOF
}

uninstall_list()
{
  cat << 'EOF'
GoogleContactsSyncAdapter|com.google.android.syncadapters.contacts
GoogleCalendarSyncAdapter|com.google.android.syncadapters.calendar
CalendarGooglePrebuilt|com.google.android.calendar
GoogleBackupTransport|com.google.android.backuptransport
EOF
}

framework_uninstall_list()
{
  cat << 'EOF'
EOF
}

if test "${IS_INCLUDED:-false}" = 'false'; then
  ui_error()
  {
    printf 1>&2 '\033[1;31m%s\033[0m\n' "ERROR: ${1?}"
    exit 1
  }

  ui_debug()
  {
    printf '%s\n' "${1?}"
  }

  delete()
  {
    for filename in "${@}"; do
      if test -e "${filename?}"; then
        ui_debug "Deleting '${filename?}'...."
        rm -rf -- "${filename:?}" || ui_debug 'Failed to delete files/folders'
      fi
    done
  }

  ui_debug 'Uninstalling...'

  SYS_PATH="${ANDROID_ROOT:-/system}"
  PRIVAPP_PATH="${SYS_PATH}/app"
  if test -e "${SYS_PATH}/priv-app"; then PRIVAPP_PATH="${SYS_PATH}/priv-app"; fi
  DATA_PATH="${ANDROID_DATA:-/data}"
fi

track_init()
{
  REALLY_DELETED='false'
}

track_really_deleted()
{
  if test "${REALLY_DELETED:?}" = 'true'; then
    return 0
  fi
  return 1
}

delete_tracked()
{
  for filename in "${@}"; do
    if test -e "${filename?}"; then
      REALLY_DELETED='true'
      ui_debug "Deleting '${filename?}'...."
      rm -rf -- "${filename:?}" || ui_error 'Failed to delete files/folders'
    fi
  done
}

INTERNAL_MEMORY_PATH='/sdcard0'
if [[ -e '/mnt/sdcard' ]]; then INTERNAL_MEMORY_PATH='/mnt/sdcard'; fi

uninstall_list | while IFS='|' read -r FILENAME INTERNAL_NAME DEL_SYS_APPS_ONLY _; do
  track_init

  if test -n "${INTERNAL_NAME}"; then
    delete "${SYS_PATH}/etc/permissions/${INTERNAL_NAME}.xml"
    delete "${SYS_PATH}/etc/sysconfig/sysconfig-${INTERNAL_NAME}.xml"
    delete_tracked "${PRIVAPP_PATH}/${INTERNAL_NAME}"
    delete_tracked "${PRIVAPP_PATH}/${INTERNAL_NAME}.apk"
    delete_tracked "${SYS_PATH}/app/${INTERNAL_NAME}"
    delete_tracked "${SYS_PATH}/app/${INTERNAL_NAME}.apk"

    # Legacy xml paths
    delete "${SYS_PATH}/etc/default-permissions/${INTERNAL_NAME:?}-permissions.xml"
    # Other installers
    delete "${SYS_PATH}/etc/permissions/${INTERNAL_NAME:?}.xml"
    delete "${SYS_PATH}/etc/permissions/privapp-permissions-${INTERNAL_NAME:?}.xml"
    delete "${SYS_PATH}/etc/default-permissions/default-permissions-${INTERNAL_NAME:?}.xml"

    # App libs
    delete "${DATA_PATH:?}"/app-lib/"${INTERNAL_NAME:?}"-*

    # Dalvik cache
    delete "${DATA_PATH:?}"/dalvik-cache/*/data@app@"${INTERNAL_NAME:?}"-*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/data@app@"${INTERNAL_NAME:?}"-*@classes*
  fi

  if test -n "${FILENAME}"; then
    delete_tracked "${PRIVAPP_PATH}/${FILENAME}"
    delete_tracked "${PRIVAPP_PATH}/${FILENAME}.apk"
    delete_tracked "${PRIVAPP_PATH}/${FILENAME}.odex"
    delete_tracked "${SYS_PATH}/app/${FILENAME}"
    delete_tracked "${SYS_PATH}/app/${FILENAME}.apk"
    delete_tracked "${SYS_PATH}/app/${FILENAME}.odex"

    delete_tracked "${SYS_PATH}/system_ext/priv-app/${FILENAME}"
    delete_tracked "${SYS_PATH}/system_ext/app/${FILENAME}"
    delete_tracked "/system_ext/priv-app/${FILENAME}"
    delete_tracked "/system_ext/app/${FILENAME}"

    delete_tracked "${SYS_PATH}/product/priv-app/${FILENAME}"
    delete_tracked "${SYS_PATH}/product/app/${FILENAME}"
    delete_tracked "/product/priv-app/${FILENAME}"
    delete_tracked "/product/app/${FILENAME}"

    delete_tracked "${SYS_PATH}/vendor/priv-app/${FILENAME}"
    delete_tracked "${SYS_PATH}/vendor/app/${FILENAME}"
    delete_tracked "/vendor/priv-app/${FILENAME}"
    delete_tracked "/vendor/app/${FILENAME}"

    # Current xml paths
    delete "${SYS_PATH}/etc/permissions/privapp-permissions-${FILENAME:?}.xml"
    delete "${SYS_PATH}/etc/default-permissions/default-permissions-${FILENAME:?}.xml"
    # Legacy xml paths
    delete "${SYS_PATH}/etc/default-permissions/${FILENAME:?}-permissions.xml"

    # Dalvik cache
    delete "${DATA_PATH:?}"/dalvik-cache/*/system@priv-app@"${FILENAME}"[@\.]*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/*/system@app@"${FILENAME}"[@\.]*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/system@priv-app@"${FILENAME}"[@\.]*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/system@app@"${FILENAME}"[@\.]*@classes*
  fi

  if test -n "${INTERNAL_NAME}"; then
    if test "${DEL_SYS_APPS_ONLY:-false}" = false || track_really_deleted; then
      delete "${DATA_PATH:?}/app/${INTERNAL_NAME}"
      delete "${DATA_PATH:?}/app/${INTERNAL_NAME}.apk"
      delete "${DATA_PATH:?}/app/${INTERNAL_NAME}"-*
      delete "/mnt/asec/${INTERNAL_NAME}"
      delete "/mnt/asec/${INTERNAL_NAME}.apk"
      delete "/mnt/asec/${INTERNAL_NAME}"-*
    fi
    # Check also /data/app-private /data/app-asec /data/preload
  fi
done
STATUS="$?"
if test "${STATUS}" -ne 0; then exit "${STATUS}"; fi

framework_uninstall_list | while IFS='|' read -r INTERNAL_NAME _; do
  if test -n "${INTERNAL_NAME}"; then
    delete "${SYS_PATH:?}/etc/permissions/${INTERNAL_NAME:?}.xml"
    delete "${SYS_PATH:?}/framework/${INTERNAL_NAME:?}.jar"
    delete "${SYS_PATH:?}/framework/${INTERNAL_NAME:?}.odex"
    delete "${SYS_PATH:?}"/framework/oat/*/"${INTERNAL_NAME:?}.odex"

    # Dalvik cache
    delete "${DATA_PATH:?}"/dalvik-cache/*/system@framework@"${INTERNAL_NAME:?}".jar@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/*/system@framework@"${INTERNAL_NAME:?}".odex@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/system@framework@"${INTERNAL_NAME:?}".jar@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/system@framework@"${INTERNAL_NAME:?}".odex@classes*
  fi
done
STATUS="$?"
if test "${STATUS}" -ne 0; then exit "${STATUS}"; fi

list_app_data_to_remove | while IFS='|' read -r FILENAME; do
  if [[ -z "${FILENAME}" ]]; then continue; fi
  delete "${DATA_PATH:?}/data/${FILENAME}"
  delete "${DATA_PATH:?}"/user/*/"${FILENAME}"
  delete "${DATA_PATH:?}"/user_de/*/"${FILENAME}"
  delete "${INTERNAL_MEMORY_PATH}/Android/data/${FILENAME}"
done

delete "${SYS_PATH}"/etc/default-permissions/google-sync-permissions.xml
delete "${SYS_PATH}"/etc/default-permissions/contacts-calendar-sync.xml

# Legacy file
delete "${SYS_PATH:?}/etc/zips/google-sync.prop"

if test -e "${SYS_PATH:?}/etc/zips"; then rmdir --ignore-fail-on-non-empty -- "${SYS_PATH:?}/etc/zips" || true; fi

if test -z "${IS_INCLUDED}"; then
  ui_debug 'Done.'
fi
