#!/usr/bin/env sh
# SPDX-FileCopyrightText: NONE
# SPDX-License-Identifier: CC0-1.0

conf_lfs_get_mirror_by_sha256()
{
  case "${1?}" in
    *)
      ui_nl
      # shellcheck disable=SC3028 # Ignore: In POSIX sh, FUNCNAME is undefined
      ui_error "Unknown hash => ${1?}" "${LINENO-}" "${FUNCNAME-}"
      ;;
  esac

  return 0
}
