#!/bin/zsh

# Kubernetes prompt helper for bash/zsh
# ported to oh-my-zsh
# Displays current context and namespace

# Copyright 2018 Jon Mosco
#
#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Modified by Christopher J. Maahs to fit my custom cobalt theme.
# Jan 2020

# Debug
[[ -n $DEBUG ]] && set -x

setopt PROMPT_SUBST
autoload -U add-zsh-hook
add-zsh-hook precmd _kube_prompt_update_cache
zmodload zsh/stat
zmodload zsh/datetime

# Default values for the prompt
# Override these values in ~/.zshrc
KUBE_PROMPT_BINARY="${KUBE_PROMPT_BINARY:-kubectl}"
KUBE_PROMPT_SYMBOL_ENABLE="${KUBE_PROMPT_SYMBOL_ENABLE:-true}"
KUBE_PROMPT_SYMBOL_DEFAULT="${KUBE_PROMPT_SYMBOL_DEFAULT:-\u2388 }"
KUBE_PROMPT_SYMBOL_USE_IMG="${KUBE_PROMPT_SYMBOL_USE_IMG:-false}"
KUBE_PROMPT_NS_ENABLE="${KUBE_PROMPT_NS_ENABLE:-true}"
KUBE_PROMPT_SEPARATOR="${KUBE_PROMPT_SEPARATOR-|}"
KUBE_PROMPT_DIVIDER="${KUBE_PROMPT_DIVIDER-:}"
KUBE_PROMPT_PREFIX="${KUBE_PROMPT_PREFIX-}"
KUBE_PROMPT_SUFFIX="${KUBE_PROMPT_SUFFIX-}"
KUBE_PROMPT_USE_ENV="${KUBE_PROMPT_USE_ENV:-false}"
KUBE_PROMPT_LAST_TIME=0
KUBE_PROMPT_ENABLED=true

_kube_prompt_binary_check() {
  command -v "$1" >/dev/null
}

_kube_prompt_symbol() {
  [[ "${KUBE_PROMPT_SYMBOL_ENABLE}" == false ]] && return

  KUBE_PROMPT_SYMBOL="${KUBE_PROMPT_SYMBOL_DEFAULT}"
  KUBE_PROMPT_SYMBOL_IMG="\u2638 "

  if [[ "${KUBE_PROMPT_SYMBOL_USE_IMG}" == true ]]; then
    KUBE_PROMPT_SYMBOL="${KUBE_PROMPT_SYMBOL_IMG}"
  fi

  echo "${KUBE_PROMPT_SYMBOL}"
}

_kube_prompt_split() {
  type setopt >/dev/null 2>&1 && setopt SH_WORD_SPLIT
  local IFS=$1
  echo $2
}

_kube_prompt_file_newer_than() {
  local mtime
  local file=$1
  local check_time=$2

  zmodload -e "zsh/stat"
  if [[ "$?" -eq 0 ]]; then
    mtime=$(stat +mtime "${file}")
  elif stat -c "%s" /dev/null &> /dev/null; then
    # GNU stat
    mtime=$(stat -c %Y "${file}")
  else
    # BSD stat
    mtime=$(stat -f %m "$file")
  fi
  [[ "${mtime}" -gt "${check_time}" ]]
}

_kube_prompt_update_cache() {
  KUBECONFIG="${KUBECONFIG:=$HOME/.kube/config}"
  if ! _kube_prompt_binary_check "${KUBE_PROMPT_BINARY}"; then
    # No ability to fetch context/namespace; display N/A.
    KUBE_PROMPT_CONTEXT="BINARY-N/A"
    KUBE_PROMPT_NAMESPACE="N/A"
    return
  fi

  if [[ "${KUBE_PROMPT_USE_ENV}" == true ]]; then
    _kube_prompt_get_context_ns "env"
    return
  fi

  if [[ "${KUBECONFIG}" != "${KUBE_PROMPT_KUBECONFIG_CACHE}" ]]; then
    # User changed KUBECONFIG; unconditionally refetch.
    KUBE_PROMPT_KUBECONFIG_CACHE=${KUBECONFIG}
    _kube_prompt_get_context_ns "ns"
    return
  fi

  # kubectl will read the environment variable $KUBECONFIG
  # otherwise set it to ~/.kube/config
  local conf
  for conf in $(_kube_prompt_split : "${KUBECONFIG:-${HOME}/.kube/config}"); do
    [[ -r "${conf}" ]] || continue
    if _kube_prompt_file_newer_than "${conf}" "${KUBE_PROMPT_LAST_TIME}"; then
      _kube_prompt_get_context_ns "ns"
      return
    fi
  done
}

_kube_prompt_get_context_ns() {

  local calltype=$1
  # Set the command time
  if [[ "${calltype}" == "ns" ]]; then
    KUBE_PROMPT_LAST_TIME=$EPOCHSECONDS
  fi

  KUBE_PROMPT_CONTEXT="$(${KUBE_PROMPT_BINARY} config current-context 2>/dev/null)"
  if [[ -z "${KUBE_PROMPT_CONTEXT}" ]]; then
    KUBE_PROMPT_CONTEXT="N/A"
    KUBE_PROMPT_NAMESPACE="N/A"
    return
  elif [[ "${KUBE_PROMPT_NS_ENABLE}" == true ]]; then
    KUBE_PROMPT_NAMESPACE="$(${KUBE_PROMPT_BINARY} config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)"
    if [[ "${KUBE_PROMPT_USE_ENV}" == true ]]; then
      KUBE_PROMPT_NAMESPACE="${KUBE_PROMPT_NAMESPACE:-}${KUBE_PROMPT_SEPARATOR}${NAMESPACE:-}"
    else
      # Set namespace to 'default' if it is not defined
      KUBE_PROMPT_NAMESPACE="${KUBE_PROMPT_NAMESPACE:-default}"
    fi
  fi
}

# function to disable the prompt on the current shell
kubeon(){
  KUBE_PROMPT_ENABLED=true
}

# function to disable the prompt on the current shell
kubeoff(){
  KUBE_PROMPT_ENABLED=false
}

# Build our prompt
kube_prompt () {
  [[ ${KUBE_PROMPT_ENABLED} != 'true' ]] && return

  KUBE_PROMPT="${KUBE_PROMPT_PREFIX}"
  KUBE_PROMPT+="$(_kube_prompt_symbol)"
  KUBE_PROMPT+="${KUBE_PROMPT_SEPERATOR}"
  KUBE_PROMPT+="${KUBE_PROMPT_CONTEXT}"
  KUBE_PROMPT+="${KUBE_PROMPT_DIVIDER}"
  KUBE_PROMPT+="$KUBE_PROMPT_NAMESPACE"
  KUBE_PROMPT+="$KUBE_PROMPT_SUFFIX"

  echo "${KUBE_PROMPT}"
}
