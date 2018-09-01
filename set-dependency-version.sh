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
# Replaces the version of a artifact in any kind of file.
#
# This script executes all scripts with the file name pattern:
#  set-dependency-version-in*.sh
#
# Usage:
# ------
#  > set-dependency-version.sh "my.artifactId" "47.11.0"
#  > set-dependency-version.sh "my.artifactId" "0.8.15-SNAPSHOT"

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./_set_dependencies_functions.sh
. "${SCRIPT_DIRECTORY}/_set_dependencies_functions.sh"

# Find and execute scripts in the script directory starts with the file name _file_name_pattern
#   set-dependency-version-in*.sh
for _script_file in "${SCRIPT_DIRECTORY}"/set-dependency-version-in*.sh; do
  _script_cmd="${_script_file}"
  # append 'quiet' command line argument on each script execution if this script was executed
  # with a 'quiet' command line argument
  [ 0 -lt "${QUIET}" ] && _script_cmd=$(_append_quiet_parameter "${_script_cmd}")
  # append 'verbose' command line argument on each script execution if this script was executed
  # with a 'verbose' command line argument
  [ 0 -lt "${VERBOSE}" ] && _script_cmd=$(_append_verbose_parameter "${_script_cmd}")
  # append all other command line arguments
  _script_cmd+=" ${*}"
  [ 0 -lt "${QUIET}" ] || echo "Execute: ${_script_cmd}"
  # execute the script and check the return value
  if ! ${_script_cmd}; then echo "${_script_cmd} failed with $?"; exit $?; fi
done
