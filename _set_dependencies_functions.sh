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
# Provides global functions for dependency modification to share and use in several scripts.
#
# This script is primarily to include (source) in other bash scripts.
# Usage:
# ------
# [...]
#   script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
#   . ${script_directory}/_set_dependencies_functions.sh
# [...]
#
[ -z ${script_directory} ] && echo "script_directory is required and must be provided." && exit 1

# Includes shared functions, checks and provides the command line arguments.
. ${script_directory}/_global_functions.sh

# check the presens of required tools/commands/executables
_check_required_helper 'pwd' 'cat'
[ 0 != $? ] && exit $? || true

# defines the current directory if not available
[ -z ${current_dir} ] && current_dir="$(pwd)"

# holds the information if the given version is a SNAPSHOT version or not
is_snapshot_version=false

# Prints a help/usage message on console.
#
# Usage:
# ------
# [...]
#   _show_help
# [...]
#
# @param: none
# @returns: none
#
_show_help() {
cat << EOF
Usage: ${0##*/} [-h?qv] "ARTIFACT" "VERSION"

Replaces the version of a artifact in any kind of file.

    -h|-?                      display this help and exit.
    -q                         quiet modus.
    -v                         verbose mode. Can be used multiple times for increased verbosity.
EOF
}

# Checks the size of the given arguments and print usage/help if the check not passed.
#
#
# Usage:
# ------
# [...]
#   _check_arguments "${@}"
#   [ 0 != $? ] && exit $? || true
# [...]
#
# @param #1: array of passed arguments
# @returns: 1 if the check not passed, otherwise 0
#
_check_arguments() {
  _arguments=(${@})
  if [ 2 -ne ${#_arguments[@]} ]
    then
      echo "\"ARTIFACT\" and \"VERSION\" arguments are required."
      _show_help
      return 1
  fi
  return 0
}

# Builds the 'find' command including filer based on given file name pattern and directory.
#
#
# Usage:
# ------
# [...]
#   _build_find_cmd "\*pom.xml"
# [...]
#
# @param #1: file name pattern for use in find command - required
# @param #2: path where the 'find' command will start the search or ${current_dir} if not passed - optional
# @returns: the full assembled 'find' command
#
_build_find_cmd() {
  [ -z "${1}" ] && echo "file name pattern is required for 'find' command" && exit 1
  local _file_name_pattern="${1}"
  local _current_dir="${current_dir}"
  local _verbose=${verbose}
  [ -z "${2}" ] || _current_dir="${2}"

  eval "find ${_current_dir} -type f \( -name '${_file_name_pattern}' -and -not -ipath '*/.git/*' -and -not -ipath '*/target/*' -and -not -ipath '*/bin/*' \) "
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "h?qv" opt;
do
  case "$opt" in
    h|\?)
      _show_help
      exit 0
    ;;
    q)  quiet=1
    ;;
    v)  verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))
_check_arguments "${@}"
[ 0 != $? ] && exit $? || true

original_artifact_id="${1}"
original_version="${2}"
# escape dot for use in rexexp pattern
version="${original_version//\./\\.}"
stripped_version="${version}"

# check and strip -SNAPSHOT from version
[[ ${version} == *-SNAPSHOT ]] && is_snapshot_version=true && stripped_version="${version%%\-*}"
