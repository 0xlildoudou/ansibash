function ssh_command() {

    if [[ -n ${INVENTORY} ]]; then
        CURRENT_HOST="$1"
        CURRENT_USER="$2"
        CURRENT_PORT="$3"
        if [[ -n ${SCRIPT} ]]; then
            if ! ssh "${CURRENT_USER}""${CURRENT_HOST}" "${CURRENT_PORT}" "bash -s" < "${SCRIPT}" ; then
                return_code "1" "ssh"
            fi
        elif [[ ${FILE_SEND} == true ]]; then
            if ! scp "${SCP_PORT}" "${FILE_SOURCE}" "${CURRENT_USER}""${CURRENT_HOST}":"${FILE_DESTINATION}";then
                return_code "1" "scp"
            fi
        else
            if ! ssh "${CURRENT_USER}""${CURRENT_HOST}" "${CURRENT_PORT}" "${COMMAND}" ; then
                return_code "1" "ssh"
            fi
        fi
    else
        if [[ -n ${SCRIPT} ]]; then
            if ! ssh "${SINGLE_USER}"@"${1}" "bash -s" < "${SCRIPT}" ; then
                return_code "1" "ssh"
            fi
        elif [[ ${FILE_SEND} == true ]]; then
            if ! scp "${SCP_PORT}" "${FILE_SOURCE}" "${SINGLE_USER}""${1}":"${FILE_DESTINATION}" ; then
                return_code "1" "scp"
            fi
        else
            if ! ssh "${SINGLE_USER}"@"${1}" "${COMMAND}"; then
                return_code "1" "ssh"
            fi
        fi
    fi
}
