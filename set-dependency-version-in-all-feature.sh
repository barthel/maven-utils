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
# Replaces the version in Eclipse RCP feature.xml file 
# where the entries following the pattern:
#    <plugin
#          id="my.artifactId"
#          download-size="0"
#          install-size="0"
#          version="1.0.0-SNAPSHOT"
#          unpack="false"/>
#
# Locates transitively all feature.xml files in the current directory.
# In each found feature.xml file will the entry,  matches the pattern:
#    <plugin
#          id="[artifactId]"
#          download-size="0"
#          install-size="0"
#          version="[old_version]"
#          unpack="false"/>
# , modify to replace the [old_version] with the given new version argument.
#
# feature.xml file example:
# -----------------
#  1. feature.xml file before modification:
#    [...]
#    <plugin
#          id="my.artifactId"
#          download-size="0"
#          install-size="0"
#          version="1.0.0-SNAPSHOT"
#          unpack="false"/>
#    [...]
#
#  2a. feature.xml file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"
#    [...]
#    <plugin
#          id="my.artifactId"
#          download-size="0"
#          install-size="0"
#          version="47.11.0.qualifier"
#          unpack="false"/>
#    [...]
#
#  2b. feature.xml file after executing this script with parameter "my.artifactId" "47.11.0"
#    [...]
#    <plugin
#          id="my.artifactId"
#          download-size="0"
#          install-size="0"
#          version="47.11.0"
#          unpack="false"/>
#    [...]
#
# Usage:
# ------
#  > set-dependency-version-in-all-feature.sh "my.artifactId" "47.11.0"
#  > set-dependency-version-in-all-feature.sh "my.artifactId" "0.8.15-SNAPSHOT"
#

# set -x

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_set_dependencies_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_set_dependencies_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed' 'awk'

# is SNAPSHOT - use stripped version
_version="${VERSION}"
# is NOT SNAPSHOT - use version range "[stripped_version,stripped_version]"
if ${IS_SNAPSHOT_VERSION}
  then
    _version="${STRIPPED_VERSION}\.qualifier"
fi

_find_filter="feature.xml"
# id="${ORIGINAL_ARTIFACT_ID}"
_grep_filter="id=\\\"${ORIGINAL_ARTIFACT_ID}\\\""
# id="${ORIGINAL_ARTIFACT_ID}"
_awk_filter="${_grep_filter}"
# version="${VERSION}"
# @see: https://stackoverflow.com/questions/2854655/command-to-escape-a-string-in-bash
_local_quoted_version="$( printf "%q" "${_version}")"
_sed_filter="s|\\\\\\(version=\\\\\\\"\\\\\\).*\\\\\\(\\\\\\\".*\\\\\\)|\\\\1${_local_quoted_version}\\\\2|g"
_local_quoted_sed_cmd="sed -e\\\"%d,%d ${_sed_filter}\\\" -i.sed-backup  %s"

# 1. '_build_find_cmd ...' - build the find command for relative path only of files
#                            with name pattern
_cmd="( $(_build_find_cmd "${_find_filter}") "
_cmd+=" | $(_build_xargs_cmd) "
# 2. '_build_grep_cmd ...' - select file names containing the bundle version string
_cmd+="$(_build_grep_cmd "${_grep_filter}") || exit 0 ) "

# 3. 'awk ...' - identify file name and range; returns replacement sed script 'sed ... -e"[START],[END] ... [FILENAME]'
# awk '/\<plugin/{s=x; start=NR}{s=s$0"\n"}/id=\"taco.contentstore.encrypted\"/{p=1}/\/>/ && p{printf "sed -e\"%d,%d s|\\\(version=\\\"\\\).*\\\(\\\".*\\\)|\\10\\\.8\\\.15\\\.qualifier\\2|g\" -i.sed-backup  %s\n",start,NR,FILENAME; p=0}'
_cmd+=" | $(_build_xargs_cmd -I '{}') "
_cmd+=" awk '/\\<plugin/{s=x; start=NR}{s=s\$0\"\\n\"}/${_awk_filter}/{p=1}/\\/>/ && p{printf \"${_local_quoted_sed_cmd}\\n\",start,NR,FILENAME; p=0}' {}"

# 4.  - exec command in bash
#    bash -c '{}'
# @see: https://www.cloudsavvyit.com/7984/using-xargs-in-combination-with-bash-c-to-create-complex-commands/
_cmd+=" | $(_build_xargs_cmd -0 ) bash -c "

[ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_cmd}"
# 4. '_exec_cmd ...'       - execute the assembled command line

_exec_cmd "${_cmd}"

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ ${VERBOSE} -lt 2 ]] && trap "$(_exec_cmd _build_delete_sed_backup_files)" EXIT
