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
# Replaces version in Maven POM-file wich use the 'p2-maven-plugin', where the
# dependency definition following the pattern:
#   <id>group.id:[artifactId]:[version number]</id>
#
# Locates transitivly all POM-files (pom.xml) in the current directory.
# Checks in each found POM-file the presens of the 'p2-maven-plugin' plugin configuration.
# In each POM-file will the <id>-element, where the element
# matches the pattern:
#   <id>group.id:[artifactId]:[old_version]</id>
# , be modified to replace the [old_version] with the given new version argument.
#
# POM-file example:
# -----------------
#  1. POM-file before modification:
#    [...]
#    <plugin>
#      <groupId>org.reficio</groupId>
#      <artifactId>p2-maven-plugin</artifactId>
#    [...]
#            <configuration>
#    [...]
#              <artifacts>
#                <artifact>
#                  <id>group.id:artifactId:0.8.15</id>
#                  <transitive>false</transitive>
#                </artifact>
#    [...]
#
#  2. POM-file after executing this script with parameter "my.artifactId" "47.11.0"
#    [...]
#    <plugin>
#      <groupId>org.reficio</groupId>
#      <artifactId>p2-maven-plugin</artifactId>
#    [...]
#            <configuration>
#    [...]
#              <artifacts>
#                <artifact>
#                  <id>group.id:artifactId:47.11.0</id>
#                  <transitive>false</transitive>
#                </artifact>
#    [...]
#
# Usage:
# ------
#  > set-dependencies-in-all-p2-maven-plugin-poms.sh "my.artifactId" "0.8.15-SNAPSHOT"
#

# activate debug output
#set -x

# Includes shared functions, checks and provides the command line arguments.
script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. ${script_directory}/_set_dependencies_functions.sh

# 'sed' regexp for version ends with "-SNAPSHOT"
sed_snapshot_number_filter='-SNAPSHOT'
# 'sed' regexp for version ends with a digit
sed_not_snapshot_number_filter='[[:digit:]]'

# check the presens of required tools/commands/executables
_check_required_helper 'find' 'dirname' 'grep' 'xargs' 'sed'
[ 0 != $? ] && exit $? || true

# Builds the inplace 'sed' replace regexp to replace the version.
#
# Usage:
# ------
# [...]
#   _build_sed_regexp ${original_artifact_id} ${sed_number_filter} ${version}
# [...]
#
# @param #1: artifact id or regexp pattern for use in 'sed' regexp pattern
# @param #2: 'sed' number filter pattern for use in 'sed' regexp pattern
# @param #3: version or regexp pattern for use in 'sed' regexp pattern
# @returns: the full assembled inplace 'sed' replace regexp
#
_build_sed_regexp() {
  local _artifact_id="${1}"
  local _sed_number_filter="${2}"
  local _version="${3}"

  echo "s|<id>\(.*:${_artifact_id}\):\(.*${_sed_number_filter}\)<|<id>\1:${_version}<|"
}

# Generates the next patch version and increments the last digest after the last dot
# in the given stripped (without '-SNAPSHOT') version.
#
# Example:
# --------
# "47.11.0" -> "47.11.1", "0.8.15" -> "8.8.16"
#
# Usage:
# ------
# [...]
#   _generate_next_patch_version ${version}
# [...]
#
# @param #1: stripped (without '-SNAPSHOT') version
# @returns: the next patch incremented version
#
_generate_next_patch_version() {
  local _next_patch_version=${1##*\.}
  ((_next_patch_version++))
  echo "${1%\.*}.${_next_patch_version}"
}

_build_cmd() {
  local _artifact_id="${1}"
  local _filter="${2}"
  local _version="${3}"
  local _sed_filter=$(_build_sed_regexp ${_artifact_id} ${_filter} ${_version})

  # meaning of parameters in ordered way:
  # 1. '_build_find_cmd ...' - find relative path only of files with name pattern and
  #                            and the path does not contains one of the path pattern
  # 2. 'xargs grep -l ...'   - select file names containing the'p2-mven-plugin' pattern
  # 3. 'xargs sed ...'       - inline replace of version
  # @see: http://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
  eval "_build_find_cmd \"*pom.xml\" | xargs grep -l \"<artifactId>p2-maven-plugin</artifactId>\" | xargs sed -i'' \"${_sed_filter}\""
}

# Replace version in dependency definition of p2-maven-plugin
# <id>[groupId]:[artifactId]:[version]</id>

# is NOT SNAPSHOT - change the released version, increment the patch number and change the SNAPSHOT version
_version="${version}"
if ! ${is_snapshot_version}
  then
    cmd="_build_cmd ${original_artifact_id} ${sed_not_snapshot_number_filter} ${_version}"
    [ 0 -lt ${verbose} ] && echo "Execute: ${cmd}"
    eval ${cmd}
    # new SNAPSHOT version
    _version=$(_generate_next_patch_version ${stripped_version})"-SNAPSHOT"
fi
# is SNAPSHOT - only change the SNAPSHOT version
cmd="_build_cmd ${original_artifact_id} ${sed_snapshot_number_filter} ${_version}"
[ 0 -lt ${verbose} ] && echo "Execute: ${cmd}"
eval ${cmd}
