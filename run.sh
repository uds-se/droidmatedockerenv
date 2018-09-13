#!/bin/bash

# Run with --debug to create an interactive shell for debugging purposes
DOCKER_IMAGE="1b4e256b45b9d"
ADB_PATH_HOST="/opt/Android/Sdk/platform-tools/adb"
APK_FOLDER_HOST="/tmp/e20ae504-ec53-452d-9c96-3f99279568d6"
APK_FOLDER_CONTAINER="/root/apks"

# We have to mount adb to the docker container to prevent opening another adb session.
# There are some incompatibility issues because of that. So it does not work if the host
# system is a macOS or Windows.
# Furthermore, we have to use the host network to communicate seemlessly with the devices.

echo "Called with parameters: $@"

docker cp ${APK_FOLDER_HOST} ${DOCKER_IMAGE}:${APK_FOLDER_CONTAINER}

if [[ $* == *--debug* ]]; then
	docker run \
    		--net=host \
    		-it \
    		-v ${ADB_PATH_HOST}:/usr/local/bin/adb \
    		${DOCKER_IMAGE} \
    		/bin/bash
else
	# Consider --rm
	docker run \
        	--net=host \
        	-e APK_FOLDER_SRC=${APK_FOLDER_SRC} \
		-v ${ADB_PATH_HOST}:/usr/local/bin/adb \
    		${DOCKER_IMAGE} \
		./runTest.sh "$@"
fi

    # --privileged \
    # -e APK_FOLDER_SRC='/Users/timtoheus/Projects/droidmatenew/droidmate/apks2/originals/' \
    # -v /opt/Android/Sdk/platform-tools/adb:/usr/local/bin/adb \
    # --mount type=bind,source="/Users/timtoheus/Library/Android/sdk/platform-tools/adb",target=/usr/local/bin/adb \

# docker cp <containerId>:/file/path/within/container /host/path/target
# docker cp <containerId>:${TOOL_OUTPUT_FOLDER} /Users/timtoheus/Downloads
