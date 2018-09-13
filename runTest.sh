#!/bin/bash

set -e

echo "Run container ${TOOL_FOLDERNAME}"
arch
adb devices
cd ${TOOL_PATH}
# ./gradlew ':project:pcComponents:command:run'

set +e

# set +e
# main "$@"
# exit $?
# set -e