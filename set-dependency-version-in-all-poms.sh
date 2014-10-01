#!/bin/bash

for file in $(find . -name \*pom.xml | grep -v target)
do
  versionString="${1}.version"
  version="${2}"
  sed -i "s+<${versionString}>.*</${versionString}>+<${versionString}>${version}</${versionString}>+" $file
done
