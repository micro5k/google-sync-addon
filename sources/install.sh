#!/sbin/sh

### GLOBAL VARIABLES ###

RECOVERY_API_VER="$2"
RECOVERY_PIPE="$3"
ZIP_FILE="$4"
TMP_PATH="$5"

INSTALLER=1
OLD_ANDROID=false
SYS_ROOT_IMAGE=''
SYS_PATH='/system'
ZIP_PATH=false

mkdir "${TMP_PATH}/bin"
/tmp/busybox --install -s "${TMP_PATH}/bin"
# Clean search path so BusyBox will use only internal applets
PATH="${TMP_PATH}/bin"


### FUNCTIONS ###

. "${TMP_PATH}/inc/common.sh"


### CODE ###

if ! is_mounted '/system'; then
  mount '/system'
  if ! is_mounted '/system'; then ui_error 'ERROR: /system cannot be mounted'; fi
fi

SYS_ROOT_IMAGE=$(getprop 'build.system_root_image')
if [[ -z "$SYS_ROOT_IMAGE" ]]; then
  SYS_ROOT_IMAGE=false;
elif [[ $SYS_ROOT_IMAGE == true && -e '/system/system' ]]; then
  SYS_PATH='/system/system';
fi

cp -pf "${SYS_PATH}/build.prop" "${TMP_PATH}/build.prop"  # Cache the file for faster access

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
  ui_error 'ERROR: Your Android version is too old'
else
  ui_error 'ERROR: Invalid API level'
fi

ZIP_PATH=$(dirname "$ZIP_FILE")

# Info
ui_msg '------------------'
ui_msg 'Google Sync Add-on'
ui_msg 'v1.0.2-alpha'
ui_msg '(by ale5000)'
ui_msg '------------------'
ui_msg ''
ui_msg "API: ${API}"
ui_msg "System root image: ${SYS_ROOT_IMAGE}"
ui_msg "System path: ${SYS_PATH}"
ui_msg "Privileged apps: ${PRIVAPP_PATH}"
ui_msg ''

ui_msg 'Extracting files...'
custom_package_extract_dir 'files' "${TMP_PATH}"

ui_debug 'Setting permissions...'
set_std_perm_recursive "${TMP_PATH}/files"

ui_msg_sameline_start 'Verifying files...'
if #verify_sha1 "${TMP_PATH}/files/priv-app/GoogleBackupTransport.apk" '2bdf65e98dbd115473cd72db8b6a13d585a65d8d' &&  # Disabled for now
   verify_sha1 "${TMP_PATH}/files/app/GoogleContactsSyncAdapter.apk" '3b3dcbc77d81fc56f20af93cf453ad9da2f2276f' &&
   verify_sha1 "${TMP_PATH}/files/app/GoogleCalendarSyncAdapter.apk" 'aa482580c87a43c83882c05a4757754917d47f32' &&
   verify_sha1 "${TMP_PATH}/files/priv-app-4.4/GoogleBackupTransport.apk" '6f186d368014022b0038ad2f5d8aa46bb94b5c14' &&
   verify_sha1 "${TMP_PATH}/files/app-4.4/GoogleContactsSyncAdapter.apk" '68597be59f16d2e26a79def6fa20bc85d1d2c3b3' &&
   verify_sha1 "${TMP_PATH}/files/app-4.4/GoogleCalendarSyncAdapter.apk" 'cf9fa487dfe0ead8576d6af897687e7fa2ae00fa'
then
  ui_msg_sameline_end 'OK'
else
  ui_msg_sameline_end 'ERROR'
  ui_error 'ERROR: Verification failed'
fi

# Clean some Google Apps and previous installations
. "${TMP_PATH}/uninstall.sh"

# Setup default Android permissions
ui_debug 'Setup default Android permissions...'
if [[ ! -e "${SYS_PATH}/etc/default-permissions" ]]; then
  ui_msg 'Creating the default permissions folder...'
  create_dir "${SYS_PATH}/etc/default-permissions"
fi
copy_dir_content "${TMP_PATH}/files/etc/default-permissions" "${SYS_PATH}/etc/default-permissions"

# Resetting Android runtime permissions
if ! is_mounted '/data'; then
  mount '/data'
  if ! is_mounted '/data'; then ui_error 'ERROR: /data cannot be mounted'; fi
fi
if [[ -e '/data/system/users/0/runtime-permissions.xml' ]]; then
  if ! grep -q 'com.google.android.syncadapters.contacts' /data/system/users/*/runtime-permissions.xml; then
    # Purge the runtime permissions to prevent issues when the user flash this for the first time on a dirty install
    ui_debug "Resetting Android runtime permissions..."
    delete /data/system/users/*/runtime-permissions.xml
  fi
fi
umount '/data'

# Installing
ui_msg 'Installing...'
if [[ $OLD_ANDROID != true ]]; then
  # Move apps into subdirs
  #for entry in "${TMP_PATH}/files/priv-app"/*; do
    #path_without_ext=$(remove_ext "$entry")

    #create_dir "$path_without_ext"
    #mv -f "$entry" "$path_without_ext"/
  #done
  for entry in "${TMP_PATH}/files/app"/*; do
    path_without_ext=$(remove_ext "$entry")

    create_dir "$path_without_ext"
    mv -f "$entry" "$path_without_ext"/
  done
fi

if [[ $API -ge 23 ]]; then
  #copy_dir_content "${TMP_PATH}/files/priv-app" "${PRIVAPP_PATH}"  # Disabled for now
  copy_dir_content "${TMP_PATH}/files/app" "${SYS_PATH}/app"
elif [[ $API -ge 21 ]]; then
  ui_error 'ERROR: Unsupported Android version'
elif [[ $API -ge 19 ]]; then
  copy_dir_content "${TMP_PATH}/files/priv-app-4.4" "${PRIVAPP_PATH}"
  copy_dir_content "${TMP_PATH}/files/app-4.4" "${SYS_PATH}/app"
fi

# Install survival script
if [[ -d "${SYS_PATH}/addon.d" ]]; then
  if [[ $OLD_ANDROID == true ]]; then
    :  ### Not ready yet #cp -rpf "${TMP_PATH}/files/addon.d/....sh" "${SYS_PATH}/addon.d/....sh"
  else
    #ui_msg 'Installing survival script...'
    :  ### Not ready yet #cp -rpf "${TMP_PATH}/files/addon.d/....sh" "${SYS_PATH}/addon.d/....sh"
  fi
fi

umount '/system'

touch "${TMP_PATH}/installed"
ui_msg 'Done.'
