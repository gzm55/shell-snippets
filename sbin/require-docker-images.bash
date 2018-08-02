#!/usr/bin/env bash

# detect bash, see: https://www.av8n.com/computer/shell-dialect-detect
# shellcheck disable=SC2006,SC2116
/usr/bin/env test _"`echo asdf 2>/dev/null`" != _asdf \
  && echo "[ERROR] require-docker-images.bash must be interpreted by bash!" && exit 11 || :

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
  echo "[ERROR] require-docker-images.bash must be interpreted by bash!"
  exit 12
fi

set -eufo pipefail +x || set -euf +x
[[ ${DEBUG-} != true ]] || set -x

## Usage:
# require-docker-images.bash [--force] [NAME[:TAG|@DIGEST] ...]

if [[ ${1-} == --force ]]; then
  FORCE_PULL=true
  shift
fi

## PULL images

for image in "$@"; do
  if [[ ${FORCE_PULL-} == true ]] || ! docker images -q "$image" 2>/dev/null | grep -q "^[0-9a-zA-Z]*$"; then
    echo "[INFO] start deploying $image..."
    docker pull "$image"
  fi
  if ! docker images -q "$image" 2>/dev/null | grep -q "^[0-9a-zA-Z]*$"; then
    echo "[ERROR] pull the image $image failed!" >&2
    exit 2
  fi
done
