#!/bin/bash

droidmate_id_running=("$(docker ps -q --filter=ancestor="droidmate")")
n_droidmate_id_running="${#droidmate_id_running[@]}"

if [[ ${n_droidmate_id_running} -gt 1 ]]; then
    echo "INFO: More than one container match:"
    for container in "${droidmate_id_running[@]}"; do
        echo "    - ${container}"
    done
elif [[ ${droidmate_id_running} == "" ]] || [[ ${n_droidmate_id_running} -eq 0 ]]; then
    echo "INFO: Not containers running at this moment."
elif [[ ${n_droidmate_id_running} -eq 1 ]]; then
    container="${droidmate_id_running[0]}"
    echo "INFO: Going inside: ${container}"
    docker exec -it ${container} /bin/bash
else
    echo "ERROR: ¿?"
    exit 1
fi

exit 0