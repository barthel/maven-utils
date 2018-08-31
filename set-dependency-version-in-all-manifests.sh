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
# Replaces version in MANIFEST-file, with a OSGI "Require-Bundle"-header, entries following the pattern:
#   [artifactId];bundle-version="[version number or version range]"
#
# Locates transitivly all MANIFEST-files (MANIFEST.MF) in the current directory.
# In each found MANIFEST-file will the entry,  matches the pattern:
#   [artifactId];bundle-version="[old_version]"
# , be modified to replace the [old_version] with the given new version argument.
#
# MANIFEST-file example:
# -----------------
#  1. MANIFEST-file before modification:
#    [...]
#    Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
#     my.artifactId;bundle-version="[0.8.15,0.8.15]",
#    [...]
#
#  2. MANIFEST-file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"
#    [...]
#    Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
#     my.artifactId;bundle-version="47.11.0",
#    [...]
#
# Usage:
# ------
#  > set-dependencies-in-all-manifests.sh "my.artifactId" "0.8.15-SNAPSHOT"
#

# activate debug output
# set -x

# Includes shared functions, checks and provides the command line arguments.
script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. ${script_directory}/_set_dependencies_functions.sh

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed'
[ 0 != $? ] && exit $? || true

# Builds the inplace 'sed' replace regexp to replace the version.
#
# Usage:
# ------
# [...]
#   _build_sed_regexp ${original_artifact_id} ${version}
# [...]
#
# @param #1: artifact id or regexp pattern for use in 'sed' regexp pattern
# @param #2: version or regexp pattern for use in 'sed' regexp pattern
# @returns: the full assembled inplace 'sed' replace regexp
#
_build_sed_regexp() {
  local _artifact_id="${1}"
  local _version="${2}"

  # [artifactId];bundle-version="[version]"
  echo "s|\(${_artifact_id};bundle-version=\\\"\)\(.*\)\(\\\".*\)|\1${_version}\3|"
}

# Builds the whole replace command based on 'find', 'sed' ...
#
# Usage:
# ------
# [...]
#   _build_cmd ${original_artifact_id} ${version}
# [...]
#
# @param #1: artifact id or regexp pattern for use in 'sed' regexp pattern
# @param #2: version or regexp pattern for use in 'sed' regexp pattern
# @returns: the full assembled replace command
#
_build_cmd() {
  local _artifact_id="${1}"
  local _version="${2}"
  local _sed_regexp=$(_build_sed_regexp ${_artifact_id} ${_version})

  # meaning of parameters in ordered way:
  # 1. '_build_find_cmd ...' - find relative path only of files with name pattern and
  #                            and the path does not contains one of the path pattern
  # 2. 'xargs grep -l ...'   - select file names containing the OSGI "Require-Bundle"-header pattern
  # 3. 'xargs sed ...'       - inline replace of version
  # @see: http://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
  eval "_build_find_cmd \"MANIFEST.MF\" | xargs grep -l \"${_artifact_id}\;bundle-version=\" | xargs sed -i '' \"${_sed_regexp}\""
}

# Replace version in dependency definition of MANIFEST.MF
# [artifactId];bundle-version="[version]"

# is SNAPSHOT - use stripped version
_version="${stripped_version}"
# is NOT SNAPSHOT - use version range "[stripped_version,stripped_version]"
if ! ${is_snapshot_version}
  then
    _version="\\\[${_version},${_version}\\\]"
fi

cmd="_build_cmd ${original_artifact_id} ${_version}"
[ 0 -lt ${verbose} ] && echo "Execute: ${cmd}"
eval ${cmd}
