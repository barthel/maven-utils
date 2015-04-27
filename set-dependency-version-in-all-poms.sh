#!/bin/bash
#
# Replace version in POM file property entries following th pattern:
#   <[artifactId].version>[version number]</[artifactId].version>
#

set -m
# set -x

# escape dot but not in {1} to use rexexp pattern into it
versionString="${1}\.version"
version="${2//\./\\.}"

# it seems it's faster then a for-loop on cygwin ???
# @see: http://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
# meaning of parameters in ordered way
# find relative path only of files with name pattern and the path does not contains one of the path pattern
# select file names containing the version string
# inline replace of version
find . -type f \( -name '*pom.xml' -and -not -ipath '*/.git/*' -and -not -ipath '*/target/*' -and -not -ipath '*/bin/*' \) | xargs grep -l "<${versionString}>" | xargs sed -i'' "s|<\(${versionString}\)>\(.*\)<|<\1>${version}<|"

