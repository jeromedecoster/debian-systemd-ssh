#!/bin/bash

log() { echo -e "\e[30;47m ${1} \e[0m ${@:2}" >&2; }      # $1 background white
info() { echo -e "\e[48;5;28m ${1} \e[0m ${@:2}" >&2; }   # $1 background green
warn() { echo -e "\e[48;5;202m ${1} \e[0m ${@:2}" >&2; }  # $1 background orange
error() { echo -e "\e[48;5;196m ${1} \e[0m ${@:2}" >&2; } # $1 background red

# https://unix.stackexchange.com/a/22867
# export functions
export -f log info warn error

export BIN_PATH=$(realpath $0)
export PROJECT_DIR=$(dirname $(dirname $BIN_PATH))

under() { echo -e "\033[0;4m${@}\033[0m"; } # write $@ underline
bold()  { echo -e "\033[1m${@}\033[0m"; }   # write $@ in bold

usage() {
    cat << EOF
debian-systemd-ssh : debian and systemd in a docker image that can be connected to via ssh

$(under Usage) dss <command> [option]

$(under Commands)

  $(bold '<nbr>')          Create $(bold nbr) containers
  $(bold d, destroy)     Destroy all containers
  $(bold e, edit)        Edit Dockerfile
  $(bold i, info)        Show running containers information
  $(bold 's, ssh [idx]')   SSH to $(bold 'debian-[idx]'). Missing containers will be created
  
  
$(under Examples)
    
    # connect to debian-1 via ssh (create it first if missing)
    $(bold 'dss s')
    
    # create 3 containers then connect to debian-2 via ssh
    $(bold 'dss 3 && dss s 2')
  
EOF
}

# get running containers names ordered by asc
#
# https://superuser.com/a/1716577
# `sort --numeric-sort` return `debian-1 debian-10 debian-11 debian-2 debian-3 ... debian-9`
# `sort --numeric-sort --field-separator=- --key=2` return `debian-1 debian-2 ... debian-9 debian-10 debian-11`
containers_names() {
    docker ps --all --filter "name=^debian-[0-9]+$" --format '{{.Names}}' \
        | sort --numeric-sort --field-separator=- --key 2
}

# export functions
export -f containers_names 

if [[ $1 == '-v' || $1 == '--version' ]]
then
    VERSION=$(grep '"version"' $PROJECT_DIR/package.json | sed -E 's|[^\.0-9]||g')
    echo debian-systemd-ssh $VERSION
    exit 0
fi

# remove leading 0 + ignore invalid number
NBR=$(expr $1 + 0 2>/dev/null)
if [[ -n $NBR ]]
then
    # max 30
    [[ $NBR -gt 30 ]] && NBR=30
    # abort if < 1
    [[ $NBR -lt 1 ]] && unset NBR
fi

# create and interrupt script
[[ -n $NBR ]] && $PROJECT_DIR/scripts/create.sh $NBR && exit 0

if [[ $1 == 's' || $1 == 'ssh' ]] && [[ $# -eq 1 ]]
then
    SSH=1
else
    # https://stackoverflow.com/a/25806426/1503073
    # regular expressions in a case statement
    # 
    # try capture `s1` or `s=1` and return `1`
    SSH1=$(expr "$1" : '^s[ =]\{0,1\}\([0-9]\{1,\}\)')
    # try capture `c 1` and return `1`
    SSH2=$(expr "$1 $2" : '^s \([0-9]\{1,\}\)')
    # try capture `ssh1` or `ssh=1` and return `1`
    SSH3=$(expr "$1" : '^ssh[ =]\{0,1\}\([0-9]\{1,\}\)')
    # try capture `ssh 1` return `1`
    SSH4=$(expr "$1 $2" : '^ssh \([0-9]\{1,\}\)')
    # get the first non empty value
    SSH=$(echo "$SSH1 $SSH2 $SSH3 $SSH4" | xargs | cut --delimiter=' ' --fields=1)
    # remove leading 0
    SSH=$(expr $SSH + 0)
    # max 30
    [[ $SSH -gt 30 ]] && SSH=30
    # abort if 0
    [[ $SSH -eq 0 ]] && unset SSH
fi

if [[ -n $SSH ]]
then
    LAST_INDEX=$(docker ps --all --filter "name=^debian-[0-9]+$" --format '{{.Names}}' | wc -l)
    
    DIFF=$(($SSH - $LAST_INDEX))
    if [[ $DIFF -gt 0 ]]
    then
        $PROJECT_DIR/scripts/create.sh $DIFF
    fi
    
    # ssh just after container created can throw this error :
    # ssh: connect to host 172.17.0.x port 22: Connection refused
    #
    # an exit code 255 is returned with the error `connection refused`
    # loop until the exit code returned is 0
    while true; do
        # redirect stdout + stderr to null
        ssh debian-$SSH pwd &>/dev/null
        [[ $? -eq 0 ]] && break
        sleep 0.2
    done
    ssh debian-$SSH
    exit 0
fi

case $1 in
    b|build)   shift; $PROJECT_DIR/scripts/build.sh $@ ;;
    d|destroy) shift; $PROJECT_DIR/scripts/destroy.sh $@ ;;
    e|edit)    shift; $PROJECT_DIR/scripts/edit.sh $@ ;;
    i|info)    shift; $PROJECT_DIR/scripts/info.sh $@ ;;
    *) usage ;;
esac
