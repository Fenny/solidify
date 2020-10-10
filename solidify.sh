#!/bin/bash

# clear terminal
clear

# version
VERSION="v1.0.0"

# color codes
RESET='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
DGREEN='\033[0;32m'
YELLOW='\033[0;33m'
GREY='\033[1;30m'
BLUE='\033[1;36m'

# _cmd for handling commands
function _cmd {
    # set variables
    DESCRIPTION=$1
    CMD=$2

    # get correct line length
    LINE="───────────────────────────────────"
    LINE=${LINE:${#DESCRIPTION}}

    # reset color
    printf "${RESET}"

    # check if description is given
    if test -n "$1"; then
        # print description
        printf "  ${GREY}─ ${DESCRIPTION} \n${RED}"
        # check if for errors
        if eval "$CMD" > /dev/null; then
            # print success
            printf "  \e[1A\e[K${GREY}─ ${GREEN}${DESCRIPTION} ${GREY}${LINE} ${GREEN}[✓]\n"
            return 0 # success
        fi 
        return 1 # failure
    fi

    # check if for errors
    printf "${RED}" # potential errors should be red
    if eval "$CMD" > /dev/null; then
        return 0 # success
    fi
    return 1 # failure
} 

# _header colorize the given argument with spacing
function _header {
    printf "\n ${YELLOW}$1${RESET}\n"
}

# _clearline overrides the previous line
function _clearline {
    printf "\e[1A\e[K"
}

printf "\n${BLUE} Ubuntu Hardening ${VERSION} ${RESET}\n"


_header "System"
    _cmd "update" 'sudo apt-get update -y' && \
    _cmd "upgrade" 'sudo apt-get full-upgrade -y'
    _cmd "autoremove" "sudo apt-get autoremove"
    _cmd "autoclean" "sudo apt-get autoclean"

_header "Dependencies"
    _cmd "install wget" 'sudo apt-get install wget -y'
    _cmd "install ufw" 'sudo apt-get install ufw -y'
    _cmd "install sed" 'sudo apt-get install sed -y'

_header "Firewall"
    _cmd "disable ufw" 'sudo ufw disable' && \
    _cmd "reset rules" 'echo "y" | sudo ufw reset' && \
    _cmd "disable logging" 'sudo ufw logging off' && \
    _cmd "deny incoming" 'sudo ufw default deny incoming' && \
    _cmd "allow outgoing" 'sudo ufw default allow outgoing' && \
    _cmd "allow 80/tcp" 'sudo ufw allow 80/tcp' && \
    _cmd "allow 443/tcp" 'sudo ufw allow 443/tcp'
    printf "  ${YELLOW}─ Specify SSH port [default 22]: ${RESET}"
    read -p "" prompt
    if [[ $prompt != "" ]]; then
        _clearline
        _cmd "allow ${prompt}/tcp" 'sudo ufw allow ${prompt}/tcp'
        _cmd "update sshd config" 'sudo sed -i "/Port /Id" /etc/ssh/sshd_config' && \
        _cmd "" 'sudo echo "Port ${prompt}" | sudo tee -a /etc/ssh/sshd_config'
    else 
        _clearline
        _cmd "allow 22/tcp" 'sudo ufw allow 22/tcp'
    fi
    _cmd "enable ufw" 'sudo ufw --force enable'


_header "Network"
    _cmd "enable cloudflare ns" 'sudo sed -i "/nameserver /Id" /etc/resolv.conf' && \
    _cmd "" 'sudo echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf' && \
    _cmd "" 'sudo echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf'

    _cmd "disable ipv6 sysctl" 'sudo sed -i "/net.ipv6.conf.lo.disable_ipv6/Id" /etc/sysctl.d/99-sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv6.conf.all.disable_ipv6/Id" /etc/sysctl.d/99-sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv6.conf.default.disable_ipv6/Id" /etc/sysctl.d/99-sysctl.conf'
    _cmd "" 'echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf' && \
    _cmd "" 'echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf' && \
    _cmd "" 'echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf'

    _cmd "disable ipv6 ufw" 'sudo sed -i "/ipv6=/Id" /etc/default/ufw' && \
    _cmd "" 'sudo echo "IPV6=no" | sudo tee -a /etc/default/ufw'

    _cmd "disable ipv6 grub" 'sudo sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/Id" /etc/default/grub' && \
    _cmd "" 'sudo echo "GRUB_CMDLINE_LINUX_DEFAULT=\"ipv6.disable=1 quiet splash\"" | sudo tee -a /etc/default/grub'

    _cmd "ignore icmp echo" 'sudo sed -i "/net.ipv4.icmp_echo_ignore_/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'sudo echo "net.ipv4.icmp_echo_ignore_all = 1" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'echo 1 | sudo tee /proc/sys/net/ipv4/icmp_echo_ignore_all'

    _cmd "block syn attacks" 'sudo sed -i "/net.ipv4.tcp_max_syn_backlog/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv4.tcp_synack_retries/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv4.tcp_syn_retries/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo sed -i "/net.ipv4.tcp_syncookies/Id" /etc/sysctl.conf' && \
    _cmd "" 'sudo echo "net.ipv4.tcp_max_syn_backlog = 2048" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'sudo echo "net.ipv4.tcp_synack_retries = 2" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'sudo echo "net.ipv4.tcp_syn_retries = 5" | sudo tee -a /etc/sysctl.conf' && \
    _cmd "" 'sudo echo "#net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf'

_header "NTP"
    _cmd "disable ntp.ubuntu.com" 'sudo sed -i "/NTP=/Id" /etc/systemd/timesyncd.conf' && \
    _cmd "enable time.cloudflare.com" 'echo "NTP=time.cloudflare.com" | sudo tee -a /etc/systemd/timesyncd.conf' && \
    _cmd "" 'echo "FallbackNTP=ntp.ubuntu.com" | sudo tee -a /etc/systemd/timesyncd.conf'

_header "System logs"
    _cmd "disable sysctl logs" 'sudo sed -i "/kernel.dmesg_restrict/Id" /etc/sysctl.conf' && \
    _cmd "" 'echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf'
    _cmd "disable rsyslog" 'sudo systemctl stop syslog.socket rsyslog.service' && \
    _cmd "" 'sudo service rsyslog stop' && \
    _cmd "" 'sudo systemctl disable rsyslog'
    _cmd "hide kernel pointers" 'sudo sed -i "/kernel.kptr_restrict/Id" /etc/sysctl.conf' && \
    _cmd "" 'echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf'

_header "Golang"
    _cmd "download" 'sudo wget -q -c https://dl.google.com/go/$(curl -s https://golang.org/VERSION?m=text).linux-amd64.tar.gz -O go.tar.gz' && \
    _cmd "unpack" 'sudo tar -C /usr/local -xzf go.tar.gz' && \
    _cmd "export path" 'export PATH="/path/to/directory/go/bin/:$PATH" >> ~/.bashrc' && \
    _cmd "reload path" 'source ~/.bashrc'  && \
    _cmd "remove go.tar.gz" "sudo rm go.tar.gz"

_header "Cleanup"
    _cmd "apt clean" "sudo apt-get clean"
    _cmd "reload sysctl" 'sudo sysctl -p'
    _cmd "realod ssh" "sudo service ssh restart"
    _cmd "reload grub2" 'sudo update-grub2 2>&1'
    _cmd "reload timesyncd" 'sudo systemctl restart systemd-timesyncd'

printf "\n${YELLOW} Do you want to reboot [Y/n]? ${RESET}"
read -p "" prompt
if [[ $prompt == "y" || $prompt == "Y" ]]; then
    sudo reboot
fi

exit
