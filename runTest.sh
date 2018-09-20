#!/bin/bash

# Caller convention: The first parameter has to be the device serial number
# followed by arbitrary DroidMate parameters.
# Do here everything which we have to at running, i.e. preparing the testing
# tool with the parameters passed at runtime and running the tool. Do the
# building during the build phase, if possible.

set -e

echo "Run container ${TOOL_FOLDERNAME}"

# Setup adb
# TODO would be better, if we could include this somehow in the Dockerfile
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
