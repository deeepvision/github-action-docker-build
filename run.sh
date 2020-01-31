#!/bin/sh

set -e

function main() {
  echo ""

  DOCKER_REGISTRY=docker.pkg.github.com
  translateDockerTag

  echo ${GITHUB_TOKEN} | docker login -u ${GITHUB_ACTOR} --password-stdin ${DOCKER_REGISTRY}

  DOCKER_IMAGE_NAME=${DOCKER_REGISTRY}/${GITHUB_REPOSITORY}/${INPUT_NAME}:${IMAGE_TAG}

  docker build -t ${DOCKER_IMAGE_NAME} .
  docker push ${DOCKER_IMAGE_NAME}

  echo "::set-output name=tag::${IMAGE_TAG}"
  DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' ${DOCKER_IMAGE_NAME})
  echo "::set-output name=digest::${DIGEST}"

  docker logout ${DOCKER_REGISTRY}
}

function translateDockerTag() {
  local BRANCH=$(echo ${GITHUB_REF} | sed -e "s/refs\/heads\///g" | sed -e "s/\//-/g")
  if isOnMaster; then
    IMAGE_TAG="latest"
  elif isOnReleaseBranch; then
    IMAGE_TAG=$(echo ${BRANCH} | sed -e "s/refs\/heads\/release\///g")
  elif isGitTag; then
    IMAGE_TAG=$(echo ${GITHUB_REF} | sed -e "s/refs\/tags\/v\([[:digit:]]*.[[:digit:]]*\).[[:digit:]]*/\1/g")
  else
    IMAGE_TAG="${BRANCH}"
  fi;
}

function isOnMaster() {
  [ "${BRANCH}" = "master" ]
}

function isOnReleaseBranch() {
  [ $(echo "${BRANCH}" | sed -e "s/refs\/heads\/release\///g") != "${BRANCH}" ]
}

function isGitTag() {
  [ $(echo "${GITHUB_REF}" | sed -e "s/refs\/tags\///g") != "${GITHUB_REF}" ]
}

main
