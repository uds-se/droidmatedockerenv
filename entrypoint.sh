#!/bin/bash

ROOT_HOME="/root/"
cd ${ROOT_HOME}




#
# -> VARS
#

# @TODO: date incorrect, set the same timezone as host
DATE=$(date +"%Y-%m-%d_%H:%M:%S")

OUTPUT_TOOL_PATH="${TOOL_PATH}/out/"

#
# <- VARS
#



#
# -> FUNCTIONS
#

function change_perms {
    [[ $# -ne 3 ]] && echo "    - ERROR: change_perms req 3 args." && exit 1
    local uid=${1}
    local gid=${2}
    local folder=${3}
    echo -n "- Changing permissions... "
    chown -R "${uid}"":${gid}" "${folder}" && \
        echo "OK" || echo "ERROR" && exit 1
}


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


function main {
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
        rm "${TOOL_PATH}"/*.jars &> /dev/null
        rm "${DROIDMATE_LIBS_PATH}"/*.jars &> /dev/null
        echo -n "    - build... "
        log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_build_${DATE}.log"
        ./gradlew build &> ${log_filepath} && \
        echo "OK" || echo "ERROR" && exit 1
        echo -n "    - shadowJar... "
        log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_shadowJar_${DATE}.log"
        ./gradlew shadowJar &> ${log_filepath}  && \
        echo "OK" || echo "ERROR" && exit 1
    fi

    if [[ ! -f ${DROIDMATE_JAR_FILENAME} ]]; then
        echo "    - WARN: The DROIDMATE_JAR_FILENAME var (=${DROIDMATE_JAR_FILENAME}) is wrong. Please check your \"run.properties\"."
        DROIDMATE_JAR_FILENAME_array=( $(find . -name "${DROIDMATE_JAR_FILENAME_PATTERN}") )
        [[ ${#DROIDMATE_JAR_FILENAME_array[@]} -ne 1 ]] && echo "ERROR: " && exit 1
        DROIDMATE_JAR_FILENAME=${DROIDMATE_JAR_FILENAME_array[0]}
        echo "    - INFO: Found a \"${DROIDMATE_JAR_FILENAME_PATTERN}\". Setting the DROIDMATE_JAR_FILENAME var to ${DROIDMATE_JAR_FILENAME}."
    fi

    echo -n "    - Copy ${DROIDMATE_JAR_FILENAME} to ${TOOL_PATH}... "
    cp ${DROIDMATE_JAR_FILEPATH} ${TOOL_PATH} && \
        echo "OK" || echo "ERROR" && exit 1

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
}

#
# <- FUNCTIONS
#



#
# -> MAIN
#

sleep 9999999999999999999

# SIGUSR1-handler
# @THANKS: https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86
# @THANKS: http://man7.org/linux/man-pages/man7/signal.7.html
function trap_sigusr1() {
    echo "[X] trap_sigusr1"
    change_perms "${UID}" "${GID}" "${OUTPUT_TOOL_PATH}"
    exit 144; # 128 + 16 -- SIGUSR1
}


# setup handlers
trap 'kill ${!}; trap_sigusr1' SIGUSR1

main "$@"

# Change folder permissions for user with UID passsed by docker run -e
change_perms "${UID}" "${GID}" "${OUTPUT_TOOL_PATH}"

#
# <- MAIN
#