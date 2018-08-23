#!/bin/bash
#
# Replace version in POM file property entries following th pattern:
#   <[artifactId].version>[version number]</[artifactId].version>
#

set -m
# set -x

$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )/set-dependency-version-in-all-poms.sh ${@}

# escape dot but not in {1} to use rexexp pattern into it
versionString="${1}\.version"
version="${2//\./\\.}"

# find and replace version in MANIFEST.MF of OSGi bundles
find . -type f \( -name 'MANIFEST.MF' -and -not -ipath '*/.git/*' -and -not -ipath '*/target/*' -and -not -ipath '*/bin/*' \) | xargs grep -l "${1};bundle-version=" | xargs sed -i'' "s|\(${1};bundle-version=\"\)\(.*\)\(\".*\)|\1\[${version},${version}\]\3|"

# p2-maven-plugin
find . -type f \( -name '*pom.xml' -and -not -ipath '*/.git/*' -and -not -ipath '*/target/*' -and -not -ipath '*/bin/*' \) | xargs grep -l "<artifactId>p2-maven-plugin</artifactId>" | xargs sed -i'' "s|<id>\(.*:${1}\):\(.*[[:digit:]]\)<|<id>\1:${version}<|"
