#!/bin/bash


#
# -> VARS
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOME_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOME_REPO=$(basename "${HOME_REPO_PATH}")
NAME=$(basename "${0}")

VERBOSE=0


ok_color="\e[92m"
error_color="\e[31m"
warn_color="\e[33m"
info_color="\033[0;36m"
reset_color="\e[0m"


##### -> Set in main
DOCKER_RUNNER_CONTAINER_NAME=""
##### <- Set in main


#
# <- VARS
#



#
# -> FUNCTIONS
#

function print_usage() {
    echo "Usage: ${0} -h | --help"
    echo "Usage: ${0} -c'run.properties_file'"
    exit 0
}


trap trap_ctrl_c SIGINT
trap trap_ctrl_c SIGTERM
# @THANKS: https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86
# @THANKS: http://man7.org/linux/man-pages/man7/signal.7.html
function trap_ctrl_c() {
    echo "" && echo ""
    echo -e "${error_color}[X] Trapped CTRL-C${reset_color}"
    id=$(docker ps -q --filter "status=running" --filter "name=${DOCKER_RUNNER_CONTAINER_NAME}")
    if [[ ! -z ${id} ]]; then
        echo -en "${error_color}    [X] Kill container ${DOCKER_RUNNER_CONTAINER_NAME}... "
        docker_kill "${DOCKER_RUNNER_CONTAINER_NAME}" "SIGUSR1"
        echo -en "${error_color}    [X] Removing container ${DOCKER_RUNNER_CONTAINER_NAME}... "
        docker_rm "${DOCKER_RUNNER_CONTAINER_NAME}"
    fi
    exit 143 # 128 + 15 -- SIGTERM
}


