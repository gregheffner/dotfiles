#!/bin/bash
# Creates a GNOME Terminal profile with this palette and font. Usage: gnome-terminal.sh [profile name]
set -e
name=${1:-dotfiles}
command -v dconf >/dev/null || { echo "dconf not found (is this GNOME?)"; exit 1; }
id=$(uuidgen); base=/org/gnome/terminal/legacy/profiles:
list=$(dconf read $base/list | tr -d "[]' " ); new="['${list//,/\',\'}${list:+',}'$id']"
dconf write $base/list "$new"
p=$base/:$id
dconf write $p/visible-name "'$name'"
dconf write $p/use-theme-colors false
dconf write $p/background-color "'#0d0d0d'"
dconf write $p/foreground-color "'#e0e0e0'"
dconf write $p/cursor-colors-set true
dconf write $p/cursor-background-color "'#ffa827'"
dconf write $p/palette "['#222222','#f92a72','#a6e22e','#fff100','#2b74ee','#ae80fe','#66d9ef','#cfcfc2','#75715e','#f92a72','#a6e22e','#fff100','#2b74ee','#ae80fe','#66d9ef','#f8f8f2']"
dconf write $p/use-system-font false
dconf write $p/font "'Hack Nerd Font 11'"
dconf write $base/default "'$id'"
echo "GNOME Terminal profile '$name' created and set as default. Open a new terminal."
