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
# Replaces the version in MANIFEST-file, with a OSGI "Require-Bundle"-header, 
# where the entries following the pattern:
#   [artifactId];bundle-version="[version number or version range]"
#
# Locates transitively all MANIFEST-files (MANIFEST.MF) in the current directory.
# In each found MANIFEST-file will the entry,  matches the pattern:
#   [artifactId];bundle-version="[old_version]"
# , modify to replace the [old_version] with the given new version argument.
#
# MANIFEST-file example:
# -----------------
#  1. MANIFEST-file before modification:
#    [...]
#    Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
#     my.artifactId;bundle-version="[0.8.15,0.8.15]",
#    [...]
#
#  2a. MANIFEST-file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"
#    [...]
#    Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
#     my.artifactId;bundle-version="47.11.0",
#    [...]
#
#  2b. MANIFEST-file after executing this script with parameter "my.artifactId" "47.11.0"
#    [...]
#    Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
#     my.artifactId;bundle-version="[47.11.0,47.11.0]",
#    [...]
#
# Usage:
# ------
#  > set-dependency-version-in-all-manifests.sh "my.artifactId" "47.11.0"
#  > set-dependency-version-in-all-manifests.sh "my.artifactId" "0.8.15-SNAPSHOT"
#

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_set_dependencies_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_set_dependencies_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed'

# Replace version in dependency definition of MANIFEST.MF
# [artifactId];bundle-version="[version]"

_bundle_version="${ORIGINAL_ARTIFACT_ID};bundle-version="

# is SNAPSHOT - use stripped version
_version="${STRIPPED_VERSION}"
# is NOT SNAPSHOT - use version range "[stripped_version,stripped_version]"
if ! ${IS_SNAPSHOT_VERSION}
  then
    _version="\\\\[${_version},${_version}\\\\]"
fi

_find_filter="MANIFEST.MF"
_grep_filter="${_bundle_version}"
_sed_filter="s|\\(${_bundle_version}\\\"\\)\\(.*\\)\\(\\\".*\\)|\\1${_version}\\3|"

# 1. '_build_find_cmd ...' - build the find command for relative path only of files
#                            with name pattern
_cmd="$(_build_find_cmd "${_find_filter}") "
_cmd+=" | xargs "
# 2. '_build_grep_cmd ...' - select file names containing the bundle version string
_cmd+="$(_build_grep_cmd "${_grep_filter}") "
_cmd+=" | xargs "
# 3. '_build_sed_cmd ...'  - inline replace of version
_cmd+="$(_build_sed_cmd "${_sed_filter}") "

[ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_cmd}"
# 4. '_exec_cmd ...'       - execute the assembled command line
_exec_cmd "${_cmd}"

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ ${VERBOSE} -lt 2 ]] && trap "$(_exec_cmd _build_delete_sed_backup_files)" EXIT
