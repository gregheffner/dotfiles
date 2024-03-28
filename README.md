<div align="center">
    <h1>config files with the Drip💧</h1>

![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![Sublime Text](https://img.shields.io/badge/sublime_text-%23575757.svg?style=for-the-badge&logo=sublime-text&logoColor=important)

</div>

## Contents

1. [Details](#details)
1. [Deploy](#deploy)
1. [Folder Structure](#folderStructure)

<a name="details"></a>

## Details

- **OS**: macOS
- **Shell**: zsh (omz)
- **Terminal**: iTerm2
- **Font**: Hack Nerd Font (Patched)

<a name="firsttime"></a>

## Deploy to a new system

Installing your dotfiles onto a new system (or migrate to this setup)

If you already store your configuration/dotfiles in a Git repository, on a new system you can migrate to this setup with the following steps:

Prior to the installation make sure you have committed the alias to your .bashrc or .zsh:
```bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```
And that your source repository ignores the folder where you'll clone it, so that you don't create weird recursion problems:
```bash
echo ".cfg" >> .gitignore
```
Now clone your dotfiles into a bare repository in a "dot" folder of your $HOME:
```bash
git clone --bare <git-repo-url> $HOME/.cfg
```
Define the alias in the current shell scope:
```bash
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```
Checkout the actual content from the bare repository to your $HOME:
```bash
config checkout

```
The step above might fail with a message like:

error: The following untracked working tree files would be overwritten by checkout:
    .bashrc
    .gitignore
Please move or remove them before you can switch branches.
Aborting

Set the flag showUntrackedFiles to no on this specific (local) repository:
```bash
config config --local status.showUntrackedFiles no
```

```
cd $HOME
config add .vimrc
config commit -m "Add .vimrc"
config push
```

## Config Folder File Structure

- `.bash_profile`:a script that runs whenever you start a new shell  
- `.spackle_1.5`: not really sure LOL
- `.zprofile`: This sets the environment for interactive shells
- `.zshrc`: main configuration file for the Zsh shell
- `Brewfile`: manages packages installed by Homebrew

Thanks to BaDxKaRMa for all the help on this. 

Followed https://www.atlassian.com/git/tutorials/dotfiles for most of this.
