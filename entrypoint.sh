#!/bin/bash

ROOT_HOME="/root/"
cd ${ROOT_HOME}

OUTPUT_TOOL_PATH="${TOOL_PATH}/out/"

function change_perms {
    [[ $# -ne 3 ]] && echo "    - ERROR: change_perms req 3 args." && exit 1
    local uid=${1}
    local gid=${2}
    local folder=${3}
    echo -n "- Changing permissions... "
    chown -R "${uid}"":${gid}" "${folder}" && \
        echo "OK" || echo "ERROR" && exit 1
}

function main {
    echo "Main"
    echo "    - Running... "


    # Clone
    # RUN URL="https://github.com/uds-se/${TOOL_REPONAME}.git" && \
        # git clone ${URL} ${TOOL_PATH} && \
        # cd ${TOOL_PATH} && \
        # git checkout ${TOOL_COMMIT_DEF}




    # [[ -z ${TOOL_COMMIT} ]] && TOOL_COMMIT=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
    # log_filepath="${OUTPUT_TOOL_PATH}/${TOOL_REPONAME}_${TOOL_COMMIT}_run_${DATE}.log"
    # CMD="java -jar ${DROIDMATE_JAR_FILEPATH}"
    CMD="${CMD} ${args}"
    # CMD="${CMD} &> ${log_filepath}"
    echo "        - CMD=${CMD}"
    # eval ${CMD}
    echo -n "    - Running... "
}

main "$@"

# TODO needed?
# Change folder permissions for user with UID passsed by docker run -e
# change_perms "${UID}" "${GID}" "${OUTPUT_TOOL_PATH}"