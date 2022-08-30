#!/sbin/sh

# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

### INIT ENV ###
export TZ=UTC
export LANG=en_US

unset LANGUAGE
unset LC_ALL
unset UNZIP
unset UNZIPOPT
unset UNZIP_OPTS
unset CDPATH

### GLOBAL VARIABLES ###

export INSTALLER=1
TMP_PATH="$2"

OLD_ANDROID=false
SYS_PATH=''


### FUNCTIONS ###

# shellcheck source=SCRIPTDIR/../inc/common-functions.sh
. "${TMP_PATH}/inc/common-functions.sh"


### CODE ###

# Make sure that the commands are still overridden here (most shells don't have the ability to export functions)
if test "${TEST_INSTALL:-false}" != 'false' && test -f "${RS_OVERRIDE_SCRIPT:?}"; then
  # shellcheck source=SCRIPTDIR/../../recovery-simulator/inc/configure-overrides.sh
  . "${RS_OVERRIDE_SCRIPT:?}" || exit "${?}"
fi

# Live setup
live_setup_enabled=false
if test "${LIVE_SETUP_POSSIBLE:?}" = 'true'; then
  if test "${LIVE_SETUP_DEFAULT:?}" != '0'; then
    live_setup_enabled=true
  elif test "${LIVE_SETUP_TIMEOUT:?}" -gt 0; then
    ui_msg '---------------------------------------------------'
    ui_msg 'INFO: Select the VOLUME + key to enable live setup.'
    ui_msg "Waiting input for ${LIVE_SETUP_TIMEOUT} seconds..."
    if "${KEYCHECK_ENABLED}"; then
      choose_keycheck_with_timeout "${LIVE_SETUP_TIMEOUT}"
    else
      choose_read_with_timeout "${LIVE_SETUP_TIMEOUT}"
    fi
    if test "${?}" = '3'; then live_setup_enabled=true; fi
  fi
fi

if test "${live_setup_enabled:?}" = 'true'; then
  ui_msg 'LIVE SETUP ENABLED!'
  if test "${DEBUG_LOG}" = '0'; then
    choose 'Do you want to enable the debug log?' '+) Yes' '-) No'; if test "${?}" = '3'; then export DEBUG_LOG=1; enable_debug_log; fi
  fi
fi

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
API=$(build_getprop 'build\.version\.sdk')

if test "${API}" -ge 19; then  # KitKat or higher
  PRIVAPP_PATH="${SYS_PATH}/priv-app"
else
  PRIVAPP_PATH="${SYS_PATH}/app"
fi
if test ! -e "${PRIVAPP_PATH:?}"; then ui_error 'The priv-app folder does NOT exist'; fi

if test "${API}" -ge 24; then  # 23
  :  ### New Android versions
elif test "${API}" -ge 21; then
  ui_error 'ERROR: Unsupported Android version'
elif test "${API}" -ge 19; then
  OLD_ANDROID=true
elif test "${API}" -ge 1; then
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
ui_msg "Boot mode: ${BOOTMODE:?}"
ui_msg "Android API: ${API:?}"
ui_msg "System path: ${SYS_PATH:?}"
ui_msg "Priv-app path: ${PRIVAPP_PATH:?}"
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
ui_debug ''
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
  sleep 1
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

mount_extra_partitions_silent

# Clean previous installations
delete "${SYS_PATH}/etc/zips/${install_id}.prop"
# shellcheck source=SCRIPTDIR/uninstall.sh
. "${TMP_PATH}/uninstall.sh"

unmount_extra_partitions

# Configuring default Android permissions
ui_debug 'Configuring default Android permissions...'
if ! test -e "${SYS_PATH}/etc/default-permissions"; then
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
if test "${API}" -ge 23; then
  if test -e "${TMP_PATH}/files/etc/permissions"; then copy_dir_content "${TMP_PATH}/files/etc/permissions" "${SYS_PATH}/etc/permissions"; fi
  copy_dir_content "${TMP_PATH}/files/priv-app" "${PRIVAPP_PATH}"
  copy_dir_content "${TMP_PATH}/files/app" "${SYS_PATH}/app"
elif test "${API}" -ge 21; then
  ui_error 'ERROR: Unsupported Android version'
elif test "${API}" -ge 19; then
  copy_dir_content "${TMP_PATH}/files/priv-app-4.4" "${PRIVAPP_PATH}"
  copy_dir_content "${TMP_PATH}/files/app-4.4" "${SYS_PATH}/app"
fi

USED_SETTINGS_PATH="${TMP_PATH}/files/etc/zips"
create_dir "${USED_SETTINGS_PATH}"

{
  echo '# SPDX-FileCopyrightText: none'
  echo '# SPDX-License-Identifier: CC0-1.0'
  echo '# SPDX-FileType: OTHER'
  echo ''
  echo 'install.type=flashable-zip'
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
