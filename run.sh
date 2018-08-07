#!/bin/bash

set +e

# @TODO: with getopts
# API=${1:-"24"}
# ARCH=${2:-"armeabi-v7a"}
# TIME_TOOL_SEC=${3:-"60"}
# TOOL_COMMIT=${4:-"dev"}
# config_path=${5:-"config.properties"}
RUN_CONFIG_FILENAME="run.properties"
RUN_CONFIG_TEMPLATE_FILENAME="run.properties"

if [[ ! -f ${RUN_CONFIG_FILENAME} ]]; then
    echo "ERROR: Runner config file: \"${RUN_CONFIG_FILENAME}\" not found"
    echo "INFO: duplicate the ${RUN_CONFIG_TEMPLATE_FILENAME} and edit"
fi
source "${RUN_CONFIG_FILENAME}"


PWD=$(pwd)
DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")

TOOL_NAME="DroidMate"
TOOL_REPONAME="droidmate"

DOCKERFILE="Dockerfile"
DOCKER_TAG_TOOL="${TOOL_REPONAME}"
DOCKERFILE_RUNNER="Dockerfile-runner"
DOCKER_RUNNER_TAG="${TOOL_REPONAME}/${TOOL_COMMIT}/${API}/${ARCH}"
DOCKER_RUNNER_CONTAINER_NAME=$(echo ${DOCKER_RUNNER_TAG} | tr '/' '.')".${DATE_NOW}"
# Container name format: [a-zA-Z0-9][a-zA-Z0-9_.-]



ROOT_HOME="/root/"

apks_str="apks"
apks_host_path="${PWD}/${apks_str}"
apks_docker_path_relative="${TOOL_REPONAME}/${apks_str}"
apks_docker_path="${ROOT_HOME}/${apks_docker_path_relative}"
out_str="out"
out_host_path="${PWD}/${out_str}/"$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p ${out_host_path}
out_docker_path_relative="${TOOL_REPONAME}/${out_str}"
out_docker_path="${ROOT_HOME}/${out_docker_path_relative}"
config_str="config.properties"
config_host_path="${PWD}/${config_str}"
config_docker_path_relative="${TOOL_REPONAME}/${config_str}"
config_docker_path="${ROOT_HOME}/${config_docker_path_relative}"
DROIDMATE_RUNNER_CONFIG_DOCKER_PATH=${config_docker_path}


UID_tmp=$(id -u)
GID_tmp=$(id -g)


docker build \
    --file ${DOCKERFILE} \
    --tag "${DOCKER_TAG_TOOL}" \
    .

docker build \
    --file ${DOCKERFILE_RUNNER} \
    --tag "${DOCKER_RUNNER_TAG}" \
    --build-arg FROM_STR="${DOCKER_TAG_TOOL}" \
    --build-arg API_ARG="${API}" \
    --build-arg ARCH_ARG="${ARCH}" \
    --build-arg TOOL_COMMIT_ARG="${TOOL_COMMIT_ARG}" \
    .

docker run \
    -e UID="${UID_tmp}" \
    -e GID="${GID_tmp}" \
    -e TIME_TOOL_SEC="${TIME_TOOL_SEC}" \
    -e DROIDMATE_RUNNER_CONFIG_DOCKER_PATH=${DROIDMATE_RUNNER_CONFIG_DOCKER_PATH} \
    -v "${apks_host_path}":${apks_docker_path} \
    -v "${out_host_path}":${out_docker_path} \
    -v "${config_host_path}":${config_docker_path} \
    -e DISPLAY="${DISPLAY}" \
    --device="/dev/dri/card0:/dev/dri/card0" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -e XAUTHORITY=/tmp/.docker.xauth \
    -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw \
    --privileged \
    -v /dev/kvm:/dev/kvm:rw \
    -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock:ro '-lxc-conf=lxc.cgroup.devices.allow = c 226:* rwm' \
    --name "${DOCKER_RUNNER_CONTAINER_NAME}" \
    "${DOCKER_RUNNER_TAG}" \
    bin/bash


docker wait "${DOCKER_RUNNER_CONTAINER_NAME}" > /dev/null

set -e