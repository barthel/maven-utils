#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (c) barthel <barthel@users.noreply.github.com> https://github.com/barthel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Replaces version in Maven POM-file property entries following the pattern:
#   <[artifactId].version>[version number]</[artifactId].version>
#
# Locates transitivly all POM-files (pom.xml) in the current directory.
# In each found POM-file will the <properties> chield element, where the element
# matches the pattern:
#   <[artifactId].version>[old version]</[artifactId].version>
# , be modified to replace the [old_version] with the given new version argument.
#
# POM-file example:
# -----------------
#  1. POM-file before modification:
#    [...]
#    <properties>
#      <my.artifactId.version>0.8.15<my.artifactId.version>
#    </properties>
#    [...]
#
#  2. POM-file after executing this script with parameter "my.artifactId" "47.11.0"
#    [...]
#    <properties>
#      <my.artifactId.version>47.11.0<my.artifactId.version>
#    </properties>
#    [...]
#
# Usage:
# ------
#  > set-dependencies-in-all-poms.sh "my.artifactId" "0.8.15-SNAPSHOT"
#

# activate debug output
#set -x

# Includes shared functions, checks and provides the command line arguments.
script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
# shellcheck source=/dev/null #@see: https://github.com/koalaman/shellcheck/wiki/SC1090
. "${script_directory}/_set_dependencies_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed'
[ 0 != $? ] && exit $? || true

# <[artifactId].version>
property_name="${1}\.version"

# meaning of parameters in ordered way:
# 1. '_build_find_cmd ...' - find relative path only of files with name pattern and
#                            and the path does not contains one of the path pattern
# 2. 'xargs grep -l ...'   - select file names containing the version string
# 3. 'xargs sed ...'       - inline replace of version
# @see: http://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
cmd="_build_find_cmd \"*pom.xml\" | xargs grep -l \"<${property_name}>\"| xargs sed -e \"s|<\(${property_name}\)>\(.*\)<|<\1>${version}<|\" --in-place=''"
[ 0 -lt ${verbose} ] && echo "Execute: ${cmd}"
eval ${cmd}
