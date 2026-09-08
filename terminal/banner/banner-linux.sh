#!/bin/bash
# banner-and-fetch v2 — one renderer for the whole fleet.
# Per-host text lives in ~/.banner.conf (optional). Everything else is derived live.
#
# ~/.banner.conf example:
#   TITLE="Prod"
#   SUBTITLE="K8s - Worker1"          # optional second figlet line
#   FUNCTION="k8s worker"
#   CMDS=("k9s::live k8s logs" "stern . -n prod::all logs in prod")   # hidden if the command is missing
#   STACK=("Edge: <your CDN>" "Firewall: <your FW>")
#   WAN_TAGS=("203.0.113.5::home" "198.51.100.9::vpn")   # label known egress IPs; anything else is flagged

# --- only when someone is actually looking (skip scp/ansible/cron) ---------
[[ -t 1 ]] || exit 0

# --- colours ---------------------------------------------------------------
if [[ -t 1 ]]; then
  RED=$'\033[1;31m' YEL=$'\033[1;33m' CYN=$'\033[1;36m' GRN=$'\033[1;32m' MAG=$'\033[0;35m' DIM=$'\033[2m' NC=$'\033[0m'
else
  RED= YEL= CYN= GRN= MAG= DIM= NC=
fi

# width: ask the tty itself first (zsh does not export COLUMNS, containers often lack TERM), then env, then tput
W=$(stty size </dev/tty 2>/dev/null | awk '{print $2}'); [[ $W =~ ^[1-9][0-9]*$ ]] || W=${COLUMNS:-$(tput cols 2>/dev/null)}; [[ $W =~ ^[1-9][0-9]*$ ]] || W=80
RULE=$(printf '%*s' "$((W < 100 ? W/2 : 50))" '' | tr ' ' '-')

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT INT TERM

# --- per-host config with sane defaults -----------------------------------
TITLE="$(hostname -s)"; SUBTITLE=""; FUNCTION=""; HOMEPAGE=""; CMDS=(); STACK=(); WAN_TAGS=(); BANNER_EXAMPLE=""
[[ -r ~/.banner.conf ]] && . ~/.banner.conf

strip() { sed 's/\x1B\[[0-9;]*[A-Za-z]//g'; }

# --- live status ----------------------------------------------------------
status() {
  local n
  # uptime / load
  echo "${DIM}up $(uptime -p | sed 's/^up //') · load $(cut -d' ' -f1-3 /proc/loadavg)${NC}"
  # pending updates (update-notifier cache, no apt call)
  if [[ -r /var/lib/update-notifier/updates-available ]]; then
    n=$(grep -oE '^[0-9]+ updates? can be' /var/lib/update-notifier/updates-available | cut -d' ' -f1)
    [[ -n $n && $n -gt 0 ]] && echo "${YEL}$n updates pending${NC}"
  fi
  [[ -f /var/run/reboot-required ]] && echo "${RED}REBOOT REQUIRED${NC}"
  # failed units
  n=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
  (( n > 0 )) && echo "${RED}$n failed systemd unit(s)${NC}  ${DIM}systemctl --failed${NC}"
  # wazuh agent (agentd can die while the other daemons run)
  if systemctl list-unit-files wazuh-agent.service &>/dev/null; then
    if pgrep -x wazuh-agentd >/dev/null; then echo "${GRN}wazuh-agent ok${NC}"
    else echo "${RED}wazuh-agentd NOT running${NC}"; fi
  fi
  # k8s node state (only where kubectl + kubeconfig exist)
  if command -v kubectl >/dev/null && kubectl get node "$(hostname)" -o jsonpath='{.spec.unschedulable}{"|"}{.status.conditions[?(@.type=="Ready")].status}' >"$TMP/k8s" 2>/dev/null; then
    IFS='|' read -r cord ready <"$TMP/k8s"
    [[ $ready == True ]] && r="${GRN}Ready${NC}" || r="${RED}NotReady${NC}"
    [[ $cord == true ]] && r+=" ${YEL}CORDONED${NC}"
    echo "k8s node: $r"
  fi
}

