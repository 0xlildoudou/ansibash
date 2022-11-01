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
    echo -e "-c, --command  Command to broadcast on hosts (always put at the end of the command)"
    echo -e "--help         Print this help"

    exit 1
}

function ssh_command() {
    CURRENT_HOST="$*"
    echo -e "${YELLOW}[HOST] : ${CURRENT_HOST}${NC} --- ${GREEN}${DATE}${NC}"
    ssh ${USER}@${CURRENT_HOST} "${COMMAND}"
    if [[ $? != "0" ]]; then
        echo -e "${RED}[Error]${NC} ssh command error"
        exit 1
    fi
}

function main() {
    clear


    if [[ -z ${USER} ]]; then
        echo -e "${RED}[Error]${NC} User missing"
        usage
    fi

    if [[ -z ${COMMAND} ]]; then
        echo -e "${RED}[Error]${NC} Command missing"
        usage
    fi

    if [[ -z ${HOSTS} && -z ${INVENTORY} ]]; then
        echo -e "${RED}[Error]${NC} Hosts/Inventory file missing"
        usage
    elif [[ -n ${HOSTS} && -z ${INVENTORY} ]]; then
        HOSTS_NUMBER="$(echo ${HOSTS} | sed -e 's/,/\n/g' | wc -l)"
        for i in $(seq 1 ${HOSTS_NUMBER}); do
            CURRENT_HOST="$(echo ${HOSTS} | sed -e 's/,/\n/g' | sed -n ${i}p)"
            DATE="$(date)"
            ssh_command "${CURRENT_HOST}"
        done
    elif [[ -z ${HOSTS} && -n ${INVENTORY} ]]; then
        HOSTS_NUMBER="$(wc -l ${INVENTORY} | awk -F' ' '{print $1}' | sed '/^\s*\#/!p')"
        for i in $(seq 1 ${HOSTS_NUMBER}); do
            CURRENT_HOST="$(sed -n ${i}p ${INVENTORY})"
            DATE="$(date)"
            ssh_command "${CURRENT_HOST}"
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
        --help)
            usage
            ;;
    esac
    shift
done

main