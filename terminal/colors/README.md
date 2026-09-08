# Palette

Monokai-style on near-black, exported from the iTerm2 profile. Same 16 ANSI colours in every file.

| | |
|---|---|
| background | `#0d0d0d` |
| foreground | `#e0e0e0` |
| cursor | `#ffa827` |
| red / green / yellow | `#f92a72` `#a6e22e` `#fff100` |
| blue / magenta / cyan | `#2b74ee` `#ae80fe` `#66d9ef` |

- **iTerm2**: Preferences → Profiles → Colors → Color Presets → Import `palette.itermcolors`
- **GNOME Terminal (Ubuntu)**: `./gnome-terminal.sh "My Name"` creates a profile with that name and makes it default
- **kitty**: `include kitty-palette.conf` in `~/.config/kitty/kitty.conf`

Font is **Hack Nerd Font 11** everywhere. `install.sh` installs it on Linux; on macOS `brew install --cask font-hack-nerd-font`.
