#!/usr/bin/env bash

# detect bash, see: https://www.av8n.com/computer/shell-dialect-detect
# shellcheck disable=SC2006,SC2116
/usr/bin/env test _"`echo asdf 2>/dev/null`" != _asdf \
  && echo "[ERROR] set-docker-mirror.bash must be interpreted by bash!" && exit 11 || :

if test -z "$(export PATH=/dev/null/$$; type -p >/dev/null 2>/dev/null && type declare >/dev/null 2>/dev/null && echo bash)" &&
   test -z "$(export PATH=/dev/null/$$; type -p >/dev/null 2>/dev/null
              test "$?" -eq 1 || exit 0
              type -p type >/dev/null 2>/dev/null || exit 0
              penult='nil'  ult=''
              for word in $(type declare 2>/dev/null) ; do
                penult="$ult"
                ult="$word"
              done
              test "${penult}_${ult}" = "shell_builtin" && echo bash-on-mac)"; then
  echo "[ERROR] set-docker-mirror.bash must be interpreted by bash!"
  exit 12
fi

set -eufo pipefail +x || set -euf +x
[[ ${DEBUG-} != true ]] || set -x

## Usage:
# set-docker-mirror.bash <mirror-url>

if command -v curl >/dev/null; then
  cat_url() { [[ ${1-} ]] && curl -fsSL ${2:+-o "$2"} "$1"; }
elif command -v wget >/dev/null; then
  cat_url() { [[ ${1-} ]] && wget -qO "${2:--}" "$1"; }
else
  cat_url() {
    echo "[WARN] no wget or curl, cannot download $curl !" >&2
    return 1
  }
fi

if [[ $(uname -s) == Linux && ${1-} ]]; then
  cat_url https://get.daocloud.io/daotools/set_mirror.sh | sh -s -- "$1"
fi
