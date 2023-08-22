#!/sbin/sh
# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileType: SOURCE

### GLOBAL VARIABLES ###

TMP_PATH="${2:?}"

### FUNCTIONS ###

# shellcheck source=SCRIPTDIR/../inc/common-functions.sh
. "${TMP_PATH:?}/inc/common-functions.sh" || exit "${?}"

### CODE ###

INSTALL_CONTACTSSYNC="$(parse_setting 'INSTALL_CONTACTSSYNC' "${INSTALL_CONTACTSSYNC:?}")"
INSTALL_CALENDARSYNC="$(parse_setting 'INSTALL_CALENDARSYNC' "${INSTALL_CALENDARSYNC:?}")"

if test "${API:?}" -ge 24; then
  : ### Supported Android versions
elif test "${API:?}" -ge 21; then
  ui_error 'Unsupported Android version'
elif test "${API:?}" -ge 19; then
  : ### Supported Android versions
else
  ui_error "Your Android version is too old, API: ${API:-}"
fi

# Display info
display_info
ui_msg_empty_line

if test "${IS_INSTALLATION:?}" = 'true'; then
  ui_msg 'Starting installation...'
  ui_msg_empty_line

  # Extracting
  ui_msg 'Extracting...'
  custom_package_extract_dir 'origin' "${TMP_PATH:?}"
  custom_package_extract_dir 'files' "${TMP_PATH:?}"
  custom_package_extract_dir 'addon.d' "${TMP_PATH:?}"
  create_dir "${TMP_PATH:?}/files/etc"

  # Configuring
  ui_msg 'Configuring...'

  setup_app 1 'Google Backup Transport 4.4' 'GoogleBackupTransport44' 'priv-app' false false

  setup_app "${INSTALL_CONTACTSSYNC:?}" 'Google Contacts Sync 8' 'GoogleContactsSyncAdapter8' 'priv-app' ||
    setup_app "${INSTALL_CONTACTSSYNC:?}" 'Google Contacts Sync 4.4' 'GoogleContactsSyncAdapter44' 'app'

  setup_app "${INSTALL_CALENDARSYNC:?}" 'Google Calendar Sync 6' 'GoogleCalendarSyncAdapter6' 'app' ||
    setup_app "${INSTALL_CALENDARSYNC:?}" 'Google Calendar Sync 5' 'GoogleCalendarSyncAdapter5' 'app'

  delete "${TMP_PATH:?}/origin"
else
  ui_msg 'Starting uninstallation...'
  ui_msg_empty_line
fi

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

# Clean previous installations
delete "${SYS_PATH:?}/etc/zips/${MODULE_ID:?}.prop"

readonly INSTALLER='true'
export INSTALLER
# shellcheck source=SCRIPTDIR/uninstall.sh
. "${TMP_PATH:?}/uninstall.sh"

unmount_extra_partitions

if test "${IS_INSTALLATION:?}" != 'true'; then
  deinitialize

  touch "${TMP_PATH:?}/installed"
  ui_msg 'Uninstallation finished.'

  exit 0
fi

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

# Prepare installation
prepare_installation

# Install
perform_installation

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
