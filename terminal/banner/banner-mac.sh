#!/bin/bash
# banner-mac.sh — verbose login banner for a personal Mac. iTerm2 clickable links (OSC 8).
# All personal values come from ~/.banner.conf (see banner.conf.example).
[[ -t 1 || -n $BANNER_DEBUG ]] || exit 0

RED=$'\033[1;31m' YEL=$'\033[1;33m' CYN=$'\033[1;36m' GRN=$'\033[1;32m' MAG=$'\033[0;35m' BLU=$'\033[1;34m' DIM=$'\033[2m' NC=$'\033[0m'
# width: ask the tty itself first (zsh does not export COLUMNS), then env, then tput
W=$(stty size </dev/tty 2>/dev/null | awk '{print $2}'); [[ $W =~ ^[1-9][0-9]*$ ]] || W=${COLUMNS:-$(tput cols 2>/dev/null)}; [[ $W =~ ^[1-9][0-9]*$ ]] || W=80
RULE=$(printf '%*s' "$((W < 100 ? W/2 : 50))" '' | tr ' ' '-')
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT INT TERM
CACHE=${TMPDIR:-/tmp}/.banner-mac-$UID; mkdir -p "$CACHE"

# OSC 8 hyperlink: link "text" "url"
link() { printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$2" "$1"; }
# strip colours AND hyperlink escapes for width math
strip() { sed -E $'s/\x1B\\]8;;[^\x1B]*\x1B\\\\//g; s/\x1B\\[[0-9;]*[A-Za-z]//g'; }
# cached "cmd" for N minutes: cached <minutes> <name> <cmd...>
cached() { local m=$1 f=$CACHE/$2; shift 2
  if [[ -f $f && -n $(find "$f" -mmin -"$m" 2>/dev/null) ]]; then cat "$f"; return; fi
  "$@" >"$f.tmp" 2>/dev/null && mv "$f.tmp" "$f" || rm -f "$f.tmp"; cat "$f" 2>/dev/null; }

# ---------------------------------------------------------------- known egress
TITLE="$(scutil --get ComputerName 2>/dev/null || hostname -s)"; FUNCTION="Main PC"; HOMEPAGE=""; VAULT=""; PASSPORT=""; LINKS=(); CMDS=(); STACK=(); WAN_TAGS=(); BASTION=""
[[ -r ~/.banner.conf ]] && . ~/.banner.conf
wan=$(cached 10 wan sh -c 'curl -4sS --max-time 2 https://1.1.1.1/cdn-cgi/trace | awk -F= "/^ip=/{print \$2}"')
if [[ -z $wan ]]; then wan_line="${YEL}unreachable${NC}"; else
  tag=""; for t in "${WAN_TAGS[@]}"; do [[ ${t%%::*} == "$wan" ]] && tag=${t#*::}; done
  if [[ -n $tag ]]; then wan_line="$wan ${DIM}($tag)${NC}"; elif ((${#WAN_TAGS[@]})); then wan_line="${YEL}$wan (unknown egress)${NC}"; else wan_line=$wan; fi; fi

# ---------------------------------------------------------------- left column
{
  echo "${CYN}Host-Function: ${FUNCTION}${NC}"
  hp=""; [[ -n $HOMEPAGE ]] && hp="$(link "${HOMEPAGE#*://}" "$HOMEPAGE")"
  [[ -n $VAULT ]] && hp="${hp:+$hp  ·  }$(link 'Obsidian vault' "obsidian://open?vault=${VAULT}&file=Dashboard")"
  [[ -n $hp ]] && echo "${CYN}${hp}${NC}"
  echo "${YEL}$RULE${NC}"
  # --- status
  echo "${DIM}up $(uptime | sed -E 's/.*up ([^,]*(, *[0-9]+:[0-9]+)?).*/\1/') · load$(sysctl -n vm.loadavg | tr -d '{}')${NC}"
  n=$(cached 60 brew brew outdated --quiet | wc -l | tr -d ' ')
  (( n > 0 )) && echo "${YEL}$n brew packages outdated${NC}  ${DIM}brew upgrade${NC}" || echo "${GRN}brew up to date${NC}"
  if op whoami >/dev/null 2>&1; then echo "${GRN}1Password: signed in${NC}"; else echo "${YEL}1Password: locked${NC}  ${DIM}op signin${NC}"; fi
  if [[ -n $BASTION ]]; then
    if cached 5 bastion ssh -o BatchMode=yes -o ConnectTimeout=2 "$BASTION" 'echo ok' | grep -q ok; then echo "${GRN}bastion ($BASTION) reachable${NC}"; else echo "${RED}bastion ($BASTION) UNREACHABLE${NC}  ${DIM}ssh agent locked?${NC}"; fi
  fi
  echo "${YEL}$RULE${NC}"
  # --- reference links from LINKS=("text::url::description")
  if [[ -n $PASSPORT ]]; then
    if [[ -f $PASSPORT ]]; then echo "${BLU}$(link 'Network Passport' "file://${PASSPORT// /%20}")${NC} - estate map"
    else echo "${BLU}Network Passport${NC} - ${YEL}not found at $PASSPORT${NC}"; fi
  fi
  row=""
  for e in "${LINKS[@]}"; do
    IFS='::' read -r t rest <<<"$e"; u=${e#*::}; u=${u%%::*}; d=${e##*::}; [[ $d == "$u" ]] && d=""
    if [[ -n $d ]]; then [[ -n $row ]] && { echo "$row"; row=""; }; echo "${BLU}$(link "$t" "$u")${NC} - $d"
    else row="${row:+$row · }${BLU}$(link "$t" "$u")${NC}"; fi
  done
  [[ -n $row ]] && echo "$row"
  (( ${#LINKS[@]} + ${#PASSPORT} )) && echo "${YEL}$RULE${NC}"
  # --- commands (only if they resolve)
  for c in "${CMDS[@]}"; do
    cmd=${c%%::*}; first=${cmd%% *}
    if command -v "$first" >/dev/null 2>&1 || alias "$first" >/dev/null 2>&1 || grep -qsE "^\s*alias $first=" ~/.zshrc || grep -qsE "^Host .*\b$first\b" ~/.ssh/config; then
      echo "${GRN}$cmd${NC} - ${c#*::}"; fi
  done
  ((${#CMDS[@]})) && echo "${YEL}$RULE${NC}"
  for x in "${STACK[@]}"; do echo "${MAG}$x${NC}"; done
  ((${#STACK[@]})) && echo "${YEL}$RULE${NC}"
  if [[ -n ${BANNER_EXAMPLE:-} ]]; then
    echo "${YEL}This is the sample config. Edit ~/.banner.conf${NC}"
    echo "${DIM}$(link 'https://github.com/gregheffner/dotfiles#make-it-yours' 'https://github.com/gregheffner/dotfiles#make-it-yours')${NC}"
  fi
} >"$TMP/left"

# ---------------------------------------------------------------- right column
{
  mem_total=$(( $(sysctl -n hw.memsize) / 1073741824 ))
  mem_used=$(vm_stat | awk '/Pages (active|wired down|occupied by compressor)/{gsub(/\./,"",$NF); s+=$NF} END{printf "%.1f", s*16384/1073741824}')
  printf '%s%s@%s%s\n' "$GRN" "$USER" "$(scutil --get LocalHostName 2>/dev/null || hostname -s)" "$NC"
  echo "OS:       macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  echo "Kernel:   $(uname -r) $(uname -m)"
  echo "CPU:      $(sysctl -n machdep.cpu.brand_string) ($(sysctl -n hw.ncpu))"
  echo "Memory:   ${mem_used}Gi / ${mem_total}Gi"
  echo "Disk /:   $(df -h / | awk 'NR==2{print $3" / "$2" ("$5")"}')"
  echo "IP:       $(ipconfig getifaddr "$(route -n get default 2>/dev/null | awk '/interface/{print $2}')" 2>/dev/null || echo n/a)"
  echo "WAN:      $wan_line"
  bat=$(pmset -g batt | awk -F'[;\t]' '/InternalBattery/{gsub(/^ +/,"",$2); print $2 ";" $3}')
  [[ -n $bat ]] && echo "Battery:  ${bat%%;*} ${DIM}(${bat#*;})${NC}"
  echo "Brew:     $(ls /opt/homebrew/Cellar 2>/dev/null | wc -l | tr -d ' ') formulae, $(ls /opt/homebrew/Caskroom 2>/dev/null | wc -l | tr -d ' ') casks"
} >"$TMP/right"

# --- cluster block (kubectl from the Mac, cached 5 min, 6s cap)
if command -v kubectl >/dev/null; then
  {
    echo
    printf '%s%-14s %6s %6s  %s%s\n' "$CYN" "K8S CLUSTER" "ready" "pods" "attention" "$NC"
    cached 5 k8s sh -c 'timeout 6 kubectl get nodes -o json; echo @@; timeout 6 kubectl get pods -A -o json' |
    python3 -c '
import sys, json, collections
G, Y, R, D, N = "\033[1;32m", "\033[1;33m", "\033[1;31m", "\033[2m", "\033[0m"; blank = ""
try:
    nj, pj = sys.stdin.read().split("@@")
    nodes = json.loads(nj)["items"]; pods = json.loads(pj)["items"]
except Exception:
    print(f"{Y}cluster unreachable{N}"); sys.exit()
ready = [n for n in nodes if any(c["type"]=="Ready" and c["status"]=="True" for c in n["status"]["conditions"])]
cord = [n["metadata"]["name"] for n in nodes if n["spec"].get("unschedulable")]
notready = [n["metadata"]["name"] for n in nodes if n not in ready]
ver = nodes[0]["status"]["nodeInfo"]["kubeletVersion"] if nodes else "?"
note = " ".join([f"NotReady:{x}" for x in notready] + [f"CORDONED:{x}" for x in cord])
col = R if notready else (Y if cord else G)
label = "nodes " + ver
print(f"{col}{label:<14} {len(ready):>3}/{len(nodes):<2} {len(pods):>6}{N}  {note}")
bad = collections.defaultdict(list); byns = collections.Counter(); restarts = collections.Counter()
for p in pods:
    ns = p["metadata"]["namespace"]; byns[ns] += 1
    ph = p["status"].get("phase")
    cs = p["status"].get("containerStatuses", [])
    if ph in ("Running", "Succeeded") and all(c.get("ready") for c in cs): continue
    if ph == "Succeeded": continue
    reason = next((c["state"]["waiting"]["reason"] for c in cs if "waiting" in c["state"]), ph)
    bad[ns].append(f"{p['metadata']['name']}({reason})")
for ns in sorted(byns):
    if ns in bad:
        print(f"{R}{ns[:14]:<14} {blank:>6} {byns[ns]:>6}{N}  " + ", ".join(bad[ns])[:60])
# healthy namespaces with pod counts, wrapped to the column width
items = [f"{ns} {byns[ns]}" for ns in sorted(byns) if ns not in bad]
line = ""
for it in items:
    if line and len(line) + len(it) + 3 > 44:
        print(D + line + N); line = ""
    line = it if not line else line + " · " + it
if line: print(D + line + N)
'
  } >>"$TMP/right"
fi

# ---------------------------------------------------------------- title
echo "$RED"
figlet -w "$W" "$TITLE" | while IFS= read -r l; do printf '%*s%s\n' "$(( (W - ${#l}) / 2 > 0 ? (W - ${#l}) / 2 : 0 ))" '' "$l"; done
echo "$NC"

# ---------------------------------------------------------------- two columns
lw=$(strip <"$TMP/left"  | awk '{ if (length > m) m = length } END { print m+0 }')
rw=$(strip <"$TMP/right" | awk '{ if (length > m) m = length } END { print m+0 }')
[[ -n $BANNER_DEBUG ]] && echo "lw=$lw rw=$rw W=$W" >&2
if (( lw + rw + 2 <= W )); then
  gap=$(( W - lw - rw )); (( gap > 12 )) && gap=$(( (W - lw - rw) ))
  # macOS paste ignores control-char delimiters, so read both files in lockstep instead
  nl=$(wc -l <"$TMP/left"); nr=$(wc -l <"$TMP/right")
  while (( nl < nr )); do echo >>"$TMP/left"; ((nl++)); done
  while IFS= read -r l && { IFS= read -r r <&3 || r=""; }; do
    ll=$(printf '%s' "$l" | strip | wc -m | tr -d ' ')
    printf '%s%*s%s\n' "$l" "$(( lw - ll + gap ))" '' "$r"
  done <"$TMP/left" 3<"$TMP/right"
else
  cat "$TMP/left"; echo; cat "$TMP/right"
fi
echo
