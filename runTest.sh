#!/bin/bash

set -e

echo "Run container ${TOOL_FOLDERNAME}"
cd ${TOOL_PATH}
echo "Parameters: $@"
echo -n "$@ " > args.txt
echo -n "--Exploration-apksDir=${APK_FOLDER_CONTAINER} --Output-outputDir=${TOOL_OUTPUT_FOLDER}" >> args.txt
echo "Content of args.txt:"
cat args.txt
adb devices
#./gradlew ':project:pcComponents:command:run'

set +e

# set +e
# main "$@"
# exit $?
# set -e
