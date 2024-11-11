#!/bin/bash

# set -xe

CONTAINER_NAME="golang-builder"
DOCKER_IMAGE_TAG="bookworm"
PACKAGE=$1
BINARY_NAME=$(basename "${PACKAGE%%@*}")

if [ -z "$1" ]; then
    echo "No package specified"
    exit 1
fi

INSTALL_PACKAGE=""
if [[ $PACKAGE == *"@"* ]]; then
    INSTALL_PACKAGE="$PACKAGE"
else
    INSTALL_PACKAGE="${PACKAGE}@latest"
fi

docker run --rm -d -m 512m --name ${CONTAINER_NAME} \
  --memory-swap=0 \
  --health-cmd="stat /usr/local/go/bin/go" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=3 \
  "docker.io/library/golang:${DOCKER_IMAGE_TAG}" sleep infinity

Waiting_Msg="Waiting for container to be healthy"
SECONDS_WAITED=0
TIMEOUT=30
Dots=""
while STATUS=$(docker inspect --format "{{.State.Health.Status}}" ${CONTAINER_NAME}); \
  [ "${STATUS}" != "healthy" ]; do
    if [ "${STATUS}" == "unhealthy" ]; then
      echo "Container is unhealthy"
      exit 1
    fi
    if [ "${SECONDS_WAITED}" -ge "${TIMEOUT}" ]; then
      echo "Timeout waiting for the container to become healthy"
      exit 1
    fi
    Dots="$Dots."
    echo -ne "\r${Waiting_Msg}${Dots}"
    sleep 1
    SECONDS_WAITED=$(("${SECONDS_WAITED}" + 1))
done

GO_ENV=$(docker exec ${CONTAINER_NAME} go version | awk '{print $3}' | cut -d 'o' -f 2)

docker exec "${CONTAINER_NAME}" go install "${INSTALL_PACKAGE}"

docker cp "${CONTAINER_NAME}:/go/bin/${BINARY_NAME}" "${GOPATH}/bin/$BINARY_NAME"

docker stop "${CONTAINER_NAME}" > /dev/null

echo "${INSTALL_PACKAGE} is installed, builder version: ${GO_ENV}"
