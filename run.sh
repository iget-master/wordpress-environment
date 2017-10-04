#!/bin/bash

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPOSE_FILE="${SCRIPT_PATH}/docker/docker-compose.yml"
PROJECT_NAME="wordpress"
DEFAULT_DOMAIN="docker.wordpress"

if grep -q Microsoft /proc/version; then
    COMPOSE_FILE="${SCRIPT_PATH}/docker/docker-compose-windows.yml"
fi

#######################
# Helper Functions
#######################

# Prefix the docker-compose command with project setup options
function docker-compose {
    if grep -q Microsoft /proc/version; then
      command docker-compose -H tcp://0.0.0.0:2375 -p ${PROJECT_NAME} -f ${COMPOSE_FILE} ${@}
    else
      command docker-compose -p ${PROJECT_NAME} -f ${COMPOSE_FILE} ${@}
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
# Command: install
# Install dependencies to www application
function command_install {
echo -e "\e[33mCloning Wordpress git repo...\e[39m"
    git -C www status &> /dev/null

    case $? in
        0)
            echo -n -e "\e[32mRepo already exists,"
            ;;
        128)
            echo -e "\e[32mCloning repo..."
            git clone git@github.com:WordPress/WordPress.git www > /dev/null
            if [ $? -eq 0 ]
                then
                   echo -n -e "\e[32mRepo cloned,"
                else
                    echo -n -e "\e[31mRepo clone failed."
                    exit 1;
            fi
            ;;
        *)
            echo "\e[31mFailed on git status..."
            exit 1;
            ;;
    esac

    echo -e " checking out latest tag..."

    pushd www &> /dev/null
    git fetch --tags > /dev/null
    latestTag=$(git tag | sort -V | tail -1)
    git checkout $latestTag > /dev/null
    echo -e "\e[32mChecked out tag $latestTag."
    popd &> /dev/null

    # If wp-config.php does not exist on www path
    if [ ! -f www/wp-config.php ]; then
        # Copy our sample wp-config.php to www path
        cp ${SCRIPT_PATH}/wp-config-sample.php ${SCRIPT_PATH}/www/wp-config.php
        echo -e "\e[32mMissing wp-config.php, using sample file."
    fi
}

function command_theme_install {
    echo -e "\e[32mCloning theme from $1...\e[39m"
    git clone $1 www/wp-content/themes/theme
    command_exec www npm --prefix /var/www/wp-content/themes/theme/ install
}

function command_theme_run {
    command_exec www npm --prefix /var/www/wp-content/themes/theme/ run ${@}
}

# Command: help
# Print a help message with usage and available commands
function command_help {
    echo -e "\e[33mUsage:
    \e[39m$(basename "$0") [command] [options]

\e[33mCommands:
    \e[32mup                  \e[39mCreate and start project containers
    \e[32mdown                \e[39mStop and remove project containers
    \e[32mexec                \e[39mRun 'docker-compose exec' as current user on given container
    \e[32minstall             \e[39mInstall latest Wordpress from git
    \e[32mtheme:install [url] \e[39mInstall wordpress theme repository
    \e[32mtheme:run           \e[39mRun theme npm commands"
}

#########################
# Execution
#########################

COMMAND=${1//:/_}
if [ -z ${COMMAND} ]; then
    echo "You must provide a command."
    echo ""
    command_help
    exit 1
fi

if [ -n "$(type -t command_${COMMAND})" ]; then
    shift
    eval "command_${COMMAND} ${@}"
    exit $?
else
    echo "No such command: ${COMMAND}"
    echo ""
    command_help
    exit 1
fi
