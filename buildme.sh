#!/bin/bash
release=$(grep "LABEL RELEASE" Dockerfile|awk '{print $2}'|cut -d\" -f2)
version=$(grep "LABEL VERSION" Dockerfile|awk '{print $2}'|cut -d\" -f2)
echo Version: "$version" found
echo Release: "$release" found
if [ ! -z "$version" ] && [ ! -z "$release" ]; then
  docker build --no-cache -t "$release":"$version" .
  build_status=$?
  docker container prune --force
  # let's tag latest
  docker tag "$release":"$version" "$release":latest
else
  echo "No $version found, exiting"
  exit 1
fi
# coverage
if [ "$build_status" == 0 ]; then
  echo "Docker build succeed"
  rm -rf dive.log||true
  trivy --output coverage-"$version"_trivy.txt "$release":"$version"
  dive --ci "$release":"$version" > coverage-"$version"_dive.txt
  dockle -f json -o coverage-"$version"_dockle.txt "$release":"$version"
else
 echo "Docker build failed, exiting now"
fi
