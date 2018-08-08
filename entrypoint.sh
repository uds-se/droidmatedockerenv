#!/bin/bash

ROOT_HOME="/root/"
cd ${ROOT_HOME}


OUTPUT_TOOL_PATH="${TOOL_PATH}/out/"

function wait_for_boot_complete {
  # @THANKS: https://gist.github.com/stackedsax/2639601
  local boot_property=$1
  local boot_property_test=$2
  echo -n "    - Checking: \"${boot_property} \"... "
  local result=`adb shell ${boot_property} 2> /dev/null | grep "${boot_property_test}"`
  while [ -z $result ]; do
    sleep 1
    result=`adb shell ${boot_property} 2> /dev/null | grep "${boot_property_test}"`
  done
  echo "OK"
}


echo "- Emulator"
if [[ ${ARCH} == *"x86"* ]]; then
    EMU_ARCH="x86"
else
    EMU_ARCH="arm"
fi

CMD="${ANDROID_HOME}/emulator/emulator64-${EMU_ARCH}"
CMD="${CMD} -avd ${AVD_NAME}"
CMD="${CMD} -no-boot-anim"
CMD="${CMD} -no-window"
CMD="${CMD} -no-audio"
CMD="${CMD} -gpu off"
CMD="${CMD} -skin '1080x1920'"
CMD="${CMD} &> ${OUTPUT_TOOL_PATH}/emu.log"
echo "    - CMD=${CMD}"
eval ${CMD} &



echo "- Waiting for emulator to boot completely"
adb wait-for-device &> /dev/null
sleep 1m
# wait_for_boot_complete "getprop dev.bootcomplete" 1
# wait_for_boot_complete "getprop sys.boot_completed" 1
# wait_for_boot_complete "getprop init.svc.bootanim" "stopped"
echo "    - All boot properties succesful"



echo "- DrodMate... "
cd ${TOOL_PATH}


echo -n "    - Copy jars... "
cp ${TOOL_PATH}/project/pcComponents/API/build/libs/shadow-*.jar . && \
    echo "OK" || echo "ERROR"

echo -e "    - args... "
# @NOTE: TIME_TOOL_SEC is set by "docker run -e" in the "run.sh"
args="--Exploration-apksDir=apks"
args="${args} --Selectors-timeLimit=${TIME_TOOL_SEC}"
# # @TODO: Do with config.properties
# echo -b "    - config.properties ... "
# args="--Core-configPath=${DROIDMATE_RUNNER_CONFIG_DOCKER_PATH}"

echo -n "    - Running... "
java -jar $(ls shadow-*.jar) ${args} &> ${OUTPUT_TOOL_PATH}/droidmate_run_$(date +"%Y-%m-%d_%H:%M:%S").log && \
    echo "OK" || echo "ERROR"



# Change folder permissions for user with UID passsed by docker run -e
echo -n "- Changing permissions... "
chown -R ${UID}:${GID} "${OUTPUT_TOOL_PATH}" && \
    echo "OK" || echo "ERROR"