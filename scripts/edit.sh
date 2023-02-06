#!/bin/bash

if [[ -n $(which xdg-open) ]]; then
    xdg-open $PROJECT_DIR/scripts/Dockerfile
elif [[ -n $(which open) ]]; then
    open $PROJECT_DIR/scripts/Dockerfile
else
    info OPEN $PROJECT_DIR/scripts/Dockerfile
fi
