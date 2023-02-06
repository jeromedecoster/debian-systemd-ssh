#!/bin/bash

COUNT=1
# https://stackoverflow.com/a/806923
# test if a variable is a number
re='^[0-9]+$'
[[ $1 =~ $re ]] && COUNT=$1

# https://superuser.com/a/1716577
# `sort --numeric-sort` return `debian-1 debian-10 debian-11 debian-2 debian-3 ... debian-9`
# `sort --numeric-sort --field-separator=- --key=2` return `debian-1 debian-2 ... debian-9 debian-10 debian-11`
LAST_INDEX=$(containers_names \
    | tail --lines 1 \
    | cut --delimiter=- --fields 2)
# log LAST_INDEX $LAST_INDEX

FIRST=1
[[ -n "$LAST_INDEX" ]] && FIRST=$(($LAST_INDEX + 1))
LAST=$(($LAST_INDEX + $COUNT))
# log FIRST $FIRST
# log LAST $LAST

[[ $FIRST -eq $LAST ]] \
    && info CREATE debian-$FIRST \
    || info CREATE debian-$FIRST ... debian-$LAST

[[ ! -f ~/.ssh/config ]] && touch ~/.ssh/config

for i in $(seq $FIRST $LAST);do
    docker run \
        --detach \
        --privileged \
        --publish-all \
        --name debian-$i \
        --hostname debian-$i \
        --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
        debian-systemd-ssh

    IP=$(docker ps --all --filter "name=^debian-${i}$" --format '{{.ID}}' \
        | xargs docker inspect --format '{{.NetworkSettings.IPAddress}}')
    
    if [[ -z $(grep -E "Host debian-${i}$|Host debian-${i}\s" ~/.ssh/config) ]];
    then
        echo "Host debian-${i} ${IP}
    HostName ${IP}
    User ${USER}
    IdentityFile ~/.ssh/id_debian_systemd_ssh" >> ~/.ssh/config
    fi
    
    # if you receive the error : 
    # WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
    # IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
    # you need to execute : ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "${IP}"
    # or `ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "[${IP}]:${PORT}"`
    # this command add a new line in `~/.ssh/known_hosts`
    # old content is backup in `~/.ssh/known_hosts.old`
    ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R "${IP}" 1>/dev/null 2>/dev/null
    # ⚠ important : after `.ssh/known_hosts` update by ssh-keygen it is HIGHLY recommended 
    # to `sleep 1` second before `ssh-keyscan` to prevent exit code
    # also, do NOT OPEN `.ssh/known_hosts` in an text editor : this can block writing to the file using >>
    sleep 1

    # remove the annoying message : are you sure you want to continue connecting (yes/no/[fingerprint])?
    # list all not commented public keys available from ${IP}
    # filter and retreive ONLY by RSA type of key
    # append result to ~/.ssh/known_hosts
    ssh-keyscan ${IP} 2>/dev/null >> ~/.ssh/known_hosts
done

$PROJECT_DIR/scripts/info.sh
