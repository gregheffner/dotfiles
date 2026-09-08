#!/bin/bash
# Bootstrap a fresh Ubuntu (or macOS) machine to this terminal setup. Idempotent; re-run freely.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
os=$(uname -s)
SUDO=""; [[ $EUID -ne 0 ]] && SUDO=sudo
export DEBIAN_FRONTEND=noninteractive

say() { printf '\033[1;36m==> %s\033[0m\n' "$*"; }

# name used for the terminal colour profile and the banner title; pass -n to skip the prompt
name=""
while getopts "n:" o; do [[ $o == n ]] && name=$OPTARG; done
if [[ -z $name ]]; then
  read -rp "Name for the terminal profile and banner title [$(hostname -s)]: " name
  name=${name:-$(hostname -s)}
fi

say "packages"
if [[ $os == Linux ]]; then
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq zsh git curl figlet python3 jq fontconfig unzip lsd >/dev/null || \
  $SUDO apt-get install -y -qq zsh git curl figlet python3 jq fontconfig unzip >/dev/null
elif [[ $os == Darwin ]]; then
  command -v brew >/dev/null || { echo "install Homebrew first: https://brew.sh"; exit 1; }
  brew install zsh git figlet jq lsd >/dev/null; brew install --cask font-hack-nerd-font >/dev/null || true
fi

say "Hack Nerd Font"
if [[ $os == Linux ]] && ! fc-list | grep -qi 'Hack Nerd Font'; then
  mkdir -p ~/.local/share/fonts/HackNerdFont && cd ~/.local/share/fonts/HackNerdFont
  curl -fsSLo Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
  unzip -qo Hack.zip && rm Hack.zip && fc-cache -f >/dev/null; cd "$here"
fi

say "oh-my-zsh + plugins + powerlevel10k"
[[ -d ~/.oh-my-zsh ]] || RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
zc=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
for p in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting zsh-users/zsh-completions zsh-users/zsh-history-substring-search; do
  [[ -d $zc/plugins/${p#*/} ]] || git clone -q --depth 1 https://github.com/$p $zc/plugins/${p#*/}
done
# .zshrc sources it from ~/powerlevel10k
[[ -d ~/powerlevel10k ]] || git clone -q --depth 1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

say "dotfiles → ~ (existing files backed up as *.pre-dotfiles)"
for f in zshrc p10k.zsh; do
  if [[ -e ~/.$f && ! -L ~/.$f ]]; then mv ~/.$f ~/.$f.pre-dotfiles; fi
  ln -sfn "$here/$f" ~/.$f
done
mkdir -p ~/.local/bin
if [[ $os == Darwin ]]; then ln -sfn "$here/banner/banner-mac.sh" ~/.local/bin/banner; else ln -sfn "$here/banner/banner-linux.sh" ~/.local/bin/banner; fi
[[ -f ~/.banner.conf ]]   || sed "s/^TITLE=.*/TITLE=\"$name\"/" "$here/banner/banner.conf.example" > ~/.banner.conf
[[ -f ~/.dotfiles.local ]] || cp "$here/dotfiles.local.example" ~/.dotfiles.local

say "terminal colours"
if [[ $os == Linux ]] && command -v dconf >/dev/null && [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]]; then "$here/colors/gnome-terminal.sh" "$name" || true
else echo "   see colors/README.md for iTerm2 / kitty / GNOME Terminal"; fi

say "default shell"
if [[ $SHELL != */zsh ]] && command -v chsh >/dev/null; then chsh -s "$(command -v zsh)" || echo "   run: chsh -s $(command -v zsh)"; fi

say "done. Open a new terminal. Edit ~/.banner.conf and ~/.dotfiles.local for your hosts."
