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
# Use the passed list of local pom.xml (Apache Maven) files and create dependency-tree in dot format.
#
# The DOT-output will be modified (replace 'digraph' with 'subgraph') and surround by 'digraph G' and formatting information.
#
# Example(s):
#
# 1) Complete overview
# Use all POM files (but ignore reactor/module POM files) based on directory structure (git repositories):
#   dot-dependencies-of-all-poms.sh -m -a `find . -iname pom.xml -exec grep -H -v "<modules>" {} \; | grep -v "test\|target\|bin" | cut -d':' -f1 | sort | uniq
#
# Use the DOT file like:
#   xdot --filter=dot $output_file
# or use for print on several A4 paper:
#   dot -Tps2 $output_file | ps2pdf -dSAFER -dOptimize=true -sPAPERSIZE=a4 - $output_file.pdf
# or all in one big PDF:
#  - remove the page size (PAGE="...") from DOT file
#   dot -Tps2 dependencies_nopage.dot | ps2pdf -dSAFER -dOptimize=true - dependencies_nopage.dot.pdf
# @see: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_global_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_global_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'hash' 'date' 'mvn' 'mktemp' 'cat' 'grep' 'cut' 'sed' 'awk' 'prune'

timestamp=`date -R`

input_files=('pom.xml')
output_file='dependencies.dot'
# filter for atifacts
includes='*:::'
excludes=''

# merge dependencies / remove duplicate lines from DOT file
merge_dependencies=0
# use ONLY SNAPSHOT versions
use_only_snapshot=0

# page size; include in DOT file as page="..."; default DIN A 4
dot_file_header="digraph G {\n\ttaillabel=\"${timestamp}\";\n\tlabelfontsize=6;\n\tgraph [\n\t\tcompound=true,\n\t\tfontname=Courier,\n\t\tfontsize=8,\n\t\trankdir=LR\n\t];\n\tnode [\n\t\tfontname=Courier,\n\t\tfontsize=8,\n\t\tcolor=Black\n\t\tshape=rect\n\t];"
dot_file_footer="\n}"
page_size='8.3,11.7'

# outputFile doesn't work with reactor POMs
#exec_mvn="mvn -q -B org.apache.maven.plugins:maven-dependency-plugin:2.10:tree -DoutputType=dot -DappendOutput=true -Denforcer.skip=true"
exec_mvn="mvn -B org.apache.maven.plugins:maven-dependency-plugin:2.10:tree -DoutputType=dot -Denforcer.skip=true"

sed_word_pattern='a-zA-Z\_0-9.-' # \w\d.-
# "groupId:artifactId:type[:classifier]:version[:scope]" -> "artifactId:type[:classifier]:version"
# #1: (groupId:)
# #2: (artifactId:type)
# #3: ([:classifier]:version)
# #3: (:scope)"
sed_normalize_artifactId_version="sed -e 's/\"\([$sed_word_pattern]*:\)\([$sed_word_pattern]*:[$sed_word_pattern]*\)\(:[$sed_word_pattern]*\)\(\:[$sed_word_pattern]*\)*/\"\2\3/g'"
# #1: (artifactId)
sed_normalize_artifactId="sed -e 's/\"\([$sed_word_pattern]*:\)\([$sed_word_pattern]*\)\(:[$sed_word_pattern]*\)\(:[$sed_word_pattern]*\)\(\:[$sed_word_pattern]*\)*/\"\2/g'"

exec_sed_normalize_artifacts=$sed_normalize_artifactId_version

# rename 'digraph' into 'subgraph'
exec_sed_rename_graph="sed 's/digraph/subgraph/g'"

# remove duplicate lines but not ' }'
# @see: http://theunixshell.blogspot.de/2012/12/delete-duplicate-lines-in-file-in-unix.html
exec_awk_duplicate_lines="awk '\$0 ~ \"}\" || !x[\$0]++'"
# remove duplicate braces (' } ')
# @see: https://www.linuxquestions.org/questions/programming-9/removing-duplicate-lines-with-sed-276169/#post1400421
exec_sed_duplicate_braces_line="sed -e'\$!N; /^\(.*\)\n\1\$/!P; D'"


# filter and cut DOT output out of mvn console message
#exec_grep_filter_console_message='grep -E "^\[INFO\].*[{;}]" | grep -v -E "[\$@]"'
exec_grep_filter_console_message='grep -E "[{;}]" | grep -v -E "[\$@]" | grep -v "osgi.os"'
exec_cut_console_message='cut -d"]" -f2 | sed -E "s/(\s*\(.*)$/\" ;/g"'

