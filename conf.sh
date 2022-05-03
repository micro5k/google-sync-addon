#!/usr/bin/env bash

# SPDX-FileCopyrightText: none
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileType: SOURCE

export NAME='google-sync-addon'

oss_files_to_download()
{
cat <<'EOF'
EOF
}

files_to_download()
{
cat <<'EOF'
GoogleContactsSyncAdapter.apk|files/app|c46d9bbe31f85a5263eb6a2a0932abbf9ac3ecc9|https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=290062||
GoogleCalendarSyncAdapter.apk|files/app|aa482580c87a43c83882c05a4757754917d47f32|https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=72565|https://gitlab.opengapps.org/opengapps/all/-/raw/master/app/com.google.android.syncadapters.calendar/15/nodpi/2015080710.apk|
GoogleBackupTransport.apk|files/priv-app-4.4|6f186d368014022b0038ad2f5d8aa46bb94b5c14|https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=152392||
GoogleContactsSyncAdapter.apk|files/app-4.4|68597be59f16d2e26a79def6fa20bc85d1d2c3b3|https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=152374|https://gitlab.opengapps.org/opengapps/all/-/raw/master/app/com.google.android.syncadapters.contacts/19/nodpi/19.apk|
GoogleCalendarSyncAdapter.apk|files/app-4.4|cf9fa487dfe0ead8576d6af897687e7fa2ae00fa|https://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=99188||
EOF
}
