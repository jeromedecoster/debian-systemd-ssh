#!/bin/bash
NAMES=$(containers_names)
COUNT=$(echo "$NAMES" | wc --lines)
[[ $COUNT -eq 0 ]] && exit 0

[[ $COUNT -eq 1 ]] \
    && info DESTROY $NAMES \
    || info DESTROY $(echo "$NAMES" | head -n1) ... $(echo "$NAMES" | tail -n1)

docker rm --force $(docker ps --all --filter 'name=^debian-[0-9]+$' --format '{{.ID}}')
