#!/bin/sh

set -e

function main() {
  echo ""

  DOCKER_REGISTRY=docker.pkg.github.com
  translateDockerTag

  echo ${GITHUB_TOKEN} | docker login -u ${GITHUB_ACTOR} --password-stdin ${DOCKER_REGISTRY}

  DOCKER_IMAGE_NAME=${DOCKER_REGISTRY}/${GITHUB_REPOSITORY}/${INPUT_NAME}:${IMAGE_TAG}

  docker build --build-arg GITHUB_TOKEN -t ${DOCKER_IMAGE_NAME} .
  docker push ${DOCKER_IMAGE_NAME}

  echo "::set-output name=tag::${IMAGE_TAG}"
  DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE_NAME})
  echo "::set-output name=digest::${DIGEST}"

  docker logout ${DOCKER_REGISTRY}
}

function translateDockerTag() {
  if isOnMaster; then
    IMAGE_TAG="latest"
  elif isOnReleaseBranch; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\/release\///g")
  elif isGitTag; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/tags\/v\([[:digit:]]*.[[:digit:]]*\).[[:digit:]]*/\1/g")
  else
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g" | sed -e "s/\//-/g")
  fi;
}

function isOnMaster() {
  [ "${GITHUB_REF}" = "refs/heads/master" ]
}

function isOnReleaseBranch() {
  [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/heads\/release\///g") != "${GITHUB_REF}" ]
}

function isGitTag() {
  [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/tags\///g") != "${GITHUB_REF}" ]
}

main
