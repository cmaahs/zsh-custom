#
# Cobalt2 Theme - https://github.com/wesbos/Cobalt2-iterm
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
##
### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
    # echo $(pwd | sed -e "s,^$HOME,~," | sed "s@\(.\)[^/]*/@\1/@g")
    # echo $(pwd | sed -e "s,^$HOME,~,")
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)✝"
  fi
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    # prompt_segment 055 white
    prompt_segment 055 white
    # print -Pn "\e[48;5;055m $(basename $VIRTUAL_ENV) \e[0m"
    print -Pn " $(basename $VIRTUAL_ENV) "
  fi
}

# Set the iterm2 user variable for use in Status Bar
iterm_set_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    iterm2_set_user_var VirtualEnv " $(basename $VIRTUAL_ENV) "
  fi
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
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    echo -n "${ref/refs\/heads\// }$dirty"
  fi
}

# Set the iterm2 user variable for use in Status Bar
iterm_set_gitprompt() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    iterm2_set_user_var gitPrompt " $((git branch 2> /dev/null) | grep \* | cut -c3-) "
  else
    iterm2_set_user_var gitPrompt "n/a"
  fi

}

# Kube: current kube-context
prompt_kube() {
  prompt_segment 033 black
  print -Pn " $(kube_prompt) "
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black "%(3~|%-1~/…/%2~|%4~)"
  # prompt_segment blue black "…${PWD: -30}"
}

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

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
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
ctxoff(){
  ZSH_KUBE_PROMPT=OFF
}
ctxon(){
  ZSH_KUBE_PROMPT=ON
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_context
  # iterm_set_virtualenv
  if [[ "$ZSH_PYENV_PROMPT" == "ON" ]]; then
    prompt_virtualenv
  fi
  if [[ "$ZSH_DIR_PROMPT" == "ON" ]]; then
    prompt_dir
  fi
  # kube_ps1_prompt
  if [[ "$ZSH_KUBE_PROMPT" == "ON" ]]; then
    #if [[ "$KUBE_PROMPT_ENABLE" == "true" ]]; then
      prompt_kube
    #fi
  fi
  # iterm_set_gitprompt
  if [[ "$ZSH_GIT_PROMPT" == "ON" ]]; then
    prompt_git
  fi
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
