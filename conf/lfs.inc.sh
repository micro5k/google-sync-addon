#!/usr/bin/env sh
# SPDX-FileCopyrightText: NONE
# SPDX-License-Identifier: CC0-1.0

get_mirror_by_sha256()
{
  case "${1?}" in
    *) ui_error "Unknown hash => ${1?}" ;;
  esac

  return 0
}
