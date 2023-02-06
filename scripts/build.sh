#!/bin/bash

# create an SSH key silently
# type : RSA 1024 bits
# no passphrase
# file : ~/.ssh/id_debian_systemd_ssh
if [[ ! -f ~/.ssh/id_debian_systemd_ssh ]];
then
    info CREATE 'ssh key ~/.ssh/id_debian_systemd_ssh'
    ssh-keygen -q -t rsa -b 1024 -N '' -f ~/.ssh/id_debian_systemd_ssh
fi

# https://stackoverflow.com/a/59678710/1503073
# you can only use files in your Dockerfile that are within the build context
# usually, this is the Dockerfile's directory `.`
# [[ ! -f $PROJECT_DIR/scripts/id_debian_systemd_ssh.pub ]] && cp ~/.ssh/id_debian_systemd_ssh.pub $PROJECT_DIR/scripts/
SUM1=$(md5sum ~/.ssh/id_debian_systemd_ssh.pub | head -c 32)
SUM2=$(md5sum $PROJECT_DIR/scripts/id_debian_systemd_ssh.pub 2>/dev/null | head -c 32)
[[ $SUM1 != $SUM2 ]] && cp ~/.ssh/id_debian_systemd_ssh.pub $PROJECT_DIR/scripts/

cd $PROJECT_DIR/scripts
info BUILD docker image : debian-systemd-ssh
docker build --build-arg USER=$USER --build-arg LANG=$LANG --tag debian-systemd-ssh .