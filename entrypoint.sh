#!/bin/bash

ROOT_HOME="/root/"
cd ${ROOT_HOME}


OUTPUT_TOOL_PATH="${TOOL_PATH}/out/"

function wait_for_boot_complete {
  # @THANKS: https://gist.github.com/stackedsax/2639601
  local boot_property=$1
  local boot_property_test=$2
  echo -n "    - Checking: \"${boot_property}\"... "
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

# # OLD way
# TIME_WAIT_EMU_BOOT="1m"
# if [[ ${EMU_ARCH} == "arm" ]]; then
#     TIME_WAIT_EMU_BOOT="30m"
# fi
# sleep ${TIME_WAIT_EMU_BOOT}
# DEBUG: adb shell getprop init.svc.bootanim && adb shell getprop init.svc.goldfish-setup && adb shell getprop service.bootanim.exit && adb shell getprop sys.boot_completed && adb shell getprop dev.bootcomplete

# @TODO: check the correct order
# running -> stopped
wait_for_boot_complete "getprop init.svc.bootanim" "stopped"
# running -> stopped
wait_for_boot_complete "getprop init.svc.goldfish-setup" "stopped"
# 0 -> 1
wait_for_boot_complete "getprop service.bootanim.exit" "1"
# not exist -> 1
wait_for_boot_complete "getprop sys.boot_completed" "1"
# not exist -> 1
wait_for_boot_complete "getprop dev.bootcomplete" "1"
echo "    - All boot properties succesful"


echo "- DrodMate:"
cd ${TOOL_PATH}

if [[ "${share_droidmate_flag}" == "1" ]]; then
    echo -n "    - build... "
    log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_build_$(date +"%Y-%m-%d_%H:%M:%S").log"
    ./gradlew build &> ${log_filepath} && \
    echo "OK" || echo "ERROR"
    echo -n "    - shadowJar... "
    log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_shadowJar_$(date +"%Y-%m-%d_%H:%M:%S").log"
    ./gradlew shadowJar &> ${log_filepath}  && \
    echo "OK" || echo "ERROR"
fi

echo -n "    - Copy jars... "
cp ${TOOL_PATH}/project/pcComponents/API/build/libs/shadow-*.jar . && \
    echo "OK" || echo "ERROR"

if [[ -f ${DROIDMATE_RUNNER_CONFIG_DOCKER_PATH} ]]; then
    echo "    - config.properties"
    args="--Core-configPath=${DROIDMATE_RUNNER_CONFIG_DOCKER_PATH}"
else
    # @TODO: remove
    echo -e "    - Args to run"
    # @NOTE: TIME_TOOL_SEC is set by "docker run -e" in the "run.sh"
    args="--Exploration-apksDir=apks"
    args="${args} --Selectors-timeLimit=${TIME_TOOL_SEC}"
fi

echo -e "    - Args to run"
# @NOTE: TIME_TOOL_SEC is set by "docker run -e" in the "run.sh"
args="--Exploration-apksDir=apks"
args="${args} --Selectors-timeLimit=${TIME_TOOL_SEC}"

echo "    - Running... "
[[ -z ${TOOL_COMMIT} ]] && TOOL_COMMIT=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_run_$(date +"%Y-%m-%d_%H:%M:%S").log"
jar_file=$(ls shadow-*.jar)
CMD="java -jar ${jar_file}"
CMD="${CMD} ${args}"
CMD="${CMD} &> ${log_filepath}"
echo "        - CMD=${CMD}"
eval ${CMD}
ret=$?
echo -n "    - Running... "
[[ ${ret} -eq 0 ]] && echo "OK" || echo "ERROR"



# Change folder permissions for user with UID passsed by docker run -e
echo -n "- Changing permissions... "
chown -R ${UID}:${GID} "${OUTPUT_TOOL_PATH}" && \
    echo "OK" || echo "ERROR"