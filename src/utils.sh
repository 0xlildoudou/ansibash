# COLOR
RED="\033[1;31m"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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