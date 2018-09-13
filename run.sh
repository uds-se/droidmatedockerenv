# Consider --rm
docker run \
    -e APK_FOLDER_SRC='/Users/timtoheus/Projects/droidmatenew/droidmate/apks2/originals/' \
    --mount type=bind,source="/Users/timtoheus/Library/Android/sdk/platform-tools/adb",target=/usr/local/bin/adb \
    testingenv:latest
# docker cp <containerId>:/file/path/within/container /host/path/target
# docker cp <containerId>:${TOOL_OUTPUT_FOLDER} /Users/timtoheus/Downloads