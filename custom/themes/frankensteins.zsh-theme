#
# Frankenstein's Theme
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# Kube Prompt is provided by the plug-in kube-prompt.plugin.zsh that has been
# modified to show the value of NAMESPACE variable for use in aliases with
# -n ${NAMESPACE} in them.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

OPEN_BRACKET="%{$fg[blue]%}[%{$reset_color%}"
CLOSE_BRACKET="%{$fg[blue]%}]%{$reset_color%}"

prompt_segment() {
  local fg
  [[ -n $1 ]] && fg="%F{$1}" || fg="%f"
  echo -n "${OPEN_BRACKET} "
  echo -n "%{$fg%}"
  [[ -n $2 ]] && echo -n "${2} ${CLOSE_BRACKET}"
}

prompt_object() {
  local fg
  [[ -n $1 ]] && fg="%F{$1}" || fg="%f"
  echo -n "%{$fg%}"
  [[ -n $2 ]] && echo -n "${2}"
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
 local symbols
 symbols=()
 [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
 [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
 [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

 [[ -n "$symbols" ]] && prompt_segment blue "$symbols"
}

prompt_end() {
  local smiley="%(?,%{$fg[green]%}:%)%{$reset_color%},%{$fg[red]%}:(%{$reset_color%})"
  # This one ONLY works on the Mac?  Why?
  # local return_status="%(?..$(prompt_segment 111 "%?"))"
  local return_status="%(?..${OPEN_BRACKET}%{%F{111}%}%?${CLOSE_BRACKET})"
  local general_status=$(prompt_status)
  # This one only works on the Mac?  Why?
  # local end_prompt=$(prompt_object white "╰─${OPEN_BRACKET}${smiley}${CLOSE_BRACKET}${return_status}${general_status} %# ")
  local end_prompt=$(prompt_object white "╰─${OPEN_BRACKET}${smiley}${CLOSE_BRACKET}${return_status}${general_status}")
  echo ${end_prompt}
}

# Context: Where am I running...  Mac, Linux, Container?
prompt_context() {
    if [[ `uname` = "Darwin" ]]; then
      prompt_segment 111 "%(!.%{%F{yellow}%}.)"
    elif grep 'docker\|lxc' /proc/1/cgroup > /dev/null 2>&1; then
      prompt_segment 111 "%(!.%{%F{yellow}%}.)⏣"
    elif grep 'kubepod' /proc/1/cgroup > /dev/null 2>&1; then
      prompt_segment 111 "%(!.%{%F{yellow}%}.)⎈"
    else
      prompt_segment 111 "%(!.%{%F{yellow}%}.)ꄱ"
    fi
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    prompt_segment 069 "$(basename $VIRTUAL_ENV)"
  fi
}

prompt_aws() {
  prompt_segment 069 "🌧  ${AWS_PROFILE}"
}

prompt_az() {
  prompt_segment 069 "⛈  $(az account show | jq -r .environmentName)"
}

prompt_gcp() {
  prompt_segment 069 "🌥  $(gcloud config get-value project)"
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY='±'
    ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[white]%}%{✔%G%}"
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    #if [[ -n $dirty ]]; then
    if [[ "$dirty" == "$ZSH_THEME_GIT_PROMPT_DIRTY" ]]; then
      prompt_segment yellow
    else
      prompt_segment green
    fi
    echo -n "${ref/refs\/heads\// }$dirty ${CLOSE_BRACKET}"
  fi
}

# Kube: current kube-context
prompt_kube() {
  prompt_segment 081 "$(kube_prompt)"
}

# Dir: current working directory
prompt_dir() {
  prompt_segment 075 "%(3~|%-1~/…/%2~|%4~)"
}

prompt_history_no() {
  prompt_segment 111 "%h"
}

pyenvoff(){
  ZSH_PYENV_PROMPT=OFF
}
pyenvon(){
  ZSH_PYENV_PROMPT=ON
}
diroff(){
  ZSH_DIR_PROMPT=OFF
}
diron(){
  ZSH_DIR_PROMPT=ON
}
gitoff(){
  ZSH_GIT_PROMPT=OFF
}
giton(){
  ZSH_GIT_PROMPT=ON
}
awson(){
  ZSH_AWS_PROMPT=ON
}
awsoff(){
  ZSH_AWS_PROMPT=OFF
}
azon(){
  ZSH_AZ_PROMPT=ON
}
azoff(){
  ZSH_AZ_PROMPT=OFF
}
gcpon(){
  ZSH_GCP_PROMPT=ON
}
gcpoff(){
  ZSH_GCP_PROMPT=OFF
}

logdirectory(){
  if [[ -n ${OLDPWD} ]]; then
    if [[ "${OLDPWD}" != "$(pwd)" ]]; then
      TODAY=$(gdate +"%Y-%m-%d")
      if [[ ! -f ~/${TODAY}-DirectoryNavigation.txt ]]; then
        touch ~/${TODAY}-DirectoryNavigation.txt
      fi
      LOC=$(pwd)
      TS=$(gdate --rfc-3339="seconds")
      echo "${TS}:${ITERM_TAB}:${LOC}" >> ~/${TODAY}-DirectoryNavigation.txt
    fi
  fi
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_context
  # prompt_history_no
  if [[ "$ZSH_PYENV_PROMPT" == "ON" ]]; then
    prompt_virtualenv
  fi
  if [[ "$ZSH_DIR_PROMPT" == "ON" ]]; then
    prompt_dir
  fi
  # this variable is controlled by the kube_prompt.plugin.zsh
  # via 'kubeon' and 'kubeoff' functions
  if [[ ${KUBE_PROMPT_ENABLED} == "true" ]]; then
    prompt_kube
  fi
  if [[ "$ZSH_GIT_PROMPT" == "ON" ]]; then
    prompt_git
  fi
  if [[ "$ZSH_AWS_PROMPT" == "ON" ]]; then
    prompt_aws
  fi
  if [[ "$ZSH_AZ_PROMPT" == "ON" ]]; then
    prompt_az
  fi
  if [[ "$ZSH_GCP_PROMPT" == "ON" ]]; then
    prompt_gcp
  fi
  logdirectory
}

PROMPT='╭─%{%f%b%k%}$(build_prompt)
$(prompt_end) %# '
