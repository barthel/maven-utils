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
# Replaces the version of the parent artifact in a Maven POM-file 
# where the parent entry following the pattern:
#    <parent>
#        <groupId>my.groupId</groupId>
#        <artifactId>my.artifactId</artifactId>
#        <version>0.8.15-SNAPSHOT</version>
#    </parent>
#
# Locates transitively all POM-files (pom.xml) in the current directory.
# In each found POM-file the version of the <parent>-entry, where the entry matches the pattern:
#    <parent>
#        <groupId>[groupId]</groupId>
#        <artifactId>[artifactId]</artifactId>
#        <version>[old_version]</version>
#    </parent>
# , modify to replace the [old_version] with the given new version argument.
#
# POM-file example:
# -----------------
#  1. POM-file before modification:
#    [...]
#    <parent>
#        <groupId>my.groupId</groupId>
#        <artifactId>my.artifactId</artifactId>
#        <version>0.8.15-SNAPSHOT</version>
#    </parent>
#    [...]
#
#  2. POM-file after executing this script with parameter "my.artifactId" "47.11.0"
#    [...]
#    <parent>
#        <groupId>my.groupId</groupId>
#        <artifactId>my.artifactId</artifactId>
#        <version>47.11.0</version>
#    </parent>
#    [...]
#
# Usage:
# ------
#  > set-parent-version-in-all-poms.sh "my.artifactId" "47.11.0-SNAPSHOT"
#  > set-parent-version-in-all-poms.sh "my.artifactId" "47.11.0"

# set -x

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_set_dependencies_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_set_dependencies_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'grep' 'xargs' 'sed' 'awk'

_find_filter="pom.xml"
# id="${ORIGINAL_ARTIFACT_ID}" - escape '/' because this is the part delemiter in awk
_grep_filter="<artifactId>${ORIGINAL_ARTIFACT_ID}<\\/artifactId>"
# id="${ORIGINAL_ARTIFACT_ID}"
_awk_filter="${_grep_filter}"
# version="${VERSION}"
_sed_filter="s|<version>.*</version>|<version>${VERSION}</version>|g"

# 1. '_build_find_cmd ...' - build the find command for relative path only of files
#                            with name pattern
_cmd="$(_build_find_cmd "${_find_filter}") "
_cmd+=" | xargs -r "
# 2. '_build_grep_cmd ...' - select file names containing the bundle version string
_cmd+="$(_build_grep_cmd "${_grep_filter}") "

# 3. 'awk ...' - identify range and returns '[FILENAME]:[START],[END]'
# awk '/<parent>/{s=x; start=NR}{s=s$0"\n"}/<artifactId>my.artifactId<\/artifactId>/{p=1}/<\/parent>/ && p{printf "%s:%d,%d\n",FILENAME,start,NR; p=0}' {}
_cmd+=" | xargs -I '{}'"
_cmd+=" awk '/<parent>/{s=x; start=NR}{s=s\$0\"\\n\"}/${_awk_filter}/{p=1}/<\\/parent>/ && p{printf \"%s:%d,%d\\n\",FILENAME,start,NR; p=0}' {}"

# 4.  - FILENAME="${ARG%%:*}"; RANGE="${ARG##*:}";
#    bash -c '
#      ARG="{}"; sed -i -e"${ARG##*:} s|\\(version=\\\"\\).*\\(\\\".*\\)|\\147\.11\.0\\2|g" ${ARG%%:*}
#    '
_cmd+=" | xargs -r -I '{}'"
_cmd+=" bash -c 'ARG=\"{}\"; $(_build_sed_cmd "\${ARG##*:} ${_sed_filter}") \${ARG%%:*};'"

[ 0 -lt "${VERBOSE}" ] && echo "Execute: ${_cmd}"
# 4. '_exec_cmd ...'       - execute the assembled command line
_exec_cmd "${_cmd}"

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ ${VERBOSE} -lt 2 ]] && trap "$(_exec_cmd _build_delete_sed_backup_files)" EXIT
