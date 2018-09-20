#!/bin/bash

# You can also build it with custom ARGs and ENVs with --build-arg
# Docker ref: https://docs.docker.com/engine/reference/commandline/build/
docker build -t farmtesting:latest .
#docker build -q -t farmtesting:latest . 2>/dev/null
