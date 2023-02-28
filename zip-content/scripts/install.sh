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

# shellcheck disable=SC3040,SC2015
{
  # Unsupported set -o options may cause the shell to exit (even without set -e), so first try them in a subshell to avoid this issue and also handle the set -e case
  (set -o posix 2> /dev/null) && set -o posix || true
  (set -o pipefail) && set -o pipefail || true
}

### GLOBAL VARIABLES ###

TMP_PATH="$2"

### FUNCTIONS ###

# shellcheck source=SCRIPTDIR/../inc/common-functions.sh
. "${TMP_PATH}/inc/common-functions.sh" || exit "${?}"

### CODE ###

initialize

package_extract_file 'module.prop' "${TMP_PATH}/module.prop"
install_id="$(simple_get_prop 'id' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse id string'
install_version="$(simple_get_prop 'version' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse version string'
install_version_code="$(simple_get_prop 'versionCode' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse version code'
install_author="$(simple_get_prop 'author' "${TMP_PATH}/module.prop")" || ui_error 'Failed to parse author string'

INSTALLATION_SETTINGS_FILE="${install_id}.prop"
API="$(build_getprop 'build\.version\.sdk')"
readonly API

if test "${API:?}" -ge 19; then # KitKat or higher
  PRIVAPP_FOLDER='priv-app'
else
  PRIVAPP_FOLDER='app'
fi
PRIVAPP_PATH="${SYS_PATH:?}/${PRIVAPP_FOLDER:?}"
readonly PRIVAPP_FOLDER PRIVAPP_PATH
if test ! -e "${PRIVAPP_PATH:?}"; then ui_error 'The priv-app folder does NOT exist'; fi

if test "${API:?}" -ge 24; then
  : ### Supported Android versions
elif test "${API:?}" -ge 21; then
  ui_error 'ERROR: Unsupported Android version'
elif test "${API:?}" -ge 19; then
  :
elif test "${API:?}" -ge 1; then
  ui_error 'Your Android version is too old'
else
  ui_error 'Invalid API level'
fi

# Info
ui_msg '------------------'
ui_msg 'Google Sync add-on'
ui_msg "${install_version:?}"
ui_msg "(by ${install_author:?})"
ui_msg '------------------'
ui_msg "Boot mode: ${BOOTMODE:?}"
ui_msg "Sideload: ${SIDELOAD:?}"
ui_msg "Zip install: ${ZIP_INSTALL:?}"
ui_msg "Recovery API ver: ${RECOVERY_API_VER:-}"
ui_msg_empty_line
ui_msg "Android API: ${API:?}"
ui_msg_empty_line
ui_msg "Dynamic partitions: ${DYNAMIC_PARTITIONS:?}"
ui_msg "Current slot: ${SLOT:-no slot}"
ui_msg "Recov. fake system: ${RECOVERY_FAKE_SYSTEM:?}"
ui_msg_empty_line
ui_msg "System mount point: ${SYS_MOUNTPOINT:?}"
ui_msg "System path: ${SYS_PATH:?}"
ui_msg "Priv-app path: ${PRIVAPP_PATH:?}"
ui_msg_empty_line
ui_msg "Android root ENV: ${ANDROID_ROOT:-}"
ui_msg '------------------'
ui_msg_empty_line

# Extracting
ui_msg 'Extracting...'
custom_package_extract_dir 'origin' "${TMP_PATH:?}"
custom_package_extract_dir 'files' "${TMP_PATH:?}"
custom_package_extract_dir 'addon.d' "${TMP_PATH:?}"

# Setting up permissions
ui_debug 'Setting up permissions...'
set_std_perm_recursive "${TMP_PATH:?}/origin"
set_std_perm_recursive "${TMP_PATH:?}/files"
if test -e "${TMP_PATH:?}/addon.d"; then set_std_perm_recursive "${TMP_PATH:?}/addon.d"; fi
set_perm 0 0 0755 "${TMP_PATH:?}/addon.d/00-1-google-sync.sh"

setup_app 1 'Google Backup Transport 4.4' 'GoogleBackupTransport44' 'priv-app' false false

setup_app 1 'Google Contacts Sync 4.4' 'GoogleContactsSyncAdapter44' 'app'
setup_app 1 'Google Contacts Sync 8.1' 'GoogleContactsSyncAdapter8' 'priv-app'
setup_app 1 'Google Calendar Sync 5.2' 'GoogleCalendarSyncAdapter5' 'app'
setup_app 1 'Google Calendar Sync 6.0' 'GoogleCalendarSyncAdapter6' 'app'

delete "${TMP_PATH:?}/origin"

