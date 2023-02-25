#!/usr/bin/env bash

#set -e

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
    if [[ ${OUTPUT} == "True" ]]; then

        echo -e "[HOST] : ${CURRENT_HOST} --- ${DATE}" >> ${OUTPUT_FILE}
        ssh_command "${CURRENT_HOST}" >> ${OUTPUT_FILE}
        echo -e "---" >> ${OUTPUT_FILE}

    else

        lines "${CURRENT_HOST}"
        ssh_command "${CURRENT_HOST}"

    fi
}

function return_code() {
    local code=$1
    if [[ ${code} != "0" ]]; then

        echo -e "${RED}[Error]${NC} ${2} error"
        exit 1

    fi
}

function ssh_command() {

    if [[ -n ${SCRIPT} ]]; then
        ssh ${USER}@${1} "bash -s" < ${SCRIPT}
        return_code "$?" "ssh"
    else
        ssh ${USER}@${1} "${COMMAND}"
        return_code "$?" "ssh"
    fi
}

function main() {

    if [[ -z ${USER} ]]; then

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

        while read line; do
            HOSTS_LIST+=($(echo $line))
        done < ${INVENTORY}

        for i in ${!HOSTS_LIST[@]}; do

            DATE="$(date)"
            output "${HOSTS_LIST[$i]}"

        done

    fi
}

while [ $# -gt 0 ]; do
    case $1 in
        -h|--host)
            HOSTS="$2"
            ;;
        -u|--user)
            USER="$2"
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
        --help)
            usage
            ;;
    esac
    shift
done

main