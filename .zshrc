# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

function add_to_fpath() {
    for dir; do
        if [[ -d "$dir" ]] && [[ ":${fpath[*]}:" != *":$dir:"* ]]; then
            fpath=("$dir" $fpath)
        fi
    done
}

# PATH function
function add_to_path() {
    for dir; do
        if [[ -d "$dir" ]] && [[ ":${path[*]}:" != *":$dir:"* ]]; then
            path=("$dir" $path)
        fi
    done
}


ZSH_THEME="robbyrussell"


plugins=(
  zsh-completions
  zsh-autosuggestions
  git
  sublime
  history-substring-search
  autoswitch_virtualenv $plugins
  zsh-syntax-highlighting
  autoupdate
)

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

export PYENV_ROOT="$HOME/.pyenv"
export ZSH="$HOME/.oh-my-zsh"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/binutils/bin:$PATH"
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
source ~/powerlevel10k/powerlevel10k.zsh-theme
source $ZSH/oh-my-zsh.sh

alias matrix='cmatrix -n -s 94 -l o'
alias ls='lsd --group-dirs first'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias l='ls -l'

eval "$(pyenv init -)"
eval "$(op completion zsh)"; compdef _op op
eval $(thefuck --alias)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
command -v pyenv >/dev/null || add_to_path "$PYENV_ROOT/bin"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

function gi() { curl -sLw "\n" https://www.toptal.com/developers/gitignore/api/$@ ;}
alias config='/usr/bin/git --git-dir=/Users/Greg/.cfg/ --work-tree=/Users/Greg'
