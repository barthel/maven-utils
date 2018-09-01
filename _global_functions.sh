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
# Provides global functions for share and use in several scripts.
#
# Notice:
# -------
# This script is primarily to include (source) in other bash scripts.
# To prevent the shellcheck directive #1091 (https://github.com/koalaman/shellcheck/wiki/SC1091)
# please check all scripts with 'shellcheck -x'.
#
# Usage:
# ------
# [...]
#   [ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
#   # @see: https://github.com/koalaman/shellcheck/wiki/SC1090
#   # shellcheck source=./_global_functions.sh
#   . "${SCRIPT_DIRECTORY}/_global_functions.sh"
# [...]
#

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# activate debug output
# @see: https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -e
# set -x

# exit codes
export EXIT_CODE_EXECUTABLE_NOT_FOUND=2

# Checks the required tools and commands.
#
# Breaks execution with exit code 'EXIT_CODE_EXECUTABLE_NOT_FOUND' if a required toll/command was not found.
#
# Usage:
# ------
# [...]
#   required_helper=('date' 'git' 'mktemp' 'cat' 'grep' 'cut' 'sed' 'curl' 'ssh' 'readlink')
# [...]
#   _check_required_helper "${required_helper[@]}"
# [...]
#
# @param #1: array of tool/command name
# @returns:  none
# @exit:     EXIT_CODE_EXECUTABLE_NOT_FOUND - if a executable was not found
#
_check_required_helper() {
   for executable in "${@}";
   do
     # @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
     if [ "" != "$(command -v "${executable}")" ]
     then
       [ 0 -lt "${VERBOSE}" ] && echo "found required executable: ${executable}"
     else
       echo "the executable: ${executable} is required!"
       exit ${EXIT_CODE_EXECUTABLE_NOT_FOUND}
     fi
     return 0
   done
}

# Appends a '-q ' on given argument
#
# Usage:
# ------
# [...]
#   [ 0 -lt ${QUIET} ] && script_cmd=$(_append_quiet_parameter "${script_cmd}")
# [...]
#
# @param #1: argument
# @returns: argument appended with " -q "
#
_append_quiet_parameter() {
  echo "${1} -q "
}

# Appends '-v' and maybe multiple 'v' on given argument based on the given verbose level
#
# Usage:
# ------
# [...]
#   [ 0 -lt ${VERBOSE} ] && script_cmd=$(_append_verbose_parameter "${script_cmd}")
# [...]
#
# @param #1: argument
# @param #2: verbose level or ${verbose} if not passed
# @returns:  argument appended with " -v" and additional multiple "v"
#
_append_verbose_parameter() {
  local _argument="${1}"
  local _verbose=0
  [ -z "${2}" ] && _verbose="${VERBOSE}" || _verbose="${2}"

  if [ 0 -lt "${_verbose}" ]
    then
     _argument+=" -v"
     for (( level=1; level<"${_verbose}"; level++ ))
      do
        _argument+="v"
    done
    _argument+=" "
    echo "${_argument}"
  fi
}

[ -z "${VERBOSE}" ] && export VERBOSE=0
[ -z "${QUIET}" ] && export QUIET=0

# check the presens of required tools/commands/executables
_check_required_helper 'dirname' 'pwd'

# defines the current directory if not available
if [ -z "${CURRENT_DIR}" ]
  then
    CURRENT_DIR="$(pwd)"
    export CURRENT_DIR
fi
