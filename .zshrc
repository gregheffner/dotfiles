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


export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || add_to_path "$PYENV_ROOT/bin"
eval "$(pyenv init -)"

export ZSH="$HOME/.oh-my-zsh"

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

source $ZSH/oh-my-zsh.sh

export PATH="/opt/homebrew/bin:$PATH"
export DOCKER_HOST=tcp://192.168.1.11:2376 DOCKER_TLS_VERIFY=1

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
alias matrix='cmatrix -n -s 94 -l o'
alias ls='lsd --group-dirs first'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias l='ls -l'

eval "$(op completion zsh)"; compdef _op op

eval $(thefuck --alias)
export PATH="/opt/homebrew/opt/binutils/bin:$PATH"
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
function gi() { curl -sLw "\n" https://www.toptal.com/developers/gitignore/api/$@ ;}
alias config='/usr/bin/git --git-dir=/Users/Greg/.cfg/ --work-tree=/Users/Greg'
alias config='/usr/bin/git --git-dir=/Users/Greg/.cfg/ --work-tree=/Users/Greg'
