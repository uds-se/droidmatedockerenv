#!/bin/bash

# You can build with custom ARGs and ENVs with --build-arg
# Docker ref: https://docs.docker.com/engine/reference/commandline/build/

# Example build args
TOOL_COMMIT_DEF="master"
GIT_REPOSITORY="https://github.com/uds-se/droidmate.git"
TOOL_FOLDERNAME="droidmate"

docker build \
        --build-arg TOOL_COMMIT_DEF=${TOOL_COMMIT_DEF} \
        --build-arg GIT_REPOSITORY=${GIT_REPOSITORY} \
        --build-arg TOOL_FOLDERNAME=${TOOL_FOLDERNAME} \
        -t farmtesting:latest .
#docker build -q -t farmtesting:latest . 2>/dev/null
