#!/bin/bash

function _version() {
  printf '%02d' $(echo "$1" | tr . ' ' | sed -e 's/ 0*/ /g') 2>/dev/null
}

function multi_arch_docker::install_docker_buildx() {
  # Check kernel version.
  local -r kernel_version="$(uname -r)"
  if [[ "$(_version "$kernel_version")" < "$(_version '4.8')" ]]; then
    echo "Kernel $kernel_version too old - need >= 4.8."
    exit 1
  fi

  # Install up-to-date version of docker, with buildx support.
  local -r docker_apt_repo='https://download.docker.com/linux/ubuntu'
  curl -fsSL "${docker_apt_repo}/gpg" | sudo apt-key add -
  local -r os="$(lsb_release -cs)"
  sudo add-apt-repository "deb [arch=amd64] $docker_apt_repo $os stable"
  sudo apt-get update
  sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce

  # Enable docker daemon experimental support (for 'docker pull --platform').
  local -r config='/etc/docker/daemon.json'
  if [[ -e "$config" ]]; then
    sudo sed -i -e 's/{/{ "experimental": true, /' "$config"
  else
    echo '{ "experimental": true }' | sudo tee "$config"
  fi
  sudo systemctl restart docker

  # Install QEMU multi-architecture support for docker buildx.
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

  # Enable docker CLI experimental support (for 'docker buildx').
  export DOCKER_CLI_EXPERIMENTAL=enabled
  # Instantiate docker buildx builder with multi-architecture support.
  docker buildx create --name mybuilder
  docker buildx use mybuilder
  # Start up buildx and verify that all is OK.
  docker buildx inspect --bootstrap
}

# Log in to Docker Hub for deployment.
# Env:
#   DOCKER_USERNAME ... user name of Docker Hub account
#   DOCKER_PASSWORD ... password of Docker Hub account
function multi_arch_docker::login_to_docker_hub() {
  echo "$DOCKER_PASSWORD" | docker login -u="$DOCKER_USERNAME" --password-stdin
}

function multi_arch_docker::login_to_github() {
  docker logout
  echo $GITHUB_TOKEN | docker login ghcr.io -u adonisd --password-stdin
}
# Run buildx build and push.
# Env:
#   DOCKER_PLATFORMS ... space separated list of Docker platforms to build.
# Args:
#   Optional additional arguments for 'docker buildx build'.
function multi_arch_docker::buildx() {
  docker buildx build \
    --platform "${DOCKER_PLATFORMS// /,}" \
    --push \
    --progress plain \
    "$@" \
    .
}

# Build and push docker images for all tags.
# Env:
#   DOCKER_PLATFORMS ... space separated list of Docker platforms to build.
#   DOCKER_BASE ........ docker image base name to build
#   TAGS ............... space separated list of docker image tags to build.
function multi_arch_docker::build_and_push_all() {
  for tag in $TAGS; do
    multi_arch_docker::buildx -t "$DOCKER_BASE:$tag"
  done
}

function multi_arch_docker::build_and_push_github() {
  multi_arch_docker::buildx -t "$GIT_TAG"
}

# Test all pushed docker images.
# Env:
#   DOCKER_PLATFORMS ... space separated list of Docker platforms to test.
#   DOCKER_BASE ........ docker image base name to test
#   TAGS ............... space separated list of docker image tags to test.
# function multi_arch_docker::test_all() {
#   for platform in $DOCKER_PLATFORMS; do
#     for tag in $TAGS; do
#       image="${DOCKER_BASE}:${tag}"
#       msg="Testing docker image $image on platform $platform"
#       line="${msg//?/=}"
#       printf '\n%s\n%s\n%s\n' "${line}" "${msg}" "${line}"
#       docker pull -q --platform "$platform" "$image"

#       echo -n "Image architecture: "
#       docker run --rm --entrypoint /bin/sh "$image" -c 'uname -m'

#       # Run your test on the built image.
#     #   docker run --rm -v "$PWD:/mnt" -w /mnt "$image" <your-arguments-here>
#     done
#   done
# }

function multi_arch_docker::main() {
  # Set docker platforms for which to build.
  export DOCKER_PLATFORMS='linux/amd64'
  DOCKER_PLATFORMS+=' linux/arm64'
  DOCKER_PLATFORMS+=' linux/arm/v7'

  export DOCKER_BASE='adonisd/searx'

  export TAGS='latest'
  export GIT_TAG='ghcr.io/adonisd/searx:1.0-'
  GIT_TAG+="$GITHUB_RUN_NUMBER"

  multi_arch_docker::install_docker_buildx
  multi_arch_docker::login_to_docker_hub
  multi_arch_docker::build_and_push_all
  multi_arch_docker::login_to_github
  multi_arch_docker::build_and_push_github
  # set +x
  # multi_arch_docker::test_all
}

multi_arch_docker::main