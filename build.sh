#!/usr/bin/env bash

<<LICENSE
    Copyright (C) 2017  ale5000
    This file is part of Google Sync Add-on by @ale5000.

    Google Sync Add-on is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version, w/Google Sync Add-on zip exception.

    Google Sync Add-on is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Google Sync Add-on.  If not, see <http://www.gnu.org/licenses/>.
LICENSE

ui_error()
{
  >&2 echo "ERROR: $1"
  test -n "$2" && exit "$2"
  exit 1
}

verify_sha1()
{
  local file_name="$1"
  local hash="$2"
  local file_hash=$(sha1sum "$file_name" | cut -d ' ' -f 1)

  if [[ $hash != "$file_hash" ]]; then return 1; fi  # Failed
  return 0  # Success
}

corrupted_file()
{
  rm -f "$1" || echo 'Failed to remove the corrupted file.'
  ui_error "The file '$1' is corrupted."
}

dl_file()
{
  if [[ ! -e "$3/$2/$1" ]]; then
    mkdir -p "$3/$2"
    wget -O "$3/$2/$1" -U 'Mozilla/5.0 (X11; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0' "$4" || ui_error "Failed to download the file '$2/$1'."
    echo ''
  fi
  verify_sha1 "$3/$2/$1" "$5" || corrupted_file "$3/$2/$1"
}

# Detect OS
UNAME=$(uname)
if [[ "$UNAME" == 'Linux' ]]; then
  PLATFORM='linux'
elif [[ "$UNAME" == 'Windows_NT' ]]; then
  PLATFORM='win'
#elif [[ "$UNAME" == 'Darwin' ]]; then
  #PLATFORM='macos'
#elif [[ "$UNAME" == 'FreeBSD' ]]; then
  #PLATFORM='freebsd'
else
  ui_error 'Unsupported OS'
fi

# Detect script dir (with absolute path)
CURDIR=$(pwd)
BASEDIR=$(dirname "$0")
if [[ "${BASEDIR:0:1}" == '/' ]] || [[ "$PLATFORM" == 'win' && "${BASEDIR:1:1}" == ':' ]]; then
  :  # If already absolute leave it as is
else
  if [[ "$BASEDIR" == '.' ]]; then BASEDIR=''; else BASEDIR="/$BASEDIR"; fi
  if [[ "$CURDIR" != '/' ]]; then BASEDIR="$CURDIR$BASEDIR"; fi
fi

. "$BASEDIR/conf.sh"

# Create the output dir
OUT_DIR="$BASEDIR/output"
mkdir -p "$OUT_DIR" || ui_error 'Failed to create the output dir'

# Create the temp dir
TEMP_DIR=$(mktemp -d -t ZIPBUILDER-XXXXXX)

# Set filename and version
VER=$(cat "$BASEDIR/sources/inc/VERSION")
FILENAME="$NAME-v$VER-signed"

# Download files if they are missing
dl_file 'GoogleContactsSyncAdapter.apk' 'app' "$BASEDIR/sources/files" 'http://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=246810' '3b3dcbc77d81fc56f20af93cf453ad9da2f2276f'
dl_file 'GoogleCalendarSyncAdapter.apk' 'app' "$BASEDIR/sources/files" 'http://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=72565' 'aa482580c87a43c83882c05a4757754917d47f32'

dl_file 'GoogleBackupTransport.apk' 'priv-app-4.4' "$BASEDIR/sources/files" 'http://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=152392' '6f186d368014022b0038ad2f5d8aa46bb94b5c14'
dl_file 'GoogleContactsSyncAdapter.apk' 'app-4.4' "$BASEDIR/sources/files" 'http://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=152374' '68597be59f16d2e26a79def6fa20bc85d1d2c3b3'
dl_file 'GoogleCalendarSyncAdapter.apk' 'app-4.4' "$BASEDIR/sources/files" 'http://www.apkmirror.com/wp-content/themes/APKMirror/download.php?id=99188' 'cf9fa487dfe0ead8576d6af897687e7fa2ae00fa'

# Copy data
cp -rf "$BASEDIR/sources" "$TEMP_DIR/" || ui_error 'Failed to copy data to the temp dir'
cp -rf "$BASEDIR/"LICENSE* "$TEMP_DIR/sources/" || ui_error 'Failed to copy license to the temp dir'

# Remove the previous file
rm -f "$OUT_DIR/$FILENAME.zip" || ui_error 'Failed to remove the previous zip file'

# Compress and sign
cd "$TEMP_DIR/sources" || ui_error 'Failed to change folder'
zip -r9X "$TEMP_DIR/zip-1.zip" * || ui_error 'Failed compressing'
echo ''
java -jar "$BASEDIR/tools/signapk.jar" "$BASEDIR/certs"/*.x509.pem "$BASEDIR/certs"/*.pk8 "$TEMP_DIR/zip-1.zip" "$TEMP_DIR/zip-2.zip" || ui_error 'Failed signing'
"$BASEDIR/tools/$PLATFORM/zipadjust" "$TEMP_DIR/zip-2.zip" "$TEMP_DIR/zip-3.zip" || ui_error 'Failed zipadjusting'
java -jar "$BASEDIR/tools/minsignapk.jar" "$BASEDIR/certs"/*.x509.pem "$BASEDIR/certs"/*.pk8 "$TEMP_DIR/zip-3.zip" "$TEMP_DIR/zip-4.zip" || ui_error 'Failed minsigning'
cd "$OUT_DIR"

cp -f "$TEMP_DIR/zip-4.zip" "$OUT_DIR/$FILENAME.zip" || ui_error 'Failed to copy the final file'

# Cleanup remnants
rm -rf "$TEMP_DIR" || ui_error 'Failed to cleanup'

echo ''
echo 'Done.'
