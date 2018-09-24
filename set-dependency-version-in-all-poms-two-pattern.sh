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
# Replaces version in Maven POM-file property entries following these two patterns:
#   <[artifactId].version.release>[version number]</[artifactId].version.release>
#   <[artifactId].version.snapshot>[next version number]</[artifactId].version.snapshot>
#
# Locates transitively all POM-files (pom.xml) in the current directory.
# In each found POM-file will the <properties> chield element, where the element
# matches these two patterns:
#   <[artifactId].version.release>[old_version]</[artifactId].version.release>
#   <[artifactId].version.snapshot>[next version number]</[artifactId].version.snapshot>
# , modify to replace the [old_version] with the given new version argument and
# the [next version number] with the third passed (["NEXT_VERSION"]) argument or with
# with the next generated patch version.
#
# POM-file example:
# -----------------
#  1. POM-file before modification:
#    [...]
#    <properties>
#      <artifactId.version.release>0.8.15<artifactId.version.release>
#      <artifactId.version.snapshot>0.8.16-SNAPSHOT<artifactId.version.snapshot>
#    </properties>
#    [...]
#
#  2a. POM-file after executing this script with parameter "artifactId" "47.11.0"
#    [...]
#    <properties>
#      <artifactId.version.release>47.11.0<artifactId.version.release>
#      <artifactId.version.snapshot>47.11.1-SNAPSHOT<artifactId.version.snapshot>
#    </properties>
#    [...]
#
#  2b. POM-file after executing this script with parameter "artifactId" "47.11.0" "48.0.0-SNAPSHOT"
#    [...]
#    <properties>
#      <artifactId.version.release>47.11.0<artifactId.version.release>
#      <artifactId.version.snapshot>48.0.0-SNAPSHOT<artifactId.version.snapshot>
#    </properties>
#    [...]
#
#  2c. POM-file after executing this script with parameter "artifactId" "48.0.0-SNAPSHOT"
#    [...]
#    <properties>
#      <artifactId.version.release>47.11.0<artifactId.version.release>
#      <artifactId.version.snapshot>48.0.0-SNAPSHOT<artifactId.version.snapshot>
#    </properties>
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

# Builds the inplace 'sed' replace regexp to replace the version in properties:
#  <artifactId.version.release>47.11.0</artifactId.version.release>
#
# Usage:
# ------
# [...]
#   _build_property_sed_regexp ${original_artifact_id} ["release"|"snapshot"] ${version}
# [...]
#
# @param #1: artifact id or regexp pattern for use in 'sed' regexp pattern
# @param #3: property filter like 'release' or 'snapshot'
# @param #2: version or regexp pattern for use in 'sed' regexp pattern
# @returns: the full assembled inplace 'sed' replace regexp
#
_build_property_sed_regexp() {
  local _property_sed_artifact_id="${1}"
  local _property_sed_artifact_id_filter="${2}"
  local _property_sed_version="${3}"

  echo "s|<\\(${_property_sed_artifact_id}\\.version\\.${_property_sed_artifact_id_filter}\\)>\\(.*\\)<|<\\1>${_property_sed_version}<|"
}

# 'sed' regexp for version ends with "-SNAPSHOT"
sed_snapshot_id_filter='snapshot'
# 'sed' regexp for version ends with a digit
sed_not_snapshot_id_filter='release'

_version="${VERSION}"

# <[artifactId]\.version\\.
property_name="${1}\\.version\\."

_find_filter="pom.xml"
_grep_filter="<${property_name}[${sed_snapshot_id_filter}\\|${sed_not_snapshot_id_filter}]"

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
    _sed_filter="$(_build_property_sed_regexp "${ORIGINAL_ARTIFACT_ID}" "${sed_not_snapshot_id_filter}" "${_version}")"
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
_sed_filter="$(_build_property_sed_regexp "${ORIGINAL_ARTIFACT_ID}" "${sed_snapshot_id_filter}" "${_version}")"

# 3. '_build_sed_cmd ...'  - inline replace of version
_cmd+="$(_build_sed_cmd "${_sed_filter}") "

[ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_cmd}"
# 4. '_exec_cmd ...'       - execute the assembled command line
_exec_cmd "${_cmd}"

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ ${VERBOSE} -lt 2 ]] && trap "$(_exec_cmd _build_delete_sed_backup_files)" EXIT
