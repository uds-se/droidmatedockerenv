#!/bin/bash

# Caller convention:
# - The first parameter has to be the device serial number.
# - As next follows a list in square brackets in this format: [ keyword=val keyword2=val2 ]. Right now,
#   only 'dependency' is supported as keyword, i.e. a git repository is expected, cloned, and
#   gradlew install will be executed.
# - A list of arbitrary DroidMate parameters.
# Example: ./run.sh 07240ba6 [ dependency= https://github.com/uds-se/droidmate ] --Selectors-actionLimit=3
#
# In general:
# Do here everything which we have to at running, i.e. preparing the testing
# tool with the parameters passed at runtime and running the tool. Do the
# building during the build phase, if possible.

set -e

echo "Run container ${TOOL_FOLDERNAME_ENV}"

# Setup adb
# TODO would be better, if we could include this somehow in the Dockerfile
ln -sf ${ADB_PATH_CONTAINER} ${ANDROID_HOME}/platform-tools/adb

cd ${TOOL_PATH}
echo "Parameters: $@"
touch args.txt
if [[ "$#" -ge 1 ]]; then
	echo -n "--Exploration-deviceSerialNumber=$1" > args.txt
fi

# Process DroidMate parameters
echo "Process DroidMate parameters:"
for i in ${@:2}; do
    echo " $i"
	echo -n " $i" >> args.txt
done
echo -n " --Exploration-apksDir=${APK_FOLDER_CONTAINER} --Output-outputDir=${TOOL_OUTPUT_FOLDER}" >> args.txt
echo "Arguments:"
arguments=`cat args.txt`
echo "arguments"

set +e

# Execute
./gradlew run --args='${arguments}'
