#!/bin/bash

set -Eeuo pipefail

docker_org="${1}"
tag="${2}"

OLDIFS=$IFS
IFS=$'\n'
for c in $(< commands.txt); do
  eval $c
  echo -e "#!/usr/bin/env bash\nset -Eeuo pipefail\nexec ${IMAGE_NAME} \"\$@\"" > ${IMAGE_NAME}.entrypoint.sh
  if [ "x${tag}" = "xlatest" ]; then
    image_tag=${tag}
  else
    image_tag=${IMAGE_TAG}-${tag}
  fi
  echo Building ${IMAGE_NAME}:${image_tag}
  docker build --build-arg REQUIRED_PACKAGES --build-arg IMAGE_NAME -t ${docker_org}/${IMAGE_NAME}:${image_tag} .
done
IFS=$OLDIFS