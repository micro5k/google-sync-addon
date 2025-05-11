#!/sbin/sh
# SPDX-FileCopyrightText: (c) 2016 ale5000
# SPDX-License-Identifier: GPL-3.0-or-later

### GLOBAL VARIABLES ###

TMP_PATH="${2:?}"

### FUNCTIONS ###

# shellcheck source=SCRIPTDIR/../inc/common-functions.sh
command . "${TMP_PATH:?}/inc/common-functions.sh" || exit "${?}"

### CODE ###

if test "${API:?}" -ge 24; then
  : # Supported Android version
elif test "${API:?}" -ge 23; then
  ui_error 'Unsupported Android version'
elif test "${API:?}" -ge 19; then
  : # Supported Android version
else
  ui_error "Your Android version is too old, API: ${API?}"
fi

APP_CONTACTSSYNC="$(parse_setting 'app' 'CONTACTSSYNC' "${APP_CONTACTSSYNC:?}")"
APP_CALENDARSYNC="$(parse_setting 'app' 'CALENDARSYNC' "${APP_CALENDARSYNC:?}")"

if test "${SETUP_TYPE:?}" = 'install'; then
  ui_msg 'Extracting...'
  custom_package_extract_dir 'origin' "${TMP_PATH:?}"
  custom_package_extract_dir 'addon.d' "${TMP_PATH:?}"
  create_dir "${TMP_PATH:?}/files/etc"

  ui_msg 'Configuring...'
  ui_msg_empty_line

  setup_app 1 '' 'Google Backup Transport 4.4' 'GoogleBackupTransport44' 'priv-app' false false

  setup_app "${APP_CONTACTSSYNC:?}" 'APP_CONTACTSSYNC' 'Google Contacts Sync 12' 'GoogleContactsSyncAdapter12' 'priv-app' ||
    setup_app "${APP_CONTACTSSYNC:?}" 'APP_CONTACTSSYNC' 'Google Contacts Sync 8' 'GoogleContactsSyncAdapter8' 'priv-app' ||
    setup_app "${APP_CONTACTSSYNC:?}" 'APP_CONTACTSSYNC' 'Google Contacts Sync 4.4' 'GoogleContactsSyncAdapter44' 'app'

  setup_app "${APP_CALENDARSYNC:?}" 'APP_CALENDARSYNC' 'Google Calendar Sync 6' 'GoogleCalendarSyncAdapter6' 'app' ||
    setup_app "${APP_CALENDARSYNC:?}" 'APP_CALENDARSYNC' 'Google Calendar Sync 5' 'GoogleCalendarSyncAdapter5' 'app'
fi

if test "${SETUP_TYPE:?}" = 'install'; then
  disable_app 'com.google.android.syncadapters.calendar'
  disable_app 'com.google.android.syncadapters.contacts'
  disable_app 'com.google.android.backuptransport'
fi

# Clean previous installations
clean_previous_installations

if test "${SETUP_TYPE:?}" = 'uninstall'; then
  clear_app 'com.google.android.syncadapters.calendar'
  clear_app 'com.google.android.syncadapters.contacts'
  clear_app 'com.google.android.backuptransport'

  finalize_correctly
  exit 0
fi

# Prepare installation
prepare_installation

# Install
perform_installation
reset_authenticator_and_sync_adapter_caches

clear_and_enable_app 'com.google.android.backuptransport'
clear_and_enable_app 'com.google.android.syncadapters.contacts'
clear_and_enable_app 'com.google.android.syncadapters.calendar'

# Install survival script
install_survival_script '00-1-google-sync'

# Resetting Android runtime permissions
reset_runtime_permissions_if_needed 'com.google.android.syncadapters.contacts'

finalize_correctly
