#!/sbin/sh

<<LICENSE
  Copyright (C) 2016-2018  ale5000
  This file was created by ale5000 (ale5000-git on GitHub).

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version, w/ zip exception.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
LICENSE

### GLOBAL VARIABLES ###

export INSTALLER=1
TMP_PATH="$2"

OLD_ANDROID=false
SYS_ROOT_IMAGE=''
SYS_PATH='/system'
INSTALLATION_SETTINGS_FILE='google-sync.prop'


### FUNCTIONS ###

. "$TMP_PATH/inc/common.sh"


### CODE ###

if ! is_mounted '/system'; then
  mount '/system'
  if ! is_mounted '/system'; then ui_error '/system cannot be mounted'; fi
fi

SYS_ROOT_IMAGE=$(getprop 'build.system_root_image')
if [[ -z "$SYS_ROOT_IMAGE" ]]; then
  SYS_ROOT_IMAGE=false;
elif [[ $SYS_ROOT_IMAGE == true && -e '/system/system' ]]; then
  SYS_PATH='/system/system';
fi

test -f "${SYS_PATH}/build.prop" || ui_error 'The ROM cannot be found'
cp -pf "${SYS_PATH}/build.prop" "$TMP_PATH/build.prop"  # Cache the file for faster access

PRIVAPP_PATH="${SYS_PATH}/app"
if [[ -d "${SYS_PATH}/priv-app" ]]; then PRIVAPP_PATH="${SYS_PATH}/priv-app"; fi  # Detect the position of the privileged apps folder

API=$(build_getprop 'build\.version\.sdk')
if [[ $API -ge 24 ]]; then  # 23
  :  ### New Android versions
elif [[ $API -ge 21 ]]; then
  ui_error 'ERROR: Unsupported Android version'
elif [[ $API -ge 19 ]]; then
  OLD_ANDROID=true
elif [[ $API -ge 1 ]]; then
  ui_error 'Your Android version is too old'
else
  ui_error 'Invalid API level'
fi

# Info
ui_msg ''
ui_msg '------------------'
ui_msg 'Google Sync Add-on'
ui_msg 'v1.0.3-beta'
ui_msg '(by ale5000)'
ui_msg '------------------'
ui_msg ''
ui_msg "API: ${API}"
ui_msg "System root image: ${SYS_ROOT_IMAGE}"
ui_msg "System path: ${SYS_PATH}"
ui_msg "Privileged apps: ${PRIVAPP_PATH}"
ui_msg ''

# Extracting
ui_msg 'Extracting...'
custom_package_extract_dir 'files' "$TMP_PATH"
#custom_package_extract_dir 'addon.d' "$TMP_PATH"

# Setting up permissions
ui_debug 'Setting up permissions...'
set_std_perm_recursive "$TMP_PATH/files"
#set_std_perm_recursive "$TMP_PATH/addon.d"
#set_perm 0 0 0755 "$TMP_PATH/addon.d/00-1-google-sync.sh"

# Verifying
ui_msg_sameline_start 'Verifying... '
if #verify_sha1 "$TMP_PATH/files/priv-app/GoogleBackupTransport.apk" '2bdf65e98dbd115473cd72db8b6a13d585a65d8d' &&  # Disabled for now
   verify_sha1 "$TMP_PATH/files/app/GoogleContactsSyncAdapter.apk" 'c46d9bbe31f85a5263eb6a2a0932abbf9ac3ecc9' &&
   verify_sha1 "$TMP_PATH/files/app/GoogleCalendarSyncAdapter.apk" 'aa482580c87a43c83882c05a4757754917d47f32' &&
   verify_sha1 "$TMP_PATH/files/priv-app-4.4/GoogleBackupTransport.apk" '6f186d368014022b0038ad2f5d8aa46bb94b5c14' &&
   verify_sha1 "$TMP_PATH/files/app-4.4/GoogleContactsSyncAdapter.apk" '68597be59f16d2e26a79def6fa20bc85d1d2c3b3' &&
   verify_sha1 "$TMP_PATH/files/app-4.4/GoogleCalendarSyncAdapter.apk" 'cf9fa487dfe0ead8576d6af897687e7fa2ae00fa'
