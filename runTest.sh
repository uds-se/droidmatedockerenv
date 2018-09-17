#!/bin/bash
# By convention the device serial number will be always passed as first parameter

set -e

echo "Run container ${TOOL_FOLDERNAME}"

# Setup adb
ln -sf ${ADB_PATH_CONTAINER} ${ANDROID_HOME}/platform-tools/adb

cd ${TOOL_PATH}
echo "Parameters: $@"
touch args.txt
if [[ "$#" -ge 1 ]]; then
	echo -n "--Exploration-deviceSerialNumber=$1" > args.txt
fi
for i in ${@:2} ; do
	echo -n " $i" >> args.txt
done
echo -n " --Exploration-apksDir=${APK_FOLDER_CONTAINER} --Output-outputDir=${TOOL_OUTPUT_FOLDER}" >> args.txt
echo "Content of args.txt:"
cat args.txt
./gradlew ':project:pcComponents:command:run'

set +e
