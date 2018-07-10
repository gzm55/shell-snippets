#!/usr/bin/env bash

# detect bash, see: https://www.av8n.com/computer/shell-dialect-detect
# shellcheck disable=SC2006,SC2116
/usr/bin/env test _"`echo asdf 2>/dev/null`" != _asdf \
  && echo "[ERROR] install-docker.bash must be interpreted by bash!" && exit 11 || :

# shellcheck disable=SC2030,SC2031
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
  echo "[ERROR] install-docker.bash must be interpreted by bash!"
  exit 12
fi

set -eufo pipefail +x || set -euf +x
[[ ${DEBUG-} != true ]] || set -x

if [[ ${OSTYPE-} == darwin* ]]; then
  __detect_brew=1
  while ! command -v brew &>/dev/null && (( --__detect_brew >= 0 )); do
    ## See: https://brew.sh/
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  done
  case $__detect_brew in
  (-1) echo "[ERROR] no brew and install failed!" >&2
       exit 1
       ;;
  esac
  unset __detect_brew

  __detect_docker=1
  while ! command -v docker &>/dev/null && (( --__detect_docker >= 0 )); do
    brew cask install docker
  done
  case $__detect_docker in
  (-1) echo "[ERROR] no docker and install failed!"
      exit 1
      ;;
  esac
  unset __detect_docker
else
  ## INSTALL Docker
  ## ref: https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-using-the-convenience-script
  ## ref: https://github.com/docker/docker-install
  ## switch env:
  ## - SKIP_CHECK_DOCKER_INSTALLER: skip checking the docker installer if not download script from https url.

  __detect_docker=1
  temp_dir="$(mktemp -q -d -t "docker-install-script.XXXXXX" 2>/dev/null || mktemp -q -d)"
  while ! command -v docker &>/dev/null && (( --__detect_docker >= 0 )); do
    if [[ ! $temp_dir || ! -d $temp_dir ]]; then
      echo "[ERROR] cannot create a temp dir for downloading docker installer script!"
      continue
    fi

    rm -- "$temp_dir/get-docker.sh" &>/dev/null || :

    if curl -fsSL https://get.docker.com/ -o "$temp_dir/get-docker.sh"; then
      __SKIP_CHECK_DOCKER_INSTALLER=true
    elif curl -fsSL get.docker.com -o "$temp_dir/get-docker.sh"; then
      __SKIP_CHECK_DOCKER_INSTALLER="${SKIP_CHECK_DOCKER_INSTALLER-}"
    else
      continue
    fi

    if [[ $__SKIP_CHECK_DOCKER_INSTALLER != true ]]; then
      SCRIPT_COMMIT_SHA=$(grep -m 1 "^SCRIPT_COMMIT_SHA=" -- "$temp_dir/get-docker.sh")
      SCRIPT_COMMIT_SHA=${SCRIPT_COMMIT_SHA##*=}
      [[ $SCRIPT_COMMIT_SHA ]] || continue

      curl -fsSL "https://raw.githubusercontent.com/docker/docker-install/$SCRIPT_COMMIT_SHA/install.sh" -o "$temp_dir/github-source.sh" \
      || continue

      SCRIPT_COMMIT_CHKSUM=$(grep -v "^SCRIPT_COMMIT_SHA=" -- "$temp_dir/github-source.sh" | grep -v "^DEFAULT_CHANNEL_VALUE=" | sha1sum)
      SCRIPT_COMMIT_CHKSUM=${SCRIPT_COMMIT_CHKSUM%% *}
      [[ $SCRIPT_COMMIT_CHKSUM ]] || continue

      sha1sum -c - <<< "$SCRIPT_COMMIT_CHKSUM  "<(grep -v "^SCRIPT_COMMIT_SHA=" -- "$temp_dir/get-docker.sh" | grep -v "^DEFAULT_CHANNEL_VALUE=") \
      || continue
    fi

    sh -- "$temp_dir/get-docker.sh" || continue

    case ":$(id -u): $(groups) " in
    (:0:*|*" docker "*) break ;;
    (*) sudo usermod -aG docker "$(whoami)" ;;
    esac
  done

  [[ $temp_dir != /tmp/* || ! -d "$temp_dir" ]] || rm -rf "$temp_dir" || :

  case $__detect_docker in
  (-1) echo "[ERROR] no docker and install failed!"
      exit 1
      ;;
  esac
  unset __detect_docker
fi
