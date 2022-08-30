#!/usr/bin/env bash
# SPDX-FileCopyrightText: none
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE

files_to_download()
{
cat <<'EOF'
GoogleContactsSyncAdapter.apk|files/priv-app|d6913b4a2fa5377b2b2f9e43056599b5e987df83|https://www.apkmirror.com/apk/google-inc/google-contacts-sync/google-contacts-sync-8-1-0-release/google-contacts-sync-8-1-0-2-android-apk-download/|https://gitlab.opengapps.org/opengapps/all/-/raw/b458223777512c97639cb6bb54bfad93047406d7/app/com.google.android.syncadapters.contacts/27/nodpi/27.apk
GoogleCalendarSyncAdapter.apk|files/app|aa482580c87a43c83882c05a4757754917d47f32|https://www.apkmirror.com/apk/google-inc/google-calendar-sync/google-calendar-sync-5-2-3-99827563-release-release/google-calendar-sync-5-2-3-99827563-release-2-android-apk-download/|https://gitlab.opengapps.org/opengapps/all/-/raw/b458223777512c97639cb6bb54bfad93047406d7/app/com.google.android.syncadapters.calendar/15/nodpi/2015080710.apk
GoogleBackupTransport.apk|files/priv-app-4.4|6f186d368014022b0038ad2f5d8aa46bb94b5c14|https://www.apkmirror.com/apk/google-inc/google-backup-transport/google-backup-transport-4-4-4-1227136-release/google-backup-transport-4-4-4-1227136-android-apk-download/|
GoogleContactsSyncAdapter.apk|files/app-4.4|68597be59f16d2e26a79def6fa20bc85d1d2c3b3|https://www.apkmirror.com/apk/google-inc/google-contacts-sync/google-contacts-sync-4-4-4-1227136-release/google-contacts-sync-4-4-4-1227136-android-apk-download/|https://gitlab.opengapps.org/opengapps/all/-/raw/b458223777512c97639cb6bb54bfad93047406d7/app/com.google.android.syncadapters.contacts/19/nodpi/19.apk
GoogleCalendarSyncAdapter.apk|files/app-4.4|cf9fa487dfe0ead8576d6af897687e7fa2ae00fa|https://www.apkmirror.com/apk/google-inc/google-calendar-sync/google-calendar-sync-4-1-2-509230-release/google-calendar-sync-4-1-2-509230-android-apk-download/|
EOF
}
