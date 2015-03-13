#!/bin/bash

versionString="${1}.version"
version="${2}"

# it seems it's faster then a for-loop on cygwin ???
find . -name '*pom.xml' | grep -v 'target\|bin' | xargs sed -i "s+<${versionString}>.*</${versionString}>+<${versionString}>${version}</${versionString}>+"

