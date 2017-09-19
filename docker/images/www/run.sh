#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_DIR="$DIR/../src"
PROJECT_HOME="/var/www/viaggio"
HOST="docker.viaggio"
FORCE_NEW=false
FIRST_RUN=false

while getopts ":n" opt; do
  case $opt in
    n)
      FORCE_NEW=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Force running script as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if image is already built
if [[ "$(docker images -q docker-viaggio:latest 2> /dev/null)" == "" ]]; then
    echo "Missing image \"docker-viaggio:latest\". Starting build"
    bash $DIR/build.sh
else
    echo "Using existent image \"docker-viaggio:latest\"."
fi

# Check for existing container for current image to reuse,
#  unless the FORCE_NEW option is true
if [ ${FORCE_NEW} == false ]; then
    EXISTING_CONTAINER="$(docker ps -aqf "ancestor=docker-viaggio" | sed -n 1p)"
else
    echo "Forcing creation of new container due option \"-n\"..."
fi


if [[ ${EXISTING_CONTAINER} == "" ]]; then
    # Try to start a new container from image
    echo "Starting new container as daemon..."
    CONTAINER_ID="$(docker run -h $HOST -v $SRC_DIR:/var/www/viaggio -d docker-viaggio | cut -c1-12)"
    FIRST_RUN=true
else
    echo "Starting existing container $EXISTING_CONTAINER"
    CONTAINER_ID="$(docker start $EXISTING_CONTAINER | cut -c1-12)"
fi

if [ $? == 0 ]
then
    echo "Container started successfully. (ID: $CONTAINER_ID)"
else
    echo "Failed starting container (Exit code: $?)"
fi

# Wait processes startup
echo -ne "Waiting processes startup"
NOT_STARTED_PROCESSES=1
while [ ${NOT_STARTED_PROCESSES} != "0" ]
do
NOT_STARTED_PROCESSES="$(docker exec $CONTAINER_ID supervisorctl status | grep -v "RUNNING" | wc -l)"
sleep 0.1
echo -ne "."
done
echo " Done!"

# Collect container IP
CONTAINER_IP="$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $CONTAINER_ID)"
echo "Container network address: $CONTAINER_IP"

sudo chmod -R 0777 $SRC_DIR
sudo cp -rf ${DIR}/.env ${SRC_DIR}/.env

if [ $FIRST_RUN == true ]; then
docker exec $CONTAINER_ID mysql -uroot -proot -e "CREATE SCHEMA sandbox_viaggio;"
fi

echo "Installing composer packages"
docker exec $CONTAINER_ID composer install -d $PROJECT_HOME

echo "Installing npm packages"
docker exec $CONTAINER_ID npm --prefix $PROJECT_HOME install -d $PROJECT_HOME

echo "Migrating database"
docker exec $CONTAINER_ID php $PROJECT_HOME/artisan migrate

# Remove any existing entry for HOST on /etc/hosts
# and point HOST to our container IP
sed -i '/\s'"$HOST"'$/d' /etc/hosts
sed -i -e "\$a$CONTAINER_IP $HOST" /etc/hosts
echo "Host \"$HOST\" pointed to container."

docker exec -ti $CONTAINER_ID /bin/bash