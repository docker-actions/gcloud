#!/bin/bash

set -Eeuo pipefail

docker_org="${1}"
tag="${2}"

OLDIFS=$IFS
IFS=$'\n'
for c in $(< commands.txt); do
  eval $c
  if [ "x${tag}" = "xlatest" ]; then
    image_tag=${tag}
  else
    image_tag=${IMAGE_TAG}-${tag}
  fi
  echo Building ${IMAGE_NAME}:${image_tag}
  docker push ${docker_org}/${IMAGE_NAME}:${image_tag}
done
IFS=$OLDIFS