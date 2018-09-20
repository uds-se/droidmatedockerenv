#!/bin/bash

# Caller convention: The first parameter has to be the device serial number
# followed by arbitrary DroidMate parameters.
# Run with --debug to create an interactive shell for debugging purposes
DOCKER_IMAGE="farmtesting:latest"
ADB_PATH_HOST="/opt/Android/Sdk/platform-tools/adb"
ADB_PATH_CONTAINER="/usr/local/bin/adb"
APK_FOLDER_HOST="/tmp/defb22d9-6e5f-4e11-8f60-19a99da4895e/"
APK_HOST="${APK_FOLDER_HOST}com.reddit.frontpage.apk"
APK_FOLDER_CONTAINER="/root/apks"
TOOL_OUTPUT_FOLDER="/root/output"
OUTPUT_FOLDER_HOST="" # Change here

# We have to mount adb to the docker container to prevent opening another adb session.
# There are some incompatibility issues because of that. So it does not work if the host
# system is a macOS or Windows.
# Furthermore, we have to use the host network to communicate seamlessly with the devices.
# Maybe in future we can work on a network based solution:
# https://github.com/sorccu/docker-adb

echo "Called with parameters: $@"

echo "Create the container with image: ${DOCKER_IMAGE}"
# Docker ref: https://docs.docker.com/engine/reference/commandline/create/
if [[ $* == *--debug* ]]; then
	# Execute without parameters
	CONTAINER_ID=$(docker create \
					-i \
					--net=host \
					-v ${ADB_PATH_HOST}:${ADB_PATH_CONTAINER} \
					${DOCKER_IMAGE} \
					/bin/bash)
else
	CONTAINER_ID=$(docker create \
					--net=host \
					-v ${ADB_PATH_HOST}:${ADB_PATH_CONTAINER} \
					${DOCKER_IMAGE} \
					$@)
fi

echo "Copy apk(s) (${APK_HOST}) into container (${APK_FOLDER_CONTAINER})"
# Docker ref: https://docs.docker.com/engine/reference/commandline/cp/
docker cp ${APK_HOST} ${CONTAINER_ID}:${APK_FOLDER_CONTAINER}

echo "Start container: ${CONTAINER_ID}"
# Docker ref: https://docs.docker.com/engine/reference/commandline/start/
if [[ $* == *--debug* ]]; then
	# It seems that -i needs also to be provided during the create process
	docker start -i -a ${CONTAINER_ID}
else
	# Consider --rm
	docker start -a ${CONTAINER_ID}
fi

docker cp ${CONTAINER_ID}:${TOOL_OUTPUT_FOLDER} ${OUTPUT_FOLDER_HOST}
