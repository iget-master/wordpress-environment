#!/bin/bash

#########################
# Bash colors variables
#########################

RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
LIGHTGRAY='\033[00;37m'

LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'

#########################
# Check current OS
#########################

case "$(uname)" in
    Darwin)
        OS="OSX"
        ;;
    *)
        if grep -q Microsoft /proc/version; then
            OS="WSL"
        else
            OS="LINUX"
        fi
        ;;
esac

#########################
# Script variables
#########################

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE="${SCRIPT_PATH}/docker-compose.yml"
PROJECT_NAME="$( cat ${SCRIPT_PATH}/.projectname)"
DEFAULT_DOMAIN="docker.wordpress"

if [ "$OS" == 'WSL' ]; then
    COMPOSE_FILE="${SCRIPT_PATH}/docker-compose-windows.yml"
fi

#######################
# Helper Functions
#######################

# Prefix the docker-compose command with project setup options
function docker-compose {
    if [ "$OS" == 'WSL' ]; then
        command docker-compose -H tcp://0.0.0.0:2375 -p ${PROJECT_NAME} -f "${COMPOSE_FILE}" ${@}
    else
        command docker-compose -p ${PROJECT_NAME} -f "${COMPOSE_FILE}" ${@}
    fi
}

#######################
# Commands declaration
#######################

# Command: exec
# Run docker-compose exec as current user on given container
function command_exec {
    docker-compose exec --user ${UID} ${@}
}

# Command: bash
# Open bash as current user
function command_bash {
    docker-compose exec --user ${UID} www /bin/bash
}

# Command: bash:root
# Open bash as root
function command_bash_root {
    docker-compose exec www /bin/bash
}

# Command: up
# Create and start project containers
function command_up {
    docker-compose up -d ${@}
    docker-compose exec www useradd -ms /bin/bash -u $(id -u) $(whoami)
}

# Command: down
# Stop and remove project containers
function command_down {
    docker-compose down ${@}
}

# Command: pull
# Pull latest container images
function command_pull {
    docker-compose pull ${@}
}

# Command: set:project
# Set the project name
function command_set_project {
    echo ${@} > ${SCRIPT_PATH}/.projectname
}

# Command: bind
# Bind hostname to container IP
function command_bind {
    if [ -n $1 ]; then
        ARG_DOMAIN=$1
    else
        ARG_DOMAIN=${DEFAULT_DOMAIN}
    fi

    echo "The sudo password may be asked to allow writing to hosts file."
    sudo echo -n

    if [ $? != 0 ]; then
        echo "You must provide a valid sudo password to run this command."
        exit 1
    fi

    # Remove any existing entry for HOST on /etc/hosts
    # and point HOST to our www service IP
    sudo sed -i'' -e '/\s'"${ARG_DOMAIN}"'$/d' /etc/hosts
    echo "127.0.0.1 ${ARG_DOMAIN}" | sudo tee -a /etc/hosts
    echo "Hostname \"${ARG_DOMAIN}\" bound to container."

    if [ "$(uname)" == "Darwin" ]; then
        echo "OS X detected. Flushing DNS Cache and restarting mDNSResponder"
        dscacheutil -flushcache; sudo killall -HUP mDNSResponder
    fi
}

# Command: install
# Install dependencies to www application
function command_install {
    echo -e "${YELLOW}Cloning Wordpress git repo...${RESTORE}"

    command_exec -T www git -C /var/www status &> /dev/null
    case $? in
        0)
            echo -n -e "${GREEN}Repo already exists,"
            ;;
        128)
            echo -e "${GREEN}Cloning repo..."
            git clone git@github.com:WordPress/WordPress.git www > /dev/null
            if [ $? -eq 0 ]
                then
                   echo -n -e "${GREEN}Repo cloned,"
                else
                    echo -n -e "${RED}Repo clone failed."
                    exit 1;
            fi
            ;;
        *)
            echo "${RED}Failed on git status..."
            exit 1;
            ;;
    esac

    echo -e " checking out latest tag..."

    pushd www &> /dev/null
    git fetch --tags > /dev/null
    latestTag=$(git tag | sort -V | tail -1)
    git checkout $latestTag > /dev/null
    echo -e "${GREEN}Checked out tag $latestTag."
    popd &> /dev/null

    # If wp-config.php does not exist on www path
    if [ ! -f www/wp-config.php ]; then
        # Copy our sample wp-config.php to www path
        cp "${SCRIPT_PATH}/wp-config-sample.php" "${SCRIPT_PATH}/www/wp-config.php"
        echo -e "${GREEN}Missing wp-config.php, using sample file."
    fi
}

# Command: install:theme
# Install a theme from git and npm dependencies
function command_install_theme {
    NAME="theme"

    echo -e "${GREEN}Cloning theme from \"$1\" as \"$2\"...${RESTORE}"
    git clone $1 "www/wp-content/themes/${NAME}"
    command_exec www npm --prefix /var/www/wp-content/themes/theme/ install
}

# Command: theme:npm
# Alias to `npm` inside www container on theme directory
function command_theme_npm {
    command_exec www npm --prefix /var/www/wp-content/themes/theme/ ${@}
}

# Command: theme:run
# Alias to `npm run` inside www container
function command_theme_run {
    command_theme_npm run ${@}
}

# Command: help
# Print a help message with usage and available commands
function command_help {
    echo -e "${YELLOW}Usage:
    ${RESTORE}$(basename "$0") [command] [options]

${YELLOW}Commands:
    ${GREEN}up                         ${RESTORE}Create and start project containers
    ${GREEN}down                       ${RESTORE}Stop and remove project containers
    ${GREEN}set:project                ${RESTORE}Set project name on '.projectname'
    ${GREEN}pull                       ${RESTORE}Pull latest container image versions
    ${GREEN}bash                       ${RESTORE}SSH into the www container
    ${GREEN}bind [-d=domain]           ${RESTORE}Bind domain to www container
    ${GREEN}exec                       ${RESTORE}Run 'docker-compose exec' as current user on given container
    ${GREEN}install                    ${RESTORE}Install latest Wordpress from git
    ${GREEN}install:theme [url] [name] ${RESTORE}Install wordpress theme repository
    ${GREEN}theme:npm [command]        ${RESTORE}Run npm inside theme directory
    ${GREEN}theme:run [command]        ${RESTORE}Alias to 'theme:npm run'"
}

#########################
# Execution
#########################

# Replace ':' by '_' and check if command isn't empty if
# command was not provided, show am error and help message.
COMMAND=${1//:/_}
if [ -z ${COMMAND} ]; then
    echo -e "${RED}You must provide a command.\n"
    command_help
    exit 1
fi

# Check if the command exists, if doesn't
# show an error and help message.
if [ -n "$(type -t command_${COMMAND})" ]; then
    shift
    eval "command_${COMMAND} ${@}"
    exit $?
else
    echo -e "${RED}No such command: ${COMMAND}"
    echo ""
    command_help
    exit 1
fi