show_help() {
cat << EOF
Usage: ${0##*/} [-ah?mqsuv] [-e EXCLUDES] [-i INCLUDES] [-o OUTFILE] [-p PAGE_SIZE] [FILE]...

Create a DOT file based on Maven dependencies (as a 'subgraph') provided by FILE.

With no FILE the default '${input_files[0]}' will be used.

    -h|-?        display this help and exit.
    -a           only artifactIds without version information.
    -d           debug mode. Temporarly files doesn't deleted on exit.
    -e EXCLUDES  exclude dependencies mode.
                 A comma-separated list of artifacts to filter from the serialized dependency tree, or null (default) not
                 to filter any artifacts from the dependency tree. An empty pattern segment is treated as an implicit wildcard.
    -i INCLUDES  include dependencies mode.
                 A comma-separated list of artifacts to filter the serialized dependency tree by, or null not
                 to filter the dependency tree. An empty pattern segment is treated as an implicit wildcard.
                 '${includes}' (default)
                 See: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html#includes for more information
    -m           merge dependencies mode.
    -o OUTFILE   Write the result to OUTFILE ('${output_file}').
    -p PAGE_SIZE The page size in inch.
                 See: http://www.graphviz.org/content/attrs#dpage for more information
    -q           quiet mode.
    -s           ONLY SNAPSHOT versions mode.
    -u           force update repositories mode.
                 Forces a check for updated releases and snapshots on remote Maven repositories.
    -v           verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} \`find . -iname pom.xml -exec grep -H -v "<modules>" {} \; | grep -v "test\|target\|bin" | cut -d':' -f1 | sort | uniq\`
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "adh?mqsuve:i:o:p:" opt;
do
    case "$opt" in
    a)  exec_sed_normalize_artifacts=$sed_normalize_artifactId
        ;;
    d)  debug=1
        ;;
    e)  exec_mvn="${exec_mvn} -Dexcludes=\"$OPTARG\""
        ;;
    h|\?)
        show_help
        exit 0
        ;;
    i)  includes="$OPTARG"
        ;;
    m)  merge_dependencies=1
        ;;
    o)  output_file=$OPTARG
        ;;
    p)  page_size="$OPTARG"
        ;;
    q)  quiet=1
        ;;
    s)  use_only_snapshot=1
        ;;
    u)  exec_mvn="${exec_mvn} -U"
        ;;
    v)  verbose=$((verbose + 1))
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift;

# use left over arguments as list of POM files
[[ "${#}" -gt "0" ]] && input_files=($@)

[[ $use_only_snapshot -gt 0 ]] && includes="$includes*-SNAPSHOT"

[[ -n "$includes" ]] && exec_mvn="${exec_mvn} -Dincludes=\"$includes\""

[[ $verbose -gt 0 || $debug -gt 0 ]] && echo -e "input_files: ${input_files[*]}\noutput_file: $output_file\nincludes: $includes\nexcludes: $excludes\nverbose: $verbose\npage_size: $page_size"
# add Maven verbose option if 'v' command line arg was more than twice
#[[ $verbose -gt 2 ]] && exec_mvn="${exec_mvn} -X"
### CMD ARGS

# get count of cpu cores and adapt thread count
# @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
if hash nproc 2>/dev/null
then
  exec_mvn="${exec_mvn} -T`nproc`"
fi

### DEPENDENCIES
# temp. working file for collect the mvn output
# @see: https://stackoverflow.com/a/31397073/4956096
temp_dependencies_output_file=`mktemp "${TMPDIR:-/tmp}/dep_${0##*/}.XXXXXXXXX"`
temp_output_file=`mktemp "${TMPDIR:-/tmp}/${0##*/}.XXXXXXXXX"`

[[ $verbose -gt 1 ]] && echo -e "temp_dependencies_output_file: ${temp_dependencies_output_file}\ntemp_output_file: ${temp_output_file}"

counter=1
# iterate over the POM file list and exec mvn
for pom_file in "${input_files[@]}"
do
  [[ $quiet -lt 1 ]] && echo "working on [$counter/${#input_files[@]}]: $pom_file"
  # -DoutputFile and -Doutput seems not work in this special behaviour :-(
  #    mvn_cmd="$exec_mvn -DoutputFile=${temp_dependencies_output_file} -f \"${pom_file}\" "
  # use the console output instead
  mvn_cmd="$exec_mvn -f\"${pom_file}\" 2>&1 | ${exec_grep_filter_console_message} | ${exec_cut_console_message}"
  [[ $verbose -gt 0 ]] && echo "$mvn_cmd"
  # send job to background to get the PID
  eval $mvn_cmd >> $temp_dependencies_output_file &
  if hash ionice 2>/dev/null
  then
    # set priviliged I/O access
    ionice -c 2 -n 2 -p $$
  fi
  # get job to foreground
  fg %1 2>&1 >> /dev/null
  [[ $? -gt 0 ]] && exit $?; # check the return value
  counter=$((counter + 1))
done

if [ ! -s "$temp_dependencies_output_file" ]
then
  echo "the generated dependencies file ($temp_dependencies_output_file) is empty"
  exit 1
fi
### DEPENDENCIES

[[ $quiet -lt 1 ]] && echo "create: $output_file"
echo -e "$dot_file_header" > $temp_output_file
[[ -n "$page_size" ]] && echo -e "\tpage=\"$page_size\";\n" >> $temp_output_file
cmd="$exec_sed_rename_graph $temp_dependencies_output_file | $exec_sed_normalize_artifacts"
if [ $merge_dependencies -lt 1 ]
then
  cmd="$cmd"
  [[ $verbose -gt 0 ]] && echo "$cmd"
  eval $cmd >> $temp_output_file
else
### MERGE and CLEAN UP
  [[ $quiet -lt 1 ]] && echo 'merge and clean up dependencies'
  # cleanup and normalize DOT content
  cmd="$cmd | $exec_awk_duplicate_lines | $exec_sed_duplicate_braces_line"
  [[ $verbose -gt 0 ]] && echo "$cmd"
  eval $cmd >> $temp_output_file
### MERGE and CLEAN UP
fi
echo -e $dot_file_footer >> $temp_output_file
prune $temp_output_file > $output_file

# clean up temp. work file if debug mode is not enabled
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ $debug -lt 1 ]] && trap "rm -f $temp_dependencies_output_file $temp_output_file" EXIT || echo -e "temp_dependencies_output_file: $temp_dependencies_output_file\ntemp_output_file: $temp_output_file"
