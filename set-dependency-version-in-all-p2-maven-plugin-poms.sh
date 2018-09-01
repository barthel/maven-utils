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
# Locates transitively all POM-files (pom.xml) in the current directory.
# Checks in each found POM-file the present of the 'p2-maven-plugin' plugin configuration.
#
# In each POM-file will the <id>-element, where the element
# matches the pattern:
#   <id>group.id:[artifactId]:[old_version]</id>
# , modify to replace the [old_version] with the given new version argument.
#
# Non SNAPSHOT version
# --------------------
# The non-SNAPSHOT version will be replaced.
#
# If there is a SNAPSHOT version available in this script the given next version
# will be set or the next patch version will be generated and used.
#
# SNAPSHOT version
# --------------------
# Only the SNAPSHOT version will be replaced.
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
#                <artifact>
#                  <id>group.id:artifactId:0.8.16-SNAPSHOT</id>
#                  <transitive>false</transitive>
#                </artifact>
#    [...]
#
#  2a. POM-file after executing this script with parameter "artifactId" "47.11.0-SNAPSHOT"
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
#                <artifact>
#                  <id>group.id:artifactId:47.11.0-SNAPSHOT</id>
#                  <transitive>false</transitive>
#                </artifact>
#    [...]
#
#  2b. POM-file after executing this script with parameter "artifactId" "47.11.0"
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
#                <artifact>
#                  <id>group.id:artifactId:47.11.1-SNAPSHOT</id>
#                  <transitive>false</transitive>
#                </artifact>
#    [...]
#
#  2c. POM-file after executing this script with parameter "artifactId" "47.11.0" "48.0.0-SNAPSHOT"
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
#                <artifact>
#                  <id>group.id:artifactId:48.0.0-SNAPSHOT</id>
#                  <transitive>false</transitive>
#                </artifact>
#    [...]
#
# Usage:
# ------
#  > set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0-SNAPSHOT"
#  > set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0"
#  > set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0" "48.0.0-SNAPSHOT"
#

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_set_dependencies_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_set_dependencies_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed'


# Builds the inplace 'sed' replace regexp to replace the version in plugin configuration:
#  <id>group.id:artifactId:47.11.0</id>
#
# Usage:
# ------
# [...]
#   _build_id_sed_regexp ${original_artifact_id} ${sed_number_filter} ${version}
# [...]
#
# @param #1: artifact id or regexp pattern for use in 'sed' regexp pattern
# @param #2: 'sed' number filter pattern for use in 'sed' regexp pattern
# @param #3: version or regexp pattern for use in 'sed' regexp pattern
# @returns: the full assembled inplace 'sed' replace regexp
#
_build_id_sed_regexp() {
  local _id_sed_artifact_id="${1}"
  local _id_sed_version_filter="${2}"
  local _id_sed_version="${3}"

  echo "s|<id>\\(.*:${_id_sed_artifact_id}\\):\\(.*${_id_sed_version_filter}\\)<|<id>\\1:${_id_sed_version}<|"
}

# Replace version in dependency definition of p2-maven-plugin
# <id>[groupId]:[artifactId]:[version]</id>

# 'sed' regexp for version ends with "-SNAPSHOT"
sed_snapshot_number_filter='-SNAPSHOT'
# 'sed' regexp for version ends with a digit
sed_not_snapshot_number_filter='[[:digit:]]'

_version="${VERSION}"

_find_filter="pom.xml"
_grep_filter="<artifactId>p2-maven-plugin</artifactId>"

# 1. '_build_find_cmd ...' - build the find command for relative path only of files
#                            with name pattern
_cmd="$(_build_find_cmd "${_find_filter}") "
_cmd+=" | xargs "
# 2. '_build_grep_cmd ...' - select file names containing the version string
_cmd+="$(_build_grep_cmd "${_grep_filter}") "
_cmd+=" | xargs "

# is NOT SNAPSHOT - change the released version, increment the patch number and change the SNAPSHOT version
if ! ${IS_SNAPSHOT_VERSION}
  then
    _release_cmd="${_cmd}"
    # is non SNAPSHOT - only change the released version
    _sed_filter="$(_build_id_sed_regexp "${ORIGINAL_ARTIFACT_ID}" "${sed_not_snapshot_number_filter}" "${_version}")"
    # 3. '_build_sed_cmd ...'  - inline replace of version
    _release_cmd+="$(_build_sed_cmd "${_sed_filter}") "
    [ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_release_cmd}"
    # 4. '_exec_cmd ...'       - execute the assembled command line for the released version
    _exec_cmd "${_release_cmd}"
    # new SNAPSHOT version
    if [ ! -z "${ORIGINAL_NEXT_VERSION}" ]
      then
        _version="${ORIGINAL_NEXT_VERSION}"
    else
        _version=$(_generate_next_patch_version "${STRIPPED_VERSION}")"-SNAPSHOT"
    fi
fi
# is SNAPSHOT - only change the SNAPSHOT version
_sed_filter="$(_build_id_sed_regexp "${ORIGINAL_ARTIFACT_ID}" "${sed_snapshot_number_filter}" "${_version}")"

# 3. '_build_sed_cmd ...'  - inline replace of version
_cmd+="$(_build_sed_cmd "${_sed_filter}") "

[ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_cmd}"
# 4. '_exec_cmd ...'       - execute the assembled command line
_exec_cmd "${_cmd}"
