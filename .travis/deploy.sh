#!/bin/bash

set -Eeuo pipefail

docker_org="${1}"
tag="${2}"


for c in $(< commands.txt); do
  echo -e "#!/usr/bin/env bash\nset -Eeuo pipefail\nexec ${c} \"\$@\"" > entrypoint.sh
  image_name="${docker_org}/$c:${tag}"
  docker push ${image_name}
done