then
  ui_msg_sameline_end 'OK'
else
  ui_msg_sameline_end 'ERROR'
  ui_error 'Verification failed'
fi

# Clean some Google Apps and previous installations
. "$TMP_PATH/uninstall.sh"

# Configuring default Android permissions
ui_debug 'Configuring default Android permissions...'
if [[ ! -e "${SYS_PATH}/etc/default-permissions" ]]; then
  ui_msg 'Creating the default permissions folder...'
  create_dir "${SYS_PATH}/etc/default-permissions"
fi
copy_dir_content "$TMP_PATH/files/etc/default-permissions" "${SYS_PATH}/etc/default-permissions"

# MOUNT /data PARTITION
if ! is_mounted '/data'; then
  mount '/data'
  if ! is_mounted '/data'; then ui_error '/data cannot be mounted'; fi
fi

# Resetting Android runtime permissions
if [[ -e '/data/system/users/0/runtime-permissions.xml' ]]; then
  if ! grep -q 'com.google.android.syncadapters.contacts' /data/system/users/*/runtime-permissions.xml; then
    # Purge the runtime permissions to prevent issues when the user flash this for the first time on a dirty install
    ui_debug "Resetting Android runtime permissions..."
    delete /data/system/users/*/runtime-permissions.xml
  fi
fi

# UNMOUNT /data PARTITION
unmount '/data'

# Preparing
ui_msg 'Preparing...'

if [[ $OLD_ANDROID != true ]]; then
  # Move apps into subdirs
  #for entry in "$TMP_PATH/files/priv-app"/*; do
    #path_without_ext=$(remove_ext "$entry")

    #create_dir "$path_without_ext"
    #mv -f "$entry" "$path_without_ext"/
  #done
  for entry in "$TMP_PATH/files/app"/*; do
    path_without_ext=$(remove_ext "$entry")

    create_dir "$path_without_ext"
    mv -f "$entry" "$path_without_ext"/
  done
fi

# Installing
ui_msg 'Installing...'
if [[ $API -ge 23 ]]; then
  #copy_dir_content "$TMP_PATH/files/priv-app" "${PRIVAPP_PATH}"  # Disabled for now
  copy_dir_content "$TMP_PATH/files/app" "${SYS_PATH}/app"
elif [[ $API -ge 21 ]]; then
  ui_error 'ERROR: Unsupported Android version'
elif [[ $API -ge 19 ]]; then
  copy_dir_content "$TMP_PATH/files/priv-app-4.4" "${PRIVAPP_PATH}"
  copy_dir_content "$TMP_PATH/files/app-4.4" "${SYS_PATH}/app"
fi

USED_SETTINGS_PATH="$TMP_PATH/files/etc/zips"

create_dir "${USED_SETTINGS_PATH}"
echo 'type="Google Sync"' > "${USED_SETTINGS_PATH}/${INSTALLATION_SETTINGS_FILE}"
set_perm 0 0 0644 "${USED_SETTINGS_PATH}/${INSTALLATION_SETTINGS_FILE}"
create_dir "${SYS_PATH}/etc/zips"
copy_dir_content "${USED_SETTINGS_PATH}" "${SYS_PATH}/etc/zips"

# Install survival script
if [[ -d "${SYS_PATH}/addon.d" ]]; then
  if [[ $OLD_ANDROID == true ]]; then
    :  ### Not ready yet
  else
    #ui_msg 'Installing survival script...'
    : ### Not ready yet
    #write_file_list "$TMP_PATH/files" "$TMP_PATH/files/" "$TMP_PATH/backup-filelist.lst"
    #replace_line_in_file "$TMP_PATH/addon.d/00-1-google-sync.sh" '%PLACEHOLDER-1%' "$TMP_PATH/backup-filelist.lst"
    #copy_file "$TMP_PATH/addon.d/00-1-google-sync.sh" "$SYS_PATH/addon.d"
  fi
fi

unmount '/system'

touch "$TMP_PATH/installed"
ui_msg 'Done.'
