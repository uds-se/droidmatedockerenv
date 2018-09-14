#!/bin/bash

# TODO Maybe pass only device serial number and write other args into a file,
# copy that into the container. so that we have this convention and it works
# with arbitrary tools

# Run with --debug to create an interactive shell for debugging purposes
# TODO probably also no hash needed?
DOCKER_IMAGE="63d69f9dd558"
ADB_PATH_HOST="/opt/Android/Sdk/platform-tools/adb"
APK_FOLDER_HOST="/tmp/e20ae504-ec53-452d-9c96-3f99279568d6/"
APK_HOST="/tmp/e20ae504-ec53-452d-9c96-3f99279568d6/sample.apk"
APK_FOLDER_CONTAINER="/root/apks"


# We have to mount adb to the docker container to prevent opening another adb session.
# There are some incompatibility issues because of that. So it does not work if the host
# system is a macOS or Windows.
# Furthermore, we have to use the host network to communicate seemlessly with the devices.

echo "Called with parameters: $@"

echo "Create the container with image: ${DOCKER_IMAGE}"
# Docker ref: https://docs.docker.com/engine/reference/commandline/create/
if [[ $* == *--debug* ]]; then
	# Execute without parameters
	CONTAINER_ID=$(docker create 
					--net=host /
					-v ${ADB_PATH_HOST}:/usr/local/bin/adb \
					-e APK_FOLDER_SRC=${APK_FOLDER_SRC} ${DOCKER_IMAGE} \
					./runTest.sh)
else
	CONTAINER_ID=$(docker create \
					--net=host \
					-v ${ADB_PATH_HOST}:/usr/local/bin/adb \
					-e APK_FOLDER_SRC=${APK_FOLDER_SRC} ${DOCKER_IMAGE} \
					./runTest.sh $@)
fi

echo "Copy apk(s) (${APK_FOLDER_HOST}) into container (${APK_FOLDER_CONTAINER})"
# Docker ref: https://docs.docker.com/engine/reference/commandline/cp/
# It seems that docker does not copy the content of a folder, so we have to pass the file
docker cp ${APK_HOST} ${CONTAINER_ID}:${APK_FOLDER_CONTAINER}

echo "Start container: ${CONTAINER_ID}"
# Docker ref: https://docs.docker.com/engine/reference/commandline/start/
if [[ $* == *--debug* ]]; then
	# Interactive shell with 'docker start' does somehow not work (Why?!)
	docker start -i ${CONTAINER_ID}
			# -v ${ADB_PATH_HOST}:/usr/local/bin/adb \
else
	# Consider --rm
	docker start -a ${CONTAINER_ID}
			# ./runTest.sh "$@"
			# -e APK_FOLDER_SRC=${APK_FOLDER_SRC} \
			# -v ${ADB_PATH_HOST}:/usr/local/bin/adb \
fi

    # --privileged \
    # -e APK_FOLDER_SRC='/Users/timtoheus/Projects/droidmatenew/droidmate/apks2/originals/' \
    # -v /opt/Android/Sdk/platform-tools/adb:/usr/local/bin/adb \
    # --mount type=bind,source="/Users/timtoheus/Library/Android/sdk/platform-tools/adb",target=/usr/local/bin/adb \

# docker cp <containerId>:/file/path/within/container /host/path/target
# docker cp <containerId>:${TOOL_OUTPUT_FOLDER} /Users/timtoheus/Downloads
