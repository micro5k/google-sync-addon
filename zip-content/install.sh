#!/sbin/sh

# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

# shellcheck disable=SC3010
# SC3010: In POSIX sh, [[ ]] is undefined

### INIT ENV ###
export TZ=UTC
export LANG=en_US

unset LANGUAGE
unset LC_ALL
unset UNZIP
unset UNZIP_OPTS
unset UNZIPOPT

### GLOBAL VARIABLES ###

export INSTALLER=1
TMP_PATH="$2"

OLD_ANDROID=false
SYS_PATH=''


### FUNCTIONS ###

# shellcheck source=SCRIPTDIR/inc/common-functions.sh
. "${TMP_PATH}/inc/common-functions.sh"


### CODE ###

SYS_INIT_STATUS=0

if test -f "${ANDROID_ROOT:-/system_root/system}/build.prop"; then
  SYS_PATH="${ANDROID_ROOT:-/system_root/system}"
elif test -f '/system_root/system/build.prop'; then
  SYS_PATH='/system_root/system'
elif test -f '/system/system/build.prop'; then
  SYS_PATH='/system/system'
elif test -f '/system/build.prop'; then
  SYS_PATH='/system'
else
  SYS_INIT_STATUS=1

  if test -n "${ANDROID_ROOT:-}" && test "${ANDROID_ROOT:-}" != '/system_root' && test "${ANDROID_ROOT:-}" != '/system' && mount_partition "${ANDROID_ROOT:-}" && test -f "${ANDROID_ROOT:-}/build.prop"; then
    SYS_PATH="${ANDROID_ROOT:-}"
  elif test -e '/system_root' && mount_partition '/system_root' && test -f '/system_root/system/build.prop'; then
    SYS_PATH='/system_root/system'
  elif test -e '/system' && mount_partition '/system' && test -f '/system/system/build.prop'; then
    SYS_PATH='/system/system'
  elif test -f '/system/build.prop'; then
    SYS_PATH='/system'
  else
    ui_error 'The ROM cannot be found'
  fi
fi

cp -pf "${SYS_PATH}/build.prop" "${TMP_PATH}/build.prop"  # Cache the file for faster access
package_extract_file 'module.prop' "${TMP_PATH}/module.prop"
install_id="$(simple_get_prop 'id' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse id string'
install_version="$(simple_get_prop 'version' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse version string'
install_version_code="$(simple_get_prop 'versionCode' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse version code'

INSTALLATION_SETTINGS_FILE="${install_id}.prop"

PRIVAPP_PATH="${SYS_PATH}/app"
if test -e "${SYS_PATH}/priv-app"; then PRIVAPP_PATH="${SYS_PATH}/priv-app"; fi  # Detect the position of the privileged apps folder

API=$(build_getprop 'build\.version\.sdk')
if [[ "${API}" -ge 24 ]]; then  # 23
  :  ### New Android versions
elif [[ "${API}" -ge 21 ]]; then
  ui_error 'ERROR: Unsupported Android version'
elif [[ "${API}" -ge 19 ]]; then
  OLD_ANDROID=true
elif [[ "${API}" -ge 1 ]]; then
  ui_error 'Your Android version is too old'
else
  ui_error 'Invalid API level'
fi

# Info
ui_msg '------------------'
ui_msg 'Google Sync Add-on'
ui_msg "${install_version}"
ui_msg '(by ale5000)'
ui_msg '------------------'
ui_msg_empty_line
ui_msg "API: ${API}"
ui_msg "System path: ${SYS_PATH}"
ui_msg "Privileged apps: ${PRIVAPP_PATH}"
ui_msg_empty_line

# Extracting
ui_msg 'Extracting...'
custom_package_extract_dir 'files' "${TMP_PATH}"
#custom_package_extract_dir 'addon.d' "${TMP_PATH}"

# Setting up permissions
ui_debug 'Setting up permissions...'
set_std_perm_recursive "${TMP_PATH}/files"
#set_std_perm_recursive "${TMP_PATH}/addon.d"
#set_perm 0 0 0755 "${TMP_PATH}/addon.d/00-1-google-sync.sh"

# Verifying
ui_msg_sameline_start 'Verifying... '
if #verify_sha1 "${TMP_PATH}/files/priv-app/GoogleBackupTransport.apk" '2bdf65e98dbd115473cd72db8b6a13d585a65d8d' &&  # Disabled for now
   verify_sha1 "${TMP_PATH}/files/priv-app/GoogleContactsSyncAdapter.apk" 'd6913b4a2fa5377b2b2f9e43056599b5e987df83' &&
   verify_sha1 "${TMP_PATH}/files/app/GoogleCalendarSyncAdapter.apk" 'aa482580c87a43c83882c05a4757754917d47f32' &&
   verify_sha1 "${TMP_PATH}/files/priv-app-4.4/GoogleBackupTransport.apk" '6f186d368014022b0038ad2f5d8aa46bb94b5c14' &&
   verify_sha1 "${TMP_PATH}/files/app-4.4/GoogleContactsSyncAdapter.apk" '68597be59f16d2e26a79def6fa20bc85d1d2c3b3' &&
   verify_sha1 "${TMP_PATH}/files/app-4.4/GoogleCalendarSyncAdapter.apk" 'cf9fa487dfe0ead8576d6af897687e7fa2ae00fa'
then
  ui_msg_sameline_end 'OK'
else
  ui_msg_sameline_end 'ERROR'
  ui_error 'Verification failed'
fi