# Resetting Android runtime permissions
if test "${API}" -ge 23; then
  if test -e "${DATA_PATH:?}/system/users/0/runtime-permissions.xml"; then
    if ! grep -q 'com.google.android.syncadapters.contacts' "${DATA_PATH:?}"/system/users/*/runtime-permissions.xml; then
      # Purge the runtime permissions to prevent issues when the user flash this on a dirty install
      ui_msg "Resetting legacy Android runtime permissions..."
      delete "${DATA_PATH:?}"/system/users/*/runtime-permissions.xml
    fi
  fi
  if test -e "${DATA_PATH:?}/misc_de/0/apexdata/com.android.permission/runtime-permissions.xml"; then
    if ! grep -q 'com.google.android.syncadapters.contacts' "${DATA_PATH:?}"/misc_de/*/apexdata/com.android.permission/runtime-permissions.xml; then
      # Purge the runtime permissions to prevent issues when the user flash this on a dirty install
      ui_msg "Resetting Android runtime permissions..."
      delete "${DATA_PATH:?}"/misc_de/*/apexdata/com.android.permission/runtime-permissions.xml
    fi
  fi
fi

mount_extra_partitions_silent

# Clean previous installations
delete "${SYS_PATH:?}/etc/zips/${install_id:?}.prop"

readonly INSTALLER='true'
export INSTALLER
# shellcheck source=SCRIPTDIR/uninstall.sh
. "${TMP_PATH:?}/uninstall.sh"

unmount_extra_partitions

# Configuring default Android permissions
if test "${API}" -ge 23; then
  ui_debug 'Configuring default Android permissions...'
  if ! test -e "${SYS_PATH}/etc/default-permissions"; then
    ui_msg 'Creating the default permissions folder...'
    create_dir "${SYS_PATH}/etc/default-permissions"
  fi
  copy_dir_content "${TMP_PATH}/files/etc/default-permissions" "${SYS_PATH}/etc/default-permissions"
else
  delete_recursive "${TMP_PATH}/files/etc/default-permissions"
fi

# Preparing
ui_msg 'Preparing...'

if test -e "${TMP_PATH:?}/files/priv-app" && test "${PRIVAPP_FOLDER:?}" != 'priv-app'; then
  copy_dir_content "${TMP_PATH:?}/files/priv-app" "${TMP_PATH:?}/files/${PRIVAPP_FOLDER:?}"
  delete "${TMP_PATH:?}/files/priv-app"
fi
delete_dir_if_empty "${TMP_PATH:?}/files/app"

if test "${API:?}" -ge 21; then
  # Move apps into subdirs
  if test -e "${TMP_PATH:?}/files/priv-app"; then
    for entry in "${TMP_PATH:?}/files/priv-app"/*; do
      path_without_ext=$(remove_ext "${entry}")

      create_dir "${path_without_ext}"
      mv -f "${entry}" "${path_without_ext}"/
    done
  fi
  if test -e "${TMP_PATH:?}/files/app"; then
    for entry in "${TMP_PATH:?}/files/app"/*; do
      path_without_ext=$(remove_ext "${entry}")

      create_dir "${path_without_ext}"
      mv -f "${entry}" "${path_without_ext}"/
    done
  fi
fi

# Installing
ui_msg 'Installing...'
delete_dir_if_empty "${TMP_PATH:?}/files/etc/permissions"
delete_dir_if_empty "${TMP_PATH:?}/files/etc"
if test -e "${TMP_PATH:?}/files/etc/permissions"; then copy_dir_content "${TMP_PATH:?}/files/etc/permissions" "${SYS_PATH:?}/etc/permissions"; fi
if test -e "${TMP_PATH:?}/files/app"; then copy_dir_content "${TMP_PATH:?}/files/app" "${SYS_PATH:?}/app"; fi
if test -e "${TMP_PATH:?}/files/priv-app"; then copy_dir_content "${TMP_PATH:?}/files/priv-app" "${PRIVAPP_PATH:?}"; fi

USED_SETTINGS_PATH="${TMP_PATH:?}/files/etc/zips"
create_dir "${USED_SETTINGS_PATH:?}"

{
  echo '# SPDX-FileCopyrightText: none'
  echo '# SPDX-License-Identifier: CC0-1.0'
  echo '# SPDX-FileType: OTHER'
  echo ''
  echo 'install.type=flashable-zip'
  echo "install.version.code=${install_version_code}"
  echo "install.version=${install_version}"
} > "${USED_SETTINGS_PATH:?}/${INSTALLATION_SETTINGS_FILE:?}"
set_perm 0 0 0640 "${USED_SETTINGS_PATH:?}/${INSTALLATION_SETTINGS_FILE:?}"

create_dir "${SYS_PATH:?}/etc/zips"
set_perm 0 0 0750 "${SYS_PATH:?}/etc/zips"

copy_dir_content "${USED_SETTINGS_PATH:?}" "${SYS_PATH:?}/etc/zips"

# Install survival script
if test -e "${SYS_PATH:?}/addon.d"; then
  ui_msg 'Installing survival script...'
  write_file_list "${TMP_PATH}/files" "${TMP_PATH}/files/" "${TMP_PATH}/backup-filelist.lst"
  replace_line_in_file_with_file "${TMP_PATH}/addon.d/00-1-google-sync.sh" '%PLACEHOLDER-1%' "${TMP_PATH}/backup-filelist.lst"
  copy_file "${TMP_PATH}/addon.d/00-1-google-sync.sh" "${SYS_PATH}/addon.d"
fi

deinitialize

touch "${TMP_PATH:?}/installed"
ui_msg 'Installation finished.'
