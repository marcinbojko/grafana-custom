#!/bin/bash
release=$(grep -i "LABEL RELEASE" Dockerfile|awk '{print $2}'|cut -d\" -f2)
version=$(grep -i "LABEL VERSION" Dockerfile|awk '{print $2}'|cut -d\" -f2)
maintainer="marcinbojko"
echo Version: "$version" found
echo Release: "$release" found
if [ -n "$version" ] && [  -n "$release" ]; then
  docker login
  docker tag "$release":"$version" "$maintainer/$release:$version"
  docker tag "$release":"$version" "$maintainer/$release":latest
  docker push "$maintainer/$release:$version"
  docker push "$maintainer/$release":latest
else
 echo Version tag is empty
 exit 1
fi
