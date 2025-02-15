#!/sbin/sh
# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

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

  # shellcheck disable=SC2034
  {
    IS_INSTALLATION='false'
    FIRST_INSTALLATION='true'
    API=999
    SYS_PATH="${ANDROID_ROOT:-/system}"
    PRIVAPP_DIRNAME='priv-app'
    DATA_PATH="${ANDROID_DATA:-/data}"
    DEST_PATH="${SYS_PATH:?}"
  }
fi

delete_symlinks()
{
  for filename in "${@}"; do
    if test -h "${filename?}"; then
      ui_debug "Deleting symlink '${filename?}'...."
      rm -f -- "${filename:?}" || ui_debug 'Failed to delete symlink'
    fi
  done
}

delete_folder_content_silent()
{
  if test -e "${1:?}"; then
    find "${1:?}" -mindepth 1 -delete
  fi
}

INTERNAL_MEMORY_PATH='/sdcard0'
if test -e '/mnt/sdcard'; then INTERNAL_MEMORY_PATH='/mnt/sdcard'; fi

uninstall_list | while IFS='|' read -r FILENAME INTERNAL_NAME _; do
  if test -n "${INTERNAL_NAME}"; then
    delete "${SYS_PATH:?}/${PRIVAPP_DIRNAME:?}/${INTERNAL_NAME}"
    delete "${SYS_PATH:?}/${PRIVAPP_DIRNAME:?}/${INTERNAL_NAME}.apk"
    delete "${SYS_PATH:?}/app/${INTERNAL_NAME}"
    delete "${SYS_PATH:?}/app/${INTERNAL_NAME}.apk"
  fi

  if test -n "${FILENAME}"; then
    delete "${SYS_PATH:?}/${PRIVAPP_DIRNAME:?}/${FILENAME}"
    delete "${SYS_PATH:?}/${PRIVAPP_DIRNAME:?}/${FILENAME}.apk"
    delete "${SYS_PATH:?}/${PRIVAPP_DIRNAME:?}/${FILENAME}.odex"
    delete "${SYS_PATH:?}/app/${FILENAME}"
    delete "${SYS_PATH:?}/app/${FILENAME}.apk"
    delete "${SYS_PATH:?}/app/${FILENAME}.odex"

    delete "${SYS_PATH:?}/system_ext/priv-app/${FILENAME}"
    delete "${SYS_PATH:?}/system_ext/app/${FILENAME}"
    delete "/system_ext/priv-app/${FILENAME}"
    delete "/system_ext/app/${FILENAME}"

    delete "${SYS_PATH:?}/product/priv-app/${FILENAME}"
    delete "${SYS_PATH:?}/product/app/${FILENAME}"
    delete "/product/priv-app/${FILENAME}"
    delete "/product/app/${FILENAME}"

    delete "${SYS_PATH:?}/vendor/priv-app/${FILENAME}"
    delete "${SYS_PATH:?}/vendor/app/${FILENAME}"
    delete "/vendor/priv-app/${FILENAME}"
    delete "/vendor/app/${FILENAME}"

    # Dalvik cache
    delete "${DATA_PATH:?}"/dalvik-cache/system@priv-app@"${FILENAME}"[@\.]*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/system@app@"${FILENAME}"[@\.]*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/*/system@priv-app@"${FILENAME}"[@\.]*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/*/system@app@"${FILENAME}"[@\.]*@classes*

    # Delete legacy libs (very unlikely to be present but possible)
    delete "${SYS_PATH:?}/lib64/${FILENAME:?}"
    delete "${SYS_PATH:?}/lib/${FILENAME:?}"
    delete "/vendor/lib64/${FILENAME:?}"
    delete "/vendor/lib/${FILENAME:?}"
    delete "${SYS_PATH:?}/vendor/lib64/${FILENAME:?}"
    delete "${SYS_PATH:?}/vendor/lib/${FILENAME:?}"

    # Current xml paths
    delete "${SYS_PATH:?}/etc/permissions/privapp-permissions-${FILENAME:?}.xml"
    delete "${SYS_PATH:?}/etc/default-permissions/default-permissions-${FILENAME:?}.xml"
    # Legacy xml paths
    delete "${SYS_PATH:?}/etc/default-permissions/${FILENAME:?}-permissions.xml"
  fi

  if test -n "${INTERNAL_NAME}"; then
    # Only delete app updates during uninstallation or first-time installation
    if test "${IS_INSTALLATION:?}" != 'true' || test "${FIRST_INSTALLATION:?}" = 'true'; then
      delete "${DATA_PATH:?}/app/${INTERNAL_NAME}"
      delete "${DATA_PATH:?}/app/${INTERNAL_NAME}.apk"
      delete "${DATA_PATH:?}/app/${INTERNAL_NAME}"-*
      delete "/mnt/asec/${INTERNAL_NAME}"
      delete "/mnt/asec/${INTERNAL_NAME}.apk"
      delete "/mnt/asec/${INTERNAL_NAME}"-*
      # ToDO => Check also /data/app-private /data/app-asec /data/preload

      # App libs
      delete "${DATA_PATH:?}/app-lib/${INTERNAL_NAME:?}"
      delete "${DATA_PATH:?}/app-lib/${INTERNAL_NAME:?}"-*
      delete_symlinks "${DATA_PATH:?}/data/${INTERNAL_NAME:?}/lib"
    fi

    # Dalvik caches
    delete "${DATA_PATH:?}"/dalvik-cache/data@app@"${INTERNAL_NAME:?}"-*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/*/data@app@"${INTERNAL_NAME:?}"-*@classes*
    delete "${DATA_PATH:?}"/dalvik-cache/profiles/"${INTERNAL_NAME:?}"

    # Caches
    delete_folder_content_silent "${DATA_PATH:?}/data/${INTERNAL_NAME:?}/code_cache"
    delete_folder_content_silent "${DATA_PATH:?}/data/${INTERNAL_NAME:?}/cache"
    delete_folder_content_silent "${DATA_PATH:?}/data/${INTERNAL_NAME:?}/app_webview/Cache"
    delete_folder_content_silent "${DATA_PATH:?}/data/${INTERNAL_NAME:?}/app_cache_dg"

    # Legacy xml paths
    delete "${SYS_PATH:?}/etc/default-permissions/${INTERNAL_NAME:?}-permissions.xml"
    # Other installers
    delete "${SYS_PATH:?}/etc/permissions/privapp-permissions-${INTERNAL_NAME:?}.xml"
    delete "${SYS_PATH:?}/etc/permissions/permissions_${INTERNAL_NAME:?}.xml"
    delete "${SYS_PATH:?}/etc/permissions/${INTERNAL_NAME:?}.xml"
    delete "${SYS_PATH:?}/etc/default-permissions/default-permissions-${INTERNAL_NAME:?}.xml"

    delete "${SYS_PATH:?}/etc/sysconfig/sysconfig-${INTERNAL_NAME:?}.xml"
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
  if test -z "${FILENAME}"; then continue; fi
  delete "${DATA_PATH:?}/data/${FILENAME}"
  delete "${DATA_PATH:?}"/user/*/"${FILENAME}"
  delete "${DATA_PATH:?}"/user_de/*/"${FILENAME}"
  delete "${INTERNAL_MEMORY_PATH}/Android/data/${FILENAME}"
done

delete "${SYS_PATH:?}"/etc/default-permissions/google-sync-permissions.xml
delete "${SYS_PATH:?}"/etc/default-permissions/contacts-calendar-sync.xml

# Legacy file
delete "${SYS_PATH:?}/etc/zips/google-sync.prop"

if test -z "${IS_INCLUDED:?}"; then
  ui_debug 'Done.'
fi
