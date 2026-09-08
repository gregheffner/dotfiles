# terminal

The terminal I use everywhere: zsh + oh-my-zsh + powerlevel10k, a Monokai-on-black palette, Hack Nerd Font, and a login banner that shows what matters on that machine.

## One-line setup on a fresh Ubuntu or Mac

```
git clone https://github.com/gregheffner/dotfiles ~/dotfiles && ~/dotfiles/terminal/install.sh
```

Installs the packages, plugins, prompt theme and font, symlinks the dotfiles, asks you for a profile name, creates a GNOME Terminal profile with the palette, and switches your shell to zsh. Backs up anything it replaces as `*.pre-dotfiles`. Safe to re-run.

## What's inside

| Path | What |
|---|---|
| `zshrc` `p10k.zsh` | shell + prompt, symlinked to `~/.zshrc` and `~/.p10k.zsh`. Tools are optional: each alias only loads if the tool exists |
| `banner/` | login banner. `banner-mac.sh` (iTerm2 clickable links, live k8s summary) and `banner-linux.sh` (containers or pods on the host, WAN egress, failed units). Both read `~/.banner.conf` |
| `colors/` | the palette as `.itermcolors`, GNOME Terminal script, and kitty theme |
| `dotfiles.local.example` | where your hosts, aliases and 1Password references go. Copied to `~/.dotfiles.local`, never committed |

## Make it yours

The install ships placeholder links and a sample stack line, and the banner says so until you edit it. Two untracked files hold everything personal:

**`~/.banner.conf`** — what the login banner shows. Open it and replace the placeholders:

| Setting | What it does |
|---|---|
| `TITLE`, `FUNCTION` | figlet title and the one-line role of the machine |
| `HOMEPAGE`, `VAULT`, `PASSPORT` | your site, Obsidian vault name, path to a local network map |
| `LINKS` | `"text::url::description"` gets its own line, `"text::url"` groups onto one row. Clickable in iTerm2 |
| `CMDS` | `"command::description"`, shown only when the command exists on that machine |
| `STACK` | free text at the bottom: your edge, firewall, DNS, agents |
| `WAN_TAGS` | label your known egress IPs so the WAN line reads `1.2.3.4 (home)` and flags anything else |
| `BASTION` | an ssh alias to health-check at login |

Delete the `BANNER_EXAMPLE=1` line when you're done and the reminder goes away. Re-run `~/.local/bin/banner` to see the result.

**`~/.dotfiles.local`** — ssh aliases, 1Password vault names, wrappers that inject secrets at call time. See `dotfiles.local.example`.

Nothing in the repo contains a hostname, address or credential. Keep it that way.
