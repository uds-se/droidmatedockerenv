#!/bin/bash

set -e

echo "Run container ${TOOL_FOLDERNAME}"
echo ${TOOL_PATH}
cd ${TOOL_PATH}
echo "$@"
echo "$@" > args.txt
echo -e "\n--Exploration-apksDir=${APK_FOLDER_CONTAINER}"
echo -e "\n--Exploration-apksDir=${APK_FOLDER_CONTAINER}" >> args.txt
./gradlew ':project:pcComponents:command:run'

set +e

# set +e
# main "$@"
# exit $?
# set -e
