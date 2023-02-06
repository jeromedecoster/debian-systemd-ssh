#!/bin/bash

NAMES=$(docker ps --all --filter "name=^debian-[0-9]+$" --format '{{.Names}}' \
    | sort --numeric-sort --field-separator=- --key 2)

[[ -z "$NAMES" ]] && exit

# get the longest name character count (for printf tab)
CHAR_COUNT=$(echo "$NAMES" | wc --max-line-length)

echo "$NAMES" \
    | xargs -I%  docker inspect % --format '% {{or .NetworkSettings.IPAddress "-"}}' \
    | xargs printf "%-${CHAR_COUNT}s %s\n"