function docker_kill() {
    [[ $# -ne 2 ]] && echo "ERROR: docker_kill req 2 args; container, signal." && exit 1
    local container="${1}"
    local signal="${2}"
    echo "docker kill --signal="${signal}" "${container}" > /dev/null"
    docker kill --signal="${signal}" "${container}" > /dev/null
    [[ $? -ne 0 ]] && echo "ERROR" || echo "OK"
    return $?
}

function docker_stop() {
    [[ $# -ne 1 ]] && echo "ERROR: docker_stop req 1 args; container." && exit 1
    local container="${1}"
    docker stop "${container}" > /dev/null
    [[ $? -ne 0 ]] && echo "ERROR" || echo "OK"
    return $?
}

function docker_rm() {
    [[ $# -ne 1 ]] && echo "ERROR: docker_stop req 1 args; container." && exit 1
    local container="${1}"
    docker rm -v "${container}" > /dev/null
    [[ $? -ne 0 ]] && echo "ERROR" || echo "OK"
    return $?
}

function main() {

    argc=$#
    argv=( "$@" )


    RUN_VARS_FILENAME="run.vars"
    source "${RUN_VARS_FILENAME}"

    # @TODO: with getopts
    # API=${1:-"24"}
    # ARCH=${2:-"armeabi-v7a"}
    # TIME_TOOL_SEC=${3:-"60"}
    # TOOL_COMMIT=${4:-"dev"}
    # config_path=${5:-"config.properties"}
    RUN_CONFIG_FILENAME="run.properties"
    RUN_CONFIG_TEMPLATE_FILENAME="run.properties.template"

    # load def values
    source "${RUN_CONFIG_TEMPLATE_FILENAME}"

    # Overwrite with the custom values
    rebuild_opt_docker=""
    update_droidmate=""
    share_droidmate_flag="0"
    APP=""
    TEMP=$(getopt -o c:rda:sh --long config:,rebuild,update-droidmate,app:,share,verbose,h,help, -- "${argv[@]}")
    ex=$?
    [ ${ex} -eq 2 ] && echo "Parameter is not correct." && exit 1
    [ ${ex} -ne 0 ] && echo "Error in getopt" && exit 1
    eval set -- "${TEMP}"
    while true ; do
        case ${1} in
            "-c" | "--config" )
                RUN_CONFIG_FILENAME=${2}
                shift 2 ;;
            "-r" | "--rebuild" )
                rebuild_opt_docker="--no-cache"
                shift 1 ;;
            "-d" | "--update-droidmate" )
                update_droidmate="--no-cache"
                shift 1 ;;
            "-a" | "--app" )
                APP="${2}"
                rm ./apks/*.apk
                cp ./apks_CS/"${APP}" ./apks/
                shift 2 ;;
            "-s" | "--share" )
                share_droidmate_flag="1"
                shift 1 ;;
            
            "--verbose" )
                VERBOSE=1 ; shift 1 ; break ;;

            "-h"|"-help"|"--h"|"--help" )
                print_usage ; exit 0 ;;
            --) shift 1; break ;;
            *)  print_usage; exit 1 ;;
        esac
    done


    if [[ ${rebuild_flag} -eq 1 ]]; then
        rebuild_opt_docker="--no-cache"
        update_droidmate="--no-cache"
    fi
    if [[ ${update_droidmate_flag} -eq 1 ]]; then
        update_droidmate="--no-cache"
    fi

    if [[ ! -f ${RUN_CONFIG_FILENAME} ]]; then
        echo "ERROR: Runner config file: \"${RUN_CONFIG_FILENAME}\" not found"
        echo "INFO: duplicate the ${RUN_CONFIG_TEMPLATE_FILENAME} and edit"
        exit 1
    fi
    source "${RUN_CONFIG_FILENAME}"
    TOOL_COMMIT_ARG=${TOOL_COMMIT}


    PWD=$(pwd)
    DATE_NOW=$(date +"%Y-%m-%d_%H-%M-%S")
    UID_tmp=$(id -u)
    GID_tmp=$(id -g)

    TOOL_NAME="DroidMate"
    TOOL_REPONAME="droidmate"

    DOCKERFILE="Dockerfile"
    DOCKER_TAG_TOOL="${TOOL_REPONAME}"
    DOCKERFILE_EMU="Dockerfile-emu"
    DOCKERFILE_BUILD="Dockerfile-build"

    if [[ "${share_droidmate_flag}" == "1" ]] && [[ -d ${TOOL_REPONAME} ]]; then
        share_droidmate="-v $(pwd)/${TOOL_REPONAME}:${tool_docker_path}"
        TOOL_COMMIT=$(git rev-parse HEAD)
    fi

    DOCKER_EMU_TAG="${TOOL_REPONAME}/${API}/${ARCH}"
    DOCKER_BUILD_TAG="${DOCKER_EMU_TAG}/${TOOL_COMMIT}"
    DOCKER_RUNNER_TAG="${DOCKER_BUILD_TAG}"
    
    DOCKER_RUNNER_CONTAINER_NAME=""
    if [[ "${APP}" != "" ]]; then
        DOCKER_RUNNER_CONTAINER_NAME="${APP}."
    fi
    DOCKER_RUNNER_CONTAINER_NAME="${DOCKER_RUNNER_CONTAINER_NAME}${DATE_NOW}.$(echo ${DOCKER_RUNNER_TAG} | tr '/' '.')"
    # Container name format: [a-zA-Z0-9][a-zA-Z0-9_.-]



    ROOT_HOME="/root/"
    tool_docker_path_relative="${TOOL_REPONAME}/"
    tool_docker_path="${ROOT_HOME}/${tool_docker_path_relative}"

    apks_str="apks"
    apks_host_path="${PWD}/${apks_str}"
    apks_docker_path_relative="${TOOL_REPONAME}/${apks_str}"
    apks_docker_path="${ROOT_HOME}/${apks_docker_path_relative}"
    out_str="out"
    out_host_path="${PWD}/${out_str}/${DOCKER_RUNNER_CONTAINER_NAME}"
    mkdir -p ${out_host_path}
    out_docker_path_relative="${TOOL_REPONAME}/${out_str}"
    out_docker_path="${ROOT_HOME}/${out_docker_path_relative}"
    DROIDMATE_RUNNER_CONFIG_ARGS_DEF_HOST_PATH="${PWD}/${args_def_filename}"
    DROIDMATE_RUNNER_CONFIG_ARGS_DEF_DOCKER_PATH="${ROOT_HOME}/${args_def_filename}"



    # This vars in run.propperties
    # DROIDMATE_TYPE_FILE_CONFIG_TOLOAD
    # DROIDMATE_FILE_CONFIG_TOLOAD_HOST_PATH_RELATIVE
    DROIDMATE_RUNNER_CONFIG_TOLOAD_HOST_PATH="${PWD}/${DROIDMATE_FILE_CONFIG_TOLOAD_HOST_PATH_RELATIVE}"
    DROIDMATE_RUNNER_CONFIG_TOLOAD_DOCKER_PATH="${ROOT_HOME}/${DROIDMATE_FILE_CONFIG_TOLOAD_HOST_PATH_RELATIVE}"

    if [[ -z ${DROIDMATE_TYPE_FILE_CONFIG_TOLOAD} ]]; then
        echo "ERROR: DROIDMATE_TYPE_FILE_CONFIG_TOLOAD"
        exit 1

    fi
    if [[ ! -f ${DROIDMATE_RUNNER_CONFIG_TOLOAD_HOST_PATH} ]]; then
        echo "ERROR: The ${TOOL_NAME} config file (${DROIDMATE_RUNNER_CONFIG_TOLOAD_HOST_PATH}) does not exist" 
        echo "ERROR: Edit the var \"DROIDMATE_FILE_CONFIG_TOLOAD_HOST_PATH_RELATIVE\" in the \"${RUN_CONFIG_FILENAME}\"" 
        exit 1
    fi



    echo "[+] docker build"
    docker_build_log="${out_host_path}/docker_build.log"
    echo -e "\t${info_color}[+] Check the log: ${docker_build_log}${reset_color}"
    echo -n -e "\t[+] ${DOCKERFILE}... "
    docker build \
        ${rebuild_opt_docker} \
        --file ${DOCKERFILE} \
        --tag "${DOCKER_TAG_TOOL}" \
        . > "${docker_build_log}"
    [[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"

    echo -e -n "\t[+] ${DOCKERFILE_EMU}... "
    docker build \
        ${rebuild_opt_docker} \
        --file ${DOCKERFILE_EMU} \
        --tag "${DOCKER_EMU_TAG}" \
        --build-arg FROM_STR="${DOCKER_TAG_TOOL}" \
        --build-arg API_ARG="${API}" \
        --build-arg ARCH_ARG="${ARCH}" \
        . >> "${docker_build_log}"
    [[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"

    echo -e -n "\t[+] ${DOCKERFILE_BUILD}... "
    docker build \
        ${update_droidmate} \
        --file "${DOCKERFILE_BUILD}" \
        --tag "${DOCKER_BUILD_TAG}" \
        --build-arg FROM_STR="${DOCKER_EMU_TAG}" \
        --build-arg TOOL_COMMIT_ARG="${TOOL_COMMIT_ARG}" \
        . >> "${docker_build_log}"
    [[ $? -ne 0 ]] && echo "ERROR" && exit 1 || echo "OK"

    echo "[+] docker run"
    script_to_run="/root/entrypoint.sh"
    docker_run_log="${out_host_path}/docker_run.log"
    
    cmd="docker run \
        -e UID="${UID_tmp}" \
        -e GID="${GID_tmp}" \
        -e TIME_TOOL_SEC="${TIME_TOOL_SEC}" \
        -e share_droidmate_flag=${share_droidmate_flag} \
        -e TOOL_COMMIT=${TOOL_COMMIT} \
        ${share_droidmate} \
        -v "${apks_host_path}":${apks_docker_path} \
        -v "${out_host_path}":${out_docker_path} \
        -v ${DROIDMATE_RUNNER_CONFIG_ARGS_DEF_HOST_PATH}:${DROIDMATE_RUNNER_CONFIG_ARGS_DEF_DOCKER_PATH} \
        -e DROIDMATE_RUNNER_CONFIG_ARGS_DEF_DOCKER_PATH=${DROIDMATE_RUNNER_CONFIG_ARGS_DEF_DOCKER_PATH} \
        -e DROIDMATE_LIBS_PATH_RELATIVE=${DROIDMATE_LIBS_PATH_RELATIVE} \
        -e DROIDMATE_JAR_FILENAME=${DROIDMATE_JAR_FILENAME} \
        -e DROIDMATE_JAR_FILENAME_PATTERN=${DROIDMATE_JAR_FILENAME_PATTERN} \
        -e DROIDMATE_RUNNER_CONFIG_STR=${DROIDMATE_RUNNER_CONFIG_STR} \
        -e DROIDMATE_RUNNER_ARGS_STR=${DROIDMATE_RUNNER_ARGS_STR} \
        -e DROIDMATE_TYPE_FILE_CONFIG_TOLOAD=${DROIDMATE_TYPE_FILE_CONFIG_TOLOAD} \
        -v "${DROIDMATE_RUNNER_CONFIG_TOLOAD_HOST_PATH}":${DROIDMATE_RUNNER_CONFIG_TOLOAD_DOCKER_PATH} \
        -e DROIDMATE_RUNNER_CONFIG_TOLOAD_DOCKER_PATH=${DROIDMATE_RUNNER_CONFIG_TOLOAD_DOCKER_PATH} \
        --device='/dev/dri/card0:/dev/dri/card0' \
        -e DISPLAY="${DISPLAY}" \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        -e XAUTHORITY=/tmp/.docker.xauth \
        -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw \
        --privileged \
        -v /dev/kvm:/dev/kvm:rw \
        -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock:ro '-lxc-conf=lxc.cgroup.devices.allow = c 226:* rwm' \
        --name "${DOCKER_RUNNER_CONTAINER_NAME}" \
        "${DOCKER_RUNNER_TAG}" \
        ${script_to_run} &>> ${docker_run_log}"
    echo ${cmd} > ${docker_run_log}
    [[ ${VERBOSE} -eq 1 ]] && echo -e "\t${info_color}[+] command=${cmd}"
    eval ${cmd} &

    echo "[+] Waiting"
    echo -e "\t${info_color}[+] Check the log: ${docker_run_log}${reset_color}"
    sleep 2s && docker wait "${DOCKER_RUNNER_CONTAINER_NAME}" > /dev/null

    echo -n "[+] Removing container... "
    docker_rm "${DOCKER_RUNNER_CONTAINER_NAME}"
    [[ $? -ne 0 ]] && exit 1
}

#
# <- FUNCTIONS
#



#
# -> MAIN
#

set +e
main "$@"
exit $?
set -e

#
# <- MAIN
#
