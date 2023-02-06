#!/bin/bash

log() { echo -e "\e[30;47m ${1} \e[0m ${@:2}" >&2; }      # $1 background white
warn() { echo -e "\e[48;5;202m ${1} \e[0m ${@:2}" >&2; }  # $1 background orange
error() { echo -e "\e[48;5;196m ${1} \e[0m ${@:2}" >&2; } # $1 background red

[[ -z $(which git) ]] && { error ABORT 'git must be installed'; exit; }


# ask sudo access
warn WARN 'sudo access required ...'
sudo echo >/dev/null
# one more check if the user abort the password question
[[ -z $(sudo --non-interactive uptime 2>/dev/null) ]] && { error ABORT 'sudo required'; exit; }


cd /usr/local/lib
sudo rm --force --recursive debian-systemd-ssh
sudo git clone --depth 1 https://github.com/jeromedecoster/debian-systemd-ssh.git

sudo rm --force --recursive /usr/local/bin/dss
sudo ln --symbolic  /usr/local/lib/debian-systemd-ssh/bin/dss.sh /usr/local/bin/dss

sudo chown --recursive $USER:$USER /usr/local/lib/debian-systemd-ssh
# https://unix.stackexchange.com/a/218559
# change ownership of symbolic link
sudo chown --no-dereference $USER:$USER /usr/local/bin/dss