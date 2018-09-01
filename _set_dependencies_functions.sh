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
#
# Usage:
# ------
# [...]
#   [ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
#   # @see: https://github.com/koalaman/shellcheck/wiki/SC1090
#   # shellcheck source=./_set_dependencies_functions.sh
#   . ${SCRIPT_DIRECTORY}/_set_dependencies_functions.sh
# [...]
#

# exit codes
export EXIT_CODE_INVALID_SIZE_ARGUMENTS=20
export EXIT_CODE_NO_FILENAME_PATTERN_FOR_FIND=30
export EXIT_CODE_COMMAND_REQUIRED_FOR_EXECUTE=40
export EXIT_CODE_GREP_PATTERN_REQUIRED=50
export EXIT_CODE_SED_SCRIPT_REQUIRED=60

# check if 'script_directory' is defined, not empty (${script_directory:?}) and a valid directory (-d)
[ ! -d "${SCRIPT_DIRECTORY:?}" ] && echo "SCRIPT_DIRECTORY must be a valid directory."

# Includes shared functions, checks and provides the command line arguments.
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./_global_functions.sh
. "${SCRIPT_DIRECTORY}/_global_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'cat'

# holds the information if the given version is a SNAPSHOT version or not
export IS_SNAPSHOT_VERSION=false

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
# // do not use the function keyword and make it possible to 'override' this function
_show_help() {
cat << EOF
Usage: ${0##*/} [-h?qv] "ARTIFACT" "VERSION" ["NEXT_VERSION"]

Replaces the version of a artifact in any kind of file.

    -h|-?                      display this help and exit.
    -q                         quiet modus.
    -v                         verbose mode. Can be used multiple times for increased verbosity.
EOF
}

# Checks the size of the given arguments and print usage/help if the check not passed.
#
# Show the help and breaks the execution with exit code 'EXIT_CODE_INVALID_SIZE_ARGUMENTS'
# if the size of the command line is invalid.
#
# Usage:
# ------
# [...]
#   _check_arguments "${@}"
# [...]
#
# @param #1: array of passed arguments
# @returns:  none
# @exit:     EXIT_CODE_INVALID_SIZE_ARGUMENTS - if a executable was not found
_check_arguments() {
  _arguments=("${@}")
  if [ 2 -gt ${#_arguments[@]} ]
    then
      echo "\"ARTIFACT\" and \"VERSION\" arguments are required."
      _show_help
      exit ${EXIT_CODE_INVALID_SIZE_ARGUMENTS}
  fi
  return 0
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
  # extract the string after the last dot
  local _next_patch_version=${1##*\.}
  # increment the extracted part
  ((_next_patch_version++))
  # replace the extracted part with the increment one
  echo "${1%\.*}.${_next_patch_version}"
}

# Builds the 'find' command including filer based on given file name pattern and directory.
#
# Breaks execution with exit code 'EXIT_CODE_NO_FILENAME_PATTERN_FOR_FIND'
# if required file name pattern was not passed.
#
# Usage:
# ------
# [...]
#   _build_find_cmd "\*pom.xml"
# [...]
#
# @param #1: file name pattern for use in find command - required
# @param #2: path where the 'find' command will start the search or ${CURRENT_DIR} if not passed - optional
# @returns:  the full assembled 'find' command
# @exit:     EXIT_CODE_NO_FILENAME_PATTERN_FOR_FIND - if required file name pattern was not passed
#
_build_find_cmd() {
  [ -z "${1}" ] && echo "file name pattern is required for 'find' command" && exit ${EXIT_CODE_NO_FILENAME_PATTERN_FOR_FIND}
  local _file_name_pattern="${1}"
  local _current_dir="${CURRENT_DIR}"

  [ ! -z "${2}" ] && _current_dir="${2}"
  local _find_cmd="find ${_current_dir} -type f \( -name '${_file_name_pattern}' -and -not -ipath '*/.git/*' -and -not -ipath '*/target/*' -and -not -ipath '*/bin/*' \) "

  echo "${_find_cmd}"
}

# Builds the 'grep' command including pattern.
#
# Breaks execution with exit code 'EXIT_CODE_GREP_PATTERN_REQUIRED'
# if required pattern was not passed.
#
# Usage:
# ------
# [...]
#   _build_grep_cmd "<${property_name}"
# [...]
#
# @param #1: pattern for use in grep command - required
# @returns:  the full assembled 'grep' command
# @exit:     EXIT_CODE_GREP_PATTERN_REQUIRED - if required pattern was not passed
#
_build_grep_cmd() {
  [ -z "${1}" ] && echo "pattern is required for 'grep' command" && exit ${EXIT_CODE_GREP_PATTERN_REQUIRED}
  local _grep_pattern="${1}"
  local _grep_cmd="grep -l '${_grep_pattern}' "

  echo "${_grep_cmd}"
}

# Builds the 'sed' command including sed scripts.
#
# Breaks execution with exit code 'EXIT_CODE_SED_SCRIPT_REQUIRED'
# if required sed script was not passed.
#
# Usage:
# ------
# [...]
#   _build_sed_cmd "s|<\\(${property_name}\\)>\\(.*\\)<|<\\1>${VERSION}<|"
# [...]
#
# @param #1: array of sed scripts for use in sed command - required
# @returns:  the full assembled 'sed' command
# @exit:     EXIT_CODE_SED_SCRIPT_REQUIRED - if required sed script was not passed
#
_build_sed_cmd() {
  local _sed_scripts=("${@}")
  [ 0 -eq "${#_sed_scripts[@]}" ] && echo "minimum one sed script is required for 'sed' command" && exit ${EXIT_CODE_SED_SCRIPT_REQUIRED}

  # @see: http://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
  local _sed_cmd="sed -i "
  for _script in "${_sed_scripts[@]}"
    do
      _sed_cmd+="-e \"${_script}\""
  done

  echo "${_sed_cmd}"
}

# Execute the command ivia 'eval'.
#
# Breaks execution with exit code 'EXIT_CODE_COMMAND_REQUIRED_FOR_EXECUTE' if required command was not passed.
#
# Usage:
# ------
# [...]
#   _execd_cmd _build_find_cmd
# [...]
#
# @param #1: command as string including all parameters - required
# @returns:  the output of the executed command
# @exit:     EXIT_CODE_COMMAND_REQUIRED_FOR_EXECUTE - if required command was not passed
#
_exec_cmd() {
  [ -z "${1}" ] && echo "command is required" && exit ${EXIT_CODE_COMMAND_REQUIRED_FOR_EXECUTE}

  # @see: https://stackoverflow.com/questions/11065077/eval-command-in-bash-and-its-typical-uses
  eval "${1}"
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
    q)  QUIET=1
    ;;
    v)  VERBOSE=$((VERBOSE + 1))
    ;;
  esac
done

shift $((OPTIND-1))
_check_arguments "${@}"

export ORIGINAL_ARTIFACT_ID="${1}"
export ORIGINAL_VERSION="${2}"
export ORIGINAL_NEXT_VERSION="${3}"
# escape dot for use in rexexp pattern
export VERSION="${ORIGINAL_VERSION//\./\\.}"
export STRIPPED_VERSION="${VERSION}"

# check and strip -SNAPSHOT from version
if [[ "${VERSION}" == *-SNAPSHOT ]] 
  then
    IS_SNAPSHOT_VERSION=true
    # extract string before '-'
    STRIPPED_VERSION="${VERSION%%\-*}"
fi
