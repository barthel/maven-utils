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
# This script is primarily to include (source) in other bash scripts.
# Usage:
# ------
# [...]
#   script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
#   . ${script_directory}/_global_functions.sh
# [...]
#

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# activate debug output
# set -x

[ -z ${verbose} ] && verbose=0
[ -z ${quiet} ] && quiet=0

# Checks the required tools and commands.
#
# Usage:
# ------
# [...]
#   required_helper=('date' 'git' 'mktemp' 'cat' 'grep' 'cut' 'sed' 'curl' 'ssh' 'readlink')
# [...]
#   _check_required_helper "${required_helper[@]}"
#   [ 0 != $? ] && exit $? || true
# [...]
#
# @param #1: array of tool/command name
# @returns: 1 if a executable was not found, otherwise 0
#
_check_required_helper() {
   _helper=($@)
   for executable in "${_helper[@]}";
   do
     # @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
     if [ "" != "$(command -v ${executable})" ]
     then
       [ 0 -lt ${verbose} ] && echo "found required executable: ${executable}"
     else
       echo "the executable: ${executable} is required!"
       return 1
     fi
   done
   return 0
}

# Appends a '-q ' on given argument
#
# Usage:
# ------
# [...]
#   [ 0 -lt ${quiet} ] && script_cmd=$(_append_quiet_parameter "${script_cmd}")
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
#   [ 0 -lt ${verbose} ] && script_cmd=$(_append_verbose_parameter "${script_cmd}")
# [...]
#
# @param #1: argument
# @param #2: verbose level or ${verbose} if not passed
# @returns: argument appended with multiple " -v "
#
_append_verbose_parameter() {
  local _argument="${1}"
  local _verbose=0
  [ -z "${2}" ] && _verbose=${verbose} || _verbose=${2}

  if [ 0 -lt ${_verbose} ]
    then
     _argument+=" -v"
     for (( level=1; level<${_verbose}; level++ ))
      do
        _argument+="v"
    done
    _argument+=" "
    echo "${_argument}"
  fi
}
