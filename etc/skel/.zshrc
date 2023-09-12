#
source /etc/profile

export PATH=$PATH:/go/bin:/usr/local/go/bin
export ZSH=/oh-my-zsh
export ZSH_CACHE_DIR=$(mktemp -d)

ZSH_THEME="simple"
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

DISABLE_AUTO_UPDATE="true"
DISABLE_LS_COLORS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
  history
  kubectl
)

source $ZSH/oh-my-zsh.sh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

unsetopt inc_append_history
unsetopt share_history

alias kube='kubectl'
