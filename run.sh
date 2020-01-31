#!/bin/sh

set -e

function main() {
  echo ""

  DOCKER_REGISTRY=docker.pkg.github.com
  translateDockerTag

  echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${DOCKER_REGISTRY}

  DOCKER_IMAGE_NAME=${DOCKER_REGISTRY}/${INPUT_REPO}/${INPUT_NAME}:${IMAGE_TAG}

  docker build -t ${DOCKER_IMAGE_NAME} .
  docker push ${DOCKER_IMAGE_NAME}

  echo "::set-output name=tag::${IMAGE_TAG}"
  DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE_NAME})
  echo "::set-output name=digest::${DIGEST}"

  docker logout
}

function translateDockerTag() {
  local BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g" | sed -e "s/\//-/g")
  if isOnMaster; then
    IMAGE_TAG="latest"
  elif isGitTag; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/tags\///g")
  else
    IMAGE_TAG="${BRANCH}"
  fi;
}

function isOnMaster() {
  [ "${BRANCH}" = "master" ]
}

function isGitTag() {
  [ $(echo "${GITHUB_REF}" | sed; -e "s/refs\/tags\///g") != "${GITHUB_REF}" ]
}

main