# ~/.bashrc additions for enhanced CLI and Cloudflare Tunnel info

# Handy ls and kubectl aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias kgn="kubectl get nodes"
alias kgp="kubectl get pods -A"

# Alert alias for long-running commands (requires notify-send)
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Cloudflare Tunnel Info Function with Color Output
tunnelinfo() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  WHITE='\033[0;37m'
  NC='\033[0m' # No Color

  cloudflared tunnel list | awk 'NR>2 {print $1}' | while read id; do
    echo -e "${RED}===== Tunnel ID: ${GREEN}$id${RED} =====${NC}"
    cloudflared tunnel info "$id" | while IFS= read -r line; do
      case "$line" in
        NAME:*)      echo -e "${WHITE}$line${NC}" ;;
        ID:*)        echo -e "${GREEN}$line${NC}" ;;
        CREATED:*)   echo -e "${GREEN}$line${NC}" ;;
        "CONNECTOR ID"*)
          echo -e "${WHITE}$line${NC}" ;;
        [a-f0-9]*\ *Z*)
          connector_id=$(echo "$line" | awk '{print $1}')
          created=$(echo "$line" | awk '{print $2}')
          arch=$(echo "$line" | awk '{print $3}')
          version=$(echo "$line" | awk '{print $4}')
          origin_ip=$(echo "$line" | awk '{print $5}')
          edge=$(echo "$line" | cut -d' ' -f6-)
          echo -e "${YELLOW}${connector_id} ${BLUE}${created} ${WHITE}${arch} ${WHITE}${version} ${BLUE}${origin_ip} ${MAGENTA}${edge}${NC}"
          ;;
        *) echo -e "${WHITE}$line${NC}" ;;
      esac
    done
    echo
  done
}
