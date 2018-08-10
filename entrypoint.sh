#!/bin/bash

ROOT_HOME="/root/"
cd ${ROOT_HOME}

# @TODO: date incorrect, set the same timezone as host
DATE=$(date +"%Y-%m-%d_%H:%M:%S")


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
# This var from by docker run -e
# DROIDMATE_JAR_FILENAME
cd ${TOOL_PATH}
DROIDMATE_LIBS_PATH="${TOOL_PATH}/${DROIDMATE_LIBS_PATH_RELATIVE}"
DROIDMATE_JAR_FILEPATH="${DROIDMATE_LIBS_PATH}/${DROIDMATE_JAR_FILENAME}"

if [[ "${share_droidmate_flag}" == "1" ]]; then
    echo -n "    - remove all jars... "
    rm "${TOOL_PATH}"/*.jars
    rm "${DROIDMATE_LIBS_PATH}"/*.jars
    echo -n "    - build... "
    log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_build_${DATE}.log"
    ./gradlew build &> ${log_filepath} && \
    echo "OK" || echo "ERROR"
    echo -n "    - shadowJar... "
    log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_shadowJar_${DATE}.log"
    ./gradlew shadowJar &> ${log_filepath}  && \
    echo "OK" || echo "ERROR"
fi

echo -n "    - Copy ${DROIDMATE_JAR_FILENAME} to ${TOOL_PATH}... "
cp ${DROIDMATE_JAR_FILEPATH} ${TOOL_PATH} && \
    echo "OK" || echo "ERROR"

# @NOTE: TIME_TOOL_SEC is set by "docker run -e" in the "run.sh"
#        If you want to change the value, edit the value in the run.properties
TIME_TOOL_MILISEC=$(( ${TIME_TOOL_SEC} * 1000 ))

echo "    - Options to run DroidMate"
echo "        - Type = ${DROIDMATE_TYPE_FILE_CONFIG_TOLOAD}"
case "${DROIDMATE_TYPE_FILE_CONFIG_TOLOAD}" in
    "${DROIDMATE_TYPE_CONFIG_CONFIG_STR}")
        echo "        - config.properties"
        args="--Core-configPath=${DROIDMATE_RUNNER_CONFIG_TOLOAD_DOCKER_PATH}"
        ;;
    
    "${DROIDMATE_TYPE_CONFIG_ARGS_STR}")
        echo "        - Args to run"
        args="$(cat ${DROIDMATE_RUNNER_CONFIG_TOLOAD_DOCKER_PATH})"
        ;;
    
    "def")
        echo "        - Default args to run"
        args="$(cat ${DROIDMATE_RUNNER_CONFIG_ARGS_DEF_DOCKER_PATH})"
        args="${args} --Selectors-timeLimit=${TIME_TOOL_MILISEC}"
        ;;
    
    *)
        echo "        - WARN: DROIDMATE_TYPE_FILE_CONFIG_TOLOAD bad option. Take the defaults."
        echo "        - Default args to run"
        args="$(cat ${DROIDMATE_RUNNER_CONFIG_ARGS_DEF_DOCKER_PATH})"
        args="${args} --Selectors-timeLimit=${TIME_TOOL_MILISEC}"
        ;;
esac

echo "    - Running... "
[[ -z ${TOOL_COMMIT} ]] && TOOL_COMMIT=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_run_${DATE}.log"
CMD="java -jar ${DROIDMATE_JAR_FILEPATH}"
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