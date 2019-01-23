#!/bin/bash

# Do here everything which we have to at running, i.e. preparing the testing
# tool with the parameters passed at runtime and running the tool. Do the
# building during the build phase, if possible.

set -e

echo "Run container ${TOOL_FOLDERNAME_ENV}"

cd ${TOOL_PATH}
echo "Container was called with the following parameters: $@"
touch args.txt

# Parse the arguments and prepare accordingly the run for DroidMate
for i in "$@"
do
case $i in
    --deviceSerialNumber=*)
    DEVICESERIALNUMBER="${i#*=}"
	echo "DEVICESERIALNUMBER=$DEVICESERIALNUMBER"
    # Don't add the real device serial number as DroidMate parameter, as it might differ
    # from the device name listed in the adb device listing. DroidMate will anyway connect
    # to the one and only available device
	# echo -n " --Exploration-deviceSerialNumber=$SERIAL" >> args.txt
    shift
    ;;
    --serverAddress=*)
    SERVERADDRESS="${i#*=}"
	echo "SERVERADDRESS=$SERVERADDRESS"
    # Use adb server socket. This is the case when using the emulator container.
	export ADB_SERVER_SOCKET=tcp:$SERVERADDRESS:5037
	echo -n " --TcpClient-serverAddress=$SERVERADDRESS" >> args.txt
	shift
    ;;
    --remoteConnectUrl=*)
    REMOTECONNECTURL="${i#*=}"
	echo "REMOTECONNECTURL=$REMOTECONNECTURL"
	# Connecto to remote address
	adb connect $REMOTECONNECTURL
    shift
    ;;
	--toolParameters=*)
    TOOLPARAMETERS="${i#*=}"
	echo "TOOLPARAMETERS=$TOOLPARAMETERS"
	echo -n " $TOOLPARAMETERS" >> args.txt
    shift
    ;;
    *)
		echo "Unknown option"
    ;;
esac
done

# Finally set the apks directory and output directory for DroidMate
echo -n " --Exploration-apksDir=${APK_FOLDER_CONTAINER} --Output-outputDir=${TOOL_OUTPUT_FOLDER}" >> args.txt

# Print out the connected devices
adb devices

echo "Arguments for DroidMate:"
arguments=`cat args.txt`
echo ${arguments}

set +e

# Execute
./gradlew run --args="${arguments}"