# MOUNT /data PARTITION
DATA_INIT_STATUS=0
if test "${TEST_INSTALL:-false}" = 'false' && ! is_mounted '/data'; then
  DATA_INIT_STATUS=1
  mount '/data'
  if ! is_mounted '/data'; then ui_error '/data cannot be mounted'; fi
fi

# Resetting Android runtime permissions
if test "${API}" -ge 23; then
  if test -e '/data/system/users/0/runtime-permissions.xml'; then
    if ! grep -q 'com.google.android.syncadapters.contacts' /data/system/users/*/runtime-permissions.xml; then
      # Purge the runtime permissions to prevent issues when the user flash this on a dirty install
      ui_msg "Resetting legacy Android runtime permissions..."
      delete /data/system/users/*/runtime-permissions.xml
    fi
  fi
  if test -e '/data/misc_de/0/apexdata/com.android.permission/runtime-permissions.xml'; then
    if ! grep -q 'com.google.android.syncadapters.contacts' /data/misc_de/*/apexdata/com.android.permission/runtime-permissions.xml; then
      # Purge the runtime permissions to prevent issues when the user flash this on a dirty install
      ui_msg "Resetting Android runtime permissions..."
      delete /data/misc_de/*/apexdata/com.android.permission/runtime-permissions.xml
    fi
  fi
fi

# Clean previous installations
# shellcheck source=SCRIPTDIR/uninstall.sh
. "${TMP_PATH}/uninstall.sh"

# Configuring default Android permissions
ui_debug 'Configuring default Android permissions...'
if [[ ! -e "${SYS_PATH}/etc/default-permissions" ]]; then
  ui_msg 'Creating the default permissions folder...'
  create_dir "${SYS_PATH}/etc/default-permissions"
fi
copy_dir_content "${TMP_PATH}/files/etc/default-permissions" "${SYS_PATH}/etc/default-permissions"

# UNMOUNT /data PARTITION
if test "${DATA_INIT_STATUS}" = '1'; then unmount '/data'; fi

# Preparing
ui_msg 'Preparing...'

if test "${OLD_ANDROID}" != true; then
  # Move apps into subdirs
  for entry in "${TMP_PATH}/files/priv-app"/*; do
    path_without_ext=$(remove_ext "${entry}")

    create_dir "${path_without_ext}"
    mv -f "${entry}" "${path_without_ext}"/
  done
  for entry in "${TMP_PATH}/files/app"/*; do
    path_without_ext=$(remove_ext "${entry}")

    create_dir "${path_without_ext}"
    mv -f "${entry}" "${path_without_ext}"/
  done
fi

# Installing
ui_msg 'Installing...'
if test "${API}" -lt 26; then
  delete "${TMP_PATH}/files/etc/permissions/privapp-permissions-com.google.android.syncadapters.contacts.xml"
  delete_dir_if_empty "${TMP_PATH}/files/etc/permissions"
fi
if [[ "${API}" -ge 23 ]]; then
  if test -e "${TMP_PATH}/files/etc/permissions"; then copy_dir_content "${TMP_PATH}/files/etc/permissions" "${SYS_PATH}/etc/permissions"; fi
  copy_dir_content "${TMP_PATH}/files/priv-app" "${PRIVAPP_PATH}"
  copy_dir_content "${TMP_PATH}/files/app" "${SYS_PATH}/app"
elif [[ "${API}" -ge 21 ]]; then
  ui_error 'ERROR: Unsupported Android version'
elif [[ "${API}" -ge 19 ]]; then
  copy_dir_content "${TMP_PATH}/files/priv-app-4.4" "${PRIVAPP_PATH}"
  copy_dir_content "${TMP_PATH}/files/app-4.4" "${SYS_PATH}/app"
fi

USED_SETTINGS_PATH="${TMP_PATH}/files/etc/zips"
create_dir "${USED_SETTINGS_PATH}"

{
  echo '# SPDX-FileCopyrightText: none'
  echo '# SPDX-License-Identifier: CC0-1.0'
  echo '# SPDX-FileType: SOURCE'
  echo ''
  echo 'install.type=recovery'
  echo "install.version.code=${install_version_code}"
  echo "install.version=${install_version}"
} > "${USED_SETTINGS_PATH}/${INSTALLATION_SETTINGS_FILE}"
set_perm 0 0 0640 "${USED_SETTINGS_PATH}/${INSTALLATION_SETTINGS_FILE}"

create_dir "${SYS_PATH}/etc/zips"
set_perm 0 0 0750 "${SYS_PATH}/etc/zips"

copy_dir_content "${USED_SETTINGS_PATH}" "${SYS_PATH}/etc/zips"

# Clean legacy file
delete "${SYS_PATH}/etc/zips/google-sync.prop"

# Install survival script
if test -e "${SYS_PATH}/addon.d"; then
  if test "${OLD_ANDROID}" = true; then
    :  ### Not ready yet
  else
    #ui_msg 'Installing survival script...'
    : ### Not ready yet
    #write_file_list "${TMP_PATH}/files" "${TMP_PATH}/files/" "${TMP_PATH}/backup-filelist.lst"
    #replace_line_in_file "${TMP_PATH}/addon.d/00-1-google-sync.sh" '%PLACEHOLDER-1%' "${TMP_PATH}/backup-filelist.lst"
    #copy_file "${TMP_PATH}/addon.d/00-1-google-sync.sh" "$SYS_PATH/addon.d"
  fi
fi

if test "${SYS_INIT_STATUS}" = '1'; then
  if test -e '/system_root'; then unmount '/system_root'; fi
  if test -e '/system'; then unmount '/system'; fi
fi

touch "${TMP_PATH}/installed"
ui_msg 'Installation finished.'
