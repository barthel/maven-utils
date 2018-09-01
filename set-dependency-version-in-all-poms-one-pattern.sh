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
# Replaces version in Maven POM-file property entries following the only one pattern:
#   <[artifactId].version>[version number]</[artifactId].version>
#
# Locates transitively all POM-files (pom.xml) in the current directory.
# In each found POM-file will the <properties> chield element, where the element
# matches the only one pattern:
#   <[artifactId].version>[old version]</[artifactId].version>
# , modify to replace the [old_version] with the given new version argument.
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
#  > set-dependencies-in-all-poms-one-pattern.sh "my.artifactId" "47.11.0-SNAPSHOT"
#  > set-dependencies-in-all-poms-one-pattern.sh "my.artifactId" "47.11.0"
#

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_set_dependencies_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_set_dependencies_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed'

# <[artifactId]\.version>
property_name="${1}\\.version"

_find_filter="pom.xml"
_grep_filter="<${property_name}>"
_sed_filter="s|<\\(${property_name}\\)>\\(.*\\)<|<\\1>${VERSION}<|"

# 1. '_build_find_cmd ...' - build the find command for relative path only of files
#                            with name pattern
_cmd="$(_build_find_cmd "${_find_filter}") "
_cmd+=" | xargs "
# 2. '_build_grep_cmd ...' - select file names containing the version string
_cmd+="$(_build_grep_cmd "${_grep_filter}") "
_cmd+=" | xargs "
# 3. '_build_sed_cmd ...'  - inline replace of version
_cmd+="$(_build_sed_cmd "${_sed_filter}") "

[ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_cmd}"
# 4. '_exec_cmd ...'       - execute the assembled command line
_exec_cmd "${_cmd}"
