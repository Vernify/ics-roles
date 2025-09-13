#!/bin/bash

COL_WIDTH=30
bold=$(tput bold)
normal=$(tput sgr0)
green=$(tput setaf 2)
blue=$(tput setaf 4)
red=$(tput setaf 1)
failures=0

print_section() {
    echo -e "\n${bold}${blue}===== $1 =====${normal}"
}

print_kv() {
    # Use dynamic column width computed in COL_WIDTH
    printf "%-${COL_WIDTH}s : %s\n" "$1" "$2"
}

check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        print_kv "$2" "$1 not available"
        ((failures++))
        return 1
    fi
    return 0
}

echo -e "${bold}Spec Check v1.0 — $(date '+%Y-%m-%d %H:%M:%S')${normal}"

print_section "System Identity"
print_kv "Hostname" "$(hostname)"
print_kv "OS Version" "$(grep VERSION= /etc/os-release | cut -d= -f2 | tr -d '"')"
print_kv "Kernel" "$(uname -r)"
print_kv "Uptime" "$(uptime -p)"
print_kv "System Status" "$(systemctl is-system-running)"

print_section "CPU & Memory"
print_kv "CPU Count" "$(grep -c ^processor /proc/cpuinfo)"
print_kv "Memory (GB)" "$(free -g | awk '/Mem:/ {print $2}')"

print_section "Storage & Filesystems"
check_cmd pvs "Physical Volumes" && print_kv "Physical Volumes" "$(pvs --noheadings -o pv_name | xargs)"
check_cmd vgs "Volume Groups" && print_kv "Volume Groups" "$(vgs --noheadings -o vg_name | xargs)"
check_cmd lvs "Logical Volumes" && print_kv "Logical Volumes" "$(lvs --noheadings -o lv_name | xargs)"

echo -e "\nMounted Filesystems:"
check_cmd findmnt "Mounted Filesystems" && findmnt -n -o TARGET,FSTYPE -t nfs,ext3,ext4,xfs | column -t

print_section "Disk Layout"
check_cmd lsblk "Disk Layout" && lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | grep -Ev 'loop|sr0'

print_section "Network"
check_cmd ip "Interfaces & IPs" && print_kv "Interfaces & IPs" "$(ip -brief address | awk '{print $1 ": " $3}' | grep -v lo | paste -sd ', ')"
print_kv "Default Route" "$(ip route show default | awk '{print $3}')"
print_kv "DNS Servers" "$(grep ^nameserver /etc/resolv.conf | awk '{print $2}' | paste -sd ', ')"

print_section "Security"
ssh_password_auth=""
ssh_pubkey_auth=""
if command -v sshd >/dev/null 2>&1; then
    ssh_password_auth=$(sshd -T 2>/dev/null | awk '/^passwordauthentication/ {print $2; exit}')
    ssh_pubkey_auth=$(sshd -T 2>/dev/null | awk '/^pubkeyauthentication/ {print $2; exit}')
fi

# Fallback: parse sshd_config for the last non-commented matching line
if [ -z "$ssh_password_auth" ]; then
    ssh_password_auth=$(awk '/^\s*[^#]*PasswordAuthentication/ {print $2}' /etc/ssh/sshd_config | tail -n1)
fi
if [ -z "$ssh_pubkey_auth" ]; then
    ssh_pubkey_auth=$(awk '/^\s*[^#]*PubkeyAuthentication/ {print $2}' /etc/ssh/sshd_config | tail -n1)
fi

# Normalize and present friendly values
fmt_yesno() {
    case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
        yes|y|true|1) echo "yes" ;;
        no|n|false|0) echo "no" ;;
        "") echo "not set" ;;
        *) echo "$1" ;;
    esac
}

print_kv "SSH Password Auth" "$(fmt_yesno "$ssh_password_auth")"
print_kv "SSH Pubkey Auth" "$(fmt_yesno "$ssh_pubkey_auth")"
print_kv "Root Account Expiry" "$(chage -l root | grep 'Account expires' | awk -F: '{ print $2 }' | xargs)"
if systemctl list-unit-files | grep -q '^auditd'; then
    print_kv "Auditd Status" "$(systemctl is-active auditd)"
else
    print_kv "Auditd Status" "Not installed"
fi

## Helper: find sudoers lines matching a pattern and extract the left-most
## user/group token (e.g. 'root' or '%sudo'). Returns a comma-separated
## unique list or 'None'. Permission errors are ignored.
extract_sudo_users() {
    local pattern="$1"
    local matches
    matches=$(grep -R --no-messages -H -I -E "$pattern" /etc/sudoers /etc/sudoers.d 2>/dev/null || true)
    if [ -z "$matches" ]; then
        echo "None"
        return
    fi
    echo "$matches" |
        # remove filename prefix up to first ':' then trim leading space
        sed 's/^[^:]*://' |
        sed 's/^[[:space:]]*//' |
        # drop commented lines
        grep -v '^[[:space:]]*#' |
        # take first token (user/group) and unique sort
        awk '{print $1}' | sort -u | paste -sd ', ' -
}

print_kv "Users with NOPASSWD ALL" "$(extract_sudo_users 'NOPASSWD\s*[:=]?\s*ALL|NOPASSWD\s+ALL')"
print_kv "Users with ALL=(ALL:ALL) ALL" "$(extract_sudo_users 'ALL=\(ALL(:ALL)?\)\s*ALL|ALL=\(ALL\)\s*ALL')"

print_section "Operational Readiness"
print_kv "Time Sync Enabled" "$(timedatectl show -p NTPSynchronized --value)"
print_kv "Machine ID" "$(cat /etc/machine-id)"
if systemctl list-unit-files | grep -q '^telegraf'; then
    print_kv "Monitoring Agent (Telegraf)" "$(systemctl is-active telegraf)"
else
    print_kv "Monitoring Agent (Telegraf)" "Not installed"
fi

## Find timers that reference "backup" and show the timer UNIT(s).
## Use the second-last field (UNIT) to avoid capturing the NEXT time column.
backup_timer=$(systemctl list-timers --all --no-legend --no-pager | grep -i backup | awk '{print $(NF-1)}' | paste -sd ', ')
print_kv "Backup Agent Timer" "${backup_timer:-None}"

echo -e "\n${green}System check complete.${normal}"

if [[ $failures -gt 0 ]]; then
    echo -e "${red}Completed with $failures missing command(s).${normal}"
    exit 1
else
    echo -e "${green}All checks passed.${normal}"
    exit 0
fi
