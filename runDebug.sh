# Run this for debugging purposes. This creates an interactive shell
docker run \
    --net=host \
    -it \
    -v /opt/Android/Sdk/platform-tools/adb:/usr/local/bin/adb \
    farmtesting:latest \
    /bin/bash


    # --privileged \
    # -e APK_FOLDER_SRC='/Users/timtoheus/Projects/droidmatenew/droidmate/apks2/originals/' \
    # -v /opt/Android/Sdk/platform-tools/adb:/usr/local/bin/adb \
    # --mount type=bind,source="/Users/timtoheus/Library/Android/sdk/platform-tools/adb",target=/usr/local/bin/adb \

# docker cp <containerId>:/file/path/within/container /host/path/target
# docker cp <containerId>:${TOOL_OUTPUT_FOLDER} /Users/timtoheus/Downloads