# --- left column -----------------------------------------------------------
{
  echo "${CYN}Host-Function: ${FUNCTION:-unset (edit ~/.banner.conf)}${NC}"
  [[ -n $HOMEPAGE ]] && echo "${CYN}${HOMEPAGE}${NC}"
  echo "${YEL}$RULE${NC}"
  status
  echo "${YEL}$RULE${NC}"
  shown=0
  for c in "${CMDS[@]}"; do
    cmd=${c%%::*}; desc=${c#*::}
    # first word must resolve (binary, alias or function) or the line is hidden
    if command -v "${cmd%% *}" >/dev/null 2>&1 || [[ -e ${cmd%% *} ]] \
       || grep -qsE "^\s*(alias ${cmd%% *}=|${cmd%% *}\s*\(\)|function ${cmd%% *}\b)" ~/.bashrc ~/.bash_aliases; then
      echo "${GRN}${cmd}${NC} - ${desc}"; shown=1
    fi
  done
  ((shown)) && echo "${YEL}$RULE${NC}"
  for s in "${STACK[@]}"; do echo "${MAG}$s${NC}"; done
  ((${#STACK[@]})) && echo "${YEL}$RULE${NC}"
  if [[ -n $BANNER_EXAMPLE ]]; then
    echo "${YEL}This is the sample config. Edit ~/.banner.conf${NC}"
    echo "${DIM}https://github.com/gregheffner/dotfiles#make-it-yours${NC}"
  fi
} >"$TMP/left"

# --- WAN egress IP: Cloudflare trace, 2s cap, cached 10 min ---------------
wan_ip() {
  local cache=${XDG_RUNTIME_DIR:-/tmp}/.banner-wan-$UID ip
  if [[ -f $cache && -n $(find "$cache" -mmin -10 2>/dev/null) ]]; then cat "$cache"; return; fi
  ip=$(curl -4sS --max-time 2 https://1.1.1.1/cdn-cgi/trace 2>/dev/null | awk -F= '/^ip=/{print $2}')
  [[ -n $ip ]] && printf '%s' "$ip" >"$cache"
  printf '%s' "$ip"
}
wan=$(wan_ip)
if [[ -z $wan ]]; then wan_line="${YEL}unreachable${NC}"
else
  tag=""; for t in "${WAN_TAGS[@]}"; do [[ ${t%%::*} == "$wan" ]] && tag=${t#*::}; done
  if [[ -n $tag ]]; then wan_line="$wan ${DIM}($tag)${NC}"
  elif ((${#WAN_TAGS[@]})); then wan_line="${RED}$wan UNKNOWN EGRESS${NC}"
  else wan_line=$wan; fi
fi

# --- right column: the seven things that matter on a server -------------
{
  . /etc/os-release
  ip4=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')
  printf '%s%s@%s%s
' "$GRN" "$USER" "$(hostname -s)" "$NC"
  echo "OS:       $PRETTY_NAME"
  echo "Kernel:   $(uname -r)"
  echo "CPU:      $(awk -F: '/model name/{n=$2} END{gsub(/^ +| +$/,"",n); print n}' /proc/cpuinfo) ($(nproc))"
  echo "Memory:   $(free -h | awk '/Mem/{print $3" / "$2}')"
  echo "Disk /:   $(df -h / | awk 'NR==2{print $3" / "$2" ("$5")"}')"
  echo "IP:       ${ip4:-n/a}"
  echo "WAN:      $wan_line"
  echo "Packages: $(dpkg-query -f . -W 2>/dev/null | wc -c) dpkg$(command -v snap >/dev/null && echo ", $(snap list 2>/dev/null | tail -n +2 | wc -l) snap")"
} >"$TMP/right"

# --- k8s nodes: pods on THIS node straight from containerd, no kubeconfig needed ---
CRI=unix:///run/containerd/containerd.sock
if command -v crictl >/dev/null && [[ -S ${CRI#unix://} ]] && sudo -n true 2>/dev/null; then
  {
    echo
    printf '%s%-22s %5s %6s  %s%s\n' "$CYN" "PODS ON NODE" "ready" "ctrs" "attention" "$NC"
    { sudo -n crictl -r "$CRI" pods -o json; echo '@@'; sudo -n crictl -r "$CRI" ps -o json; } 2>/dev/null |
    python3 -c '
import sys, json, collections
G, Y, R, N = ("\033[1;32m", "\033[1;33m", "\033[1;31m", "\033[0m") if sys.stdout.isatty() or True else ("",)*4
pods_j, ps_j = sys.stdin.read().split("@@")
pods = json.loads(pods_j)["items"]; ctrs = json.loads(ps_j)["containers"]
ready = collections.Counter(); stale = collections.defaultdict(list); rc = collections.Counter()
ready_names = {p["metadata"]["name"] for p in pods if p["state"] == "SANDBOX_READY"}
for p in pods:
    ns, nm = p["metadata"]["namespace"], p["metadata"]["name"]
    if p["state"] == "SANDBOX_READY": ready[ns] += 1
    elif nm not in ready_names: stale[ns].append(nm)      # not ready and no ready twin = really down
for c in ctrs: rc[c["labels"].get("io.kubernetes.pod.namespace", "?")] += 1
for ns in sorted(set(ready) | set(stale)):
    note = ", ".join(stale[ns]); col = R if note else G
    name = ns if len(ns) <= 22 else ns[:21] + "…"
    print(f"{col}{name:<22} {ready[ns]:>5} {rc[ns]:>6}{N}  {note}")
' 
  } >>"$TMP/right"
fi

# --- containers: one row per compose project, standalone containers on their own row ---
if command -v docker >/dev/null && docker ps -q >/dev/null 2>&1; then
  {
    echo
    printf '%s%-28s %5s %6s  %s%s\n' "$CYN" "CONTAINERS" "up" "hlthy" "attention" "$NC"
    docker ps -a --format '{{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.State}}\t{{.Status}}' |
    awk -F'\t' -v G="$GRN" -v Y="$YEL" -v R="$RED" -v D="$DIM" -v N="$NC" '
      { proj = ($1 == "") ? $2 : $1; tot[proj]++; only[proj] = $2
        if ($3 == "running") { up[proj]++
          if ($4 ~ /\(healthy\)/) hc[proj]++
          else if ($4 ~ /\(unhealthy\)/) { bad[proj] = bad[proj] $2 " unhealthy; " }
        } else if ($3 == "restarting") { bad[proj] = bad[proj] $2 " restarting; " }
        else if ($4 ~ /Exited \(0\)/) { done[proj]++ }
        else { bad[proj] = bad[proj] $2 " " $3 " " $4 "; " }
      }
      END {
        for (p in tot) {
          note = bad[p]; sub(/; $/, "", note)
          col = (note != "") ? R : (up[p] + done[p] < tot[p]) ? Y : G
          if (note == "" && done[p]) note = D done[p] " one-shot exited 0" N
          name = (tot[p] == 1) ? only[p] : p
          if (length(name) > 28) name = substr(name, 1, 27) "…"
          printf "%s%-28s %2d/%-2d %6s%s  %s\n", col, name, up[p], tot[p], hc[p] + 0, N, note
        }
      }' | sort
  } >>"$TMP/right"
fi

# --- title -----------------------------------------------------------------
echo "$RED"
for t in "$TITLE" "$SUBTITLE"; do
  [[ -n $t ]] || continue
  if command -v figlet >/dev/null; then figlet -w "$W" "$t"; else echo "== $t =="; fi |
    while IFS= read -r l; do printf '%*s%s\n' "$(( (W - ${#l}) / 2 > 0 ? (W - ${#l}) / 2 : 0 ))" '' "$l"; done
done
echo "$NC"

# --- two columns (side by side if they fit, else stacked) ------------------
lw=$(strip <"$TMP/left"  | awk '{ if (length > m) m = length } END { print m+0 }')
rw=$(strip <"$TMP/right" | awk '{ if (length > m) m = length } END { print m+0 }')
if (( lw + rw + 4 <= W )); then
  gap=$(( W - lw - rw ))
  # join on \x01, not tab: read strips leading tabs, which shoves the right column left
  paste -d $'\x01' "$TMP/left" "$TMP/right" | while IFS=$'\x01' read -r l r; do
    ll=$(printf '%s' "$l" | strip | wc -m)
    printf '%s%*s%s\n' "$l" "$(( lw - ll + gap ))" '' "$r"
  done
else
  cat "$TMP/left"; echo; cat "$TMP/right"
fi
echo
