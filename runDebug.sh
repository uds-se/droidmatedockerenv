# Run this for debugging purposes. This creates an interactive shell
docker run \
    -it \
    -e APK_FOLDER_SRC='/Users/timtoheus/Projects/droidmatenew/droidmate/apks2/originals/' \
    -v /Users/timtoheus/Library/Android/sdk/platform-tools/adb:/usr/local/bin/adb \
    testingenv:latest \
    /bin/bash

    # --mount type=bind,source="/Users/timtoheus/Library/Android/sdk/platform-tools/adb",target=/usr/local/bin/adb \

# docker cp <containerId>:/file/path/within/container /host/path/target
# docker cp <containerId>:${TOOL_OUTPUT_FOLDER} /Users/timtoheus/Downloads