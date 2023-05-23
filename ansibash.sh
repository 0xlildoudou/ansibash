#!/usr/bin/env bash

#set -x

# COLOR
RED="\033[1;31m"
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

function usage() {

    echo -e "USAGE: ansibash.sh [OPTION] COMMAND"
    echo -e "Run a command or a script on multiple targets."
    echo -e "OPTION:"
    echo -e "-h, --hosts    List of hosts (separated by commas) where the command should be broadcast. "
    echo -e "-i, --inventory    Inventory file with one host per line"
    echo -e "-u, --user     User used for connexion (ssh)"
    echo -e "-o, --output   Print all result to a output file"
    echo -e "-c, --command  Command to broadcast on hosts (always put at the end of the command)"
    echo -e "-s, --script   Run a script to the remote target"
    echo -e "--help         Print this help"

    exit 0
}

function lines() {
    DATE=" [$(date +"%Y-%m-%d %H:%M:%S")]"
    HOST="HOST: $1 "

    title=$(($(tput cols) - (${#DATE} + ${#HOST})))
    line=""
    for i in $(seq 1 $title); do
        line="$line─"
    done
    echo -e "${YELLOW}${HOST}${NC}${line}${GREEN}${DATE}${NC}"
}

function output() {

    CURRENT_HOST="$1"
    CURRENT_USER="$2@"
    CURRENT_PORT="-p $3"
    if [[ ${OUTPUT} == "True" ]]; then

        echo -e "[HOST] : ${CURRENT_HOST} --- ${DATE}" >> ${OUTPUT_FILE}
        ssh_command "${CURRENT_HOST}" "${CURRENT_USER}" "${CURRENT_PORT}" >> ${OUTPUT_FILE}
        echo -e "---" >> ${OUTPUT_FILE}

    else

        lines "${CURRENT_HOST}"

        ssh_command "${CURRENT_HOST}" "${CURRENT_USER}" "${CURRENT_PORT}"

    fi
}

function return_code() {
    local code=$1
    if [[ ${code} != "0" ]]; then

        echo -e "${RED}[Error]${NC} ${2} error"
        if [[ -z ${INVENTORY} ]]; then
            [[ ${IGNORE_ERROR} == true ]]||exit 1
        fi

    fi
}

function ssh_command() {

    if [[ -n ${INVENTORY} ]]; then
        CURRENT_HOST="$1"
        CURRENT_USER="$2"
        CURRENT_PORT="$3"
        if [[ -n ${SCRIPT} ]]; then
            if ! ssh ${CURRENT_USER}${CURRENT_HOST} ${CURRENT_PORT} "bash -s" < ${SCRIPT} ; then
                return_code "1" "ssh"
            fi
        else
            if ! ssh ${CURRENT_USER}${CURRENT_HOST} ${CURRENT_PORT} "${COMMAND}" ; then
                return_code "1" "ssh"
            fi
        fi
    else
        if [[ -n ${SCRIPT} ]]; then
            if ! ssh ${SINGLE_USER}@${1} "bash -s" < ${SCRIPT} ; then
                return_code "1" "ssh"
            fi
        else
            if ! ssh ${SINGLE_USER}@${1} "${COMMAND}"; then
                return_code "1" "ssh"
            fi
        fi
    fi
}

function main() {

    if [[ -z ${SINGLE_USER} && -z ${INVENTORY} ]]; then

        echo -e "${RED}[Error]${NC} User missing"
        usage

    fi

    if [[ -z ${COMMAND} && -z ${SCRIPT} ]]; then

        echo -e "${RED}[Error]${NC} Command missing"
        usage

    fi

    if [[ -z ${HOSTS} && -z ${INVENTORY} ]]; then

        echo -e "${RED}[Error]${NC} Hosts/Inventory file missing"
        usage

    elif [[ -n ${HOSTS} && -z ${INVENTORY} ]]; then

        HOSTS_LIST=($(echo ${HOSTS} | sed -e 's/,/ /g'))
        for i in ${!HOSTS_LIST[@]}; do

            DATE="$(date)"
            output "${HOSTS_LIST[$i]}"

        done

    elif [[ -z ${HOSTS} && -n ${INVENTORY} ]]; then

        declare -a HOSTS_LIST
        declare -a USER_LIST
        declare -a PORT_LIST

        while read line; do
            local current_arg='init'
            local current_arg_position=1
            local number_host=0
            local number_user=0
            local number_port=0
            while [[ ${current_arg} != "" ]]; do
                current_arg=$(echo $line | awk -F' ' "{print \$$current_arg_position}" | awk -F'=' '{print $1}')
                case $current_arg in
                    host)
                        if [[ $number_host -le 1 ]]; then
                            HOSTS_LIST+=($(echo $line | awk -F' ' "{print \$$current_arg_position}" | awk -F'=' '{print $2}'))
                            number_host=$( expr $number_host + 1 )
                        else
                            echo -e "${RED}Error: too many hosts${NC}"
                            break
                        fi
                    ;;
                    user)
                        if [[ $number_user -le 1 ]]; then
                            USER_LIST+=($(echo $line | awk -F' ' "{print \$$current_arg_position}" | awk -F'=' '{print $2}'))
                            number_user=$( expr $number_user + 1 )
                        else
                            echo -e "${RED}Error: too many user${NC}"
                            break
                        fi
                    ;;
                    port)
                        if [[ $number_port -le 1 ]]; then
                            PORT_LIST+=($(echo $line | awk -F' ' "{print \$$current_arg_position}" | awk -F'=' '{print $2}'))
                            number_port=$( expr $number_port + 1 )
                        else
                            echo -e "${RED}Error: too many port${NC}"
                            break
                        fi
                    ;;

                esac

            current_arg_position=$( expr $current_arg_position + 1 )
            done

            if [[ $number_host == 0 ]]; then
                echo -e "${RED}Error: no host set${NC}"
                break
            fi

            if [[ $number_user == 0 ]]; then
                USER_LIST+=("$USER")
            fi

            if [[ $number_port == 0 ]]; then
                PORT_LIST+=("22")
            fi
        done < ${INVENTORY}

        for i in ${!HOSTS_LIST[@]}; do

            DATE="$(date)"
            output "${HOSTS_LIST[$i]}" "${USER_LIST[$i]}" "${PORT_LIST[$i]}"

        done

    fi
}

while [ $# -gt 0 ]; do
    case $1 in
        -h|--host)
            HOSTS="$2"
            ;;
        -u|--user)
            SINGLE_USER="$2"
            ;;
        -c|--command)
            COMMAND="$(echo $@ | sed 's/-c//g')"
            break
            ;;
        -i|--inventory)
            INVENTORY="$2"
            ;;
        -o|--output)
            OUTPUT="True"
            OUTPUT_FILE="$2"
            ;;
        -s|--script)
            SCRIPT="$2"
            break
            ;;

        # special argument
        --ignore_error)
            IGNORE_ERROR=true
            ;;
        --help)
            usage
            ;;
    esac
    shift
done

main
