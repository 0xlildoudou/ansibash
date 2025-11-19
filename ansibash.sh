#!/usr/bin/env bash

#set -x

source ./src/utils.sh
source ./src/ssh.sh

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
    echo -e "-f, --file     Upload file to remote host"
    echo -e "--help         Print this help"
    echo -e "-------------------------------------------------"
    echo -e "SPECIALS OPTIONS:"
    echo -e "--ignore_error     Continues the script even if an error occurs"

    exit 0
}

function output() {

    CURRENT_HOST="$1"
    CURRENT_USER="$2@"
    CURRENT_PORT="-p $3"
    SCP_PORT="-P $3"
    if [[ ${OUTPUT} == "True" ]]; then

        echo -e "[HOST] : ${CURRENT_HOST} --- ${DATE}" >> "${OUTPUT_FILE}"
        ssh_command "${CURRENT_HOST}" "${CURRENT_USER}" "${CURRENT_PORT}" >> "${OUTPUT_FILE}"
        echo -e "---" >> "${OUTPUT_FILE}"

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

function main() {

    if [[ -z ${SINGLE_USER} && -z ${INVENTORY} ]]; then

        echo -e "${RED}[Error]${NC} User missing"
        usage

    fi

    if [[ -z ${COMMAND} && -z ${SCRIPT} && -z ${FILE_SEND} ]]; then

        echo -e "${RED}[Error]${NC} Command missing"
        usage

    fi

    if [[ -z ${HOSTS} && -z ${INVENTORY} ]]; then

        echo -e "${RED}[Error]${NC} Hosts/Inventory file missing"
        usage

    elif [[ -n ${HOSTS} && -z ${INVENTORY} ]]; then

        HOSTS_LIST=($(echo ${HOSTS} | sed -e 's/,/ /g'))
        for i in "${!HOSTS_LIST[@]}"; do

            DATE="$(date)"
            output "${HOSTS_LIST[$i]}"

        done

    elif [[ -z ${HOSTS} && -n ${INVENTORY} ]]; then

        declare -a HOSTS_LIST
        declare -a USER_LIST
        declare -a PORT_LIST

        while read -r line; do
            local current_arg='init'
            local current_arg_position=1
            local number_host=0
            local number_user=0
            local number_port=0
            while [[ ${current_arg} != "" ]]; do
                current_arg=$(echo "${line}" | awk -F' ' "{print \$$current_arg_position}" | awk -F'=' '{print $1}')
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
        done < "${INVENTORY}"

        for i in "${!HOSTS_LIST[@]}"; do

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
            COMMAND="$(echo "$@" | sed 's/-c//g')"
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

        -f|--file)
            FILE_SEND=true
            FILE_SOURCE=$(echo "$2" | awk -F ':' '{print $1}')
            FILE_DESTINATION=$(echo "$2" | awk -F ':' '{print $2}')
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
