#!/bin/bash

# Use the passed list of lokal pom.xml (maven) files and create dependency-tree in dot format.
#
# Example(s):
#
# 1) Complete overview
# Use all POM files based on directory structure (git repositories) where the name of the directory (git repository) starts
# with 'do' or 'ic':
#   dot_dependencies.sh -m -s -i"*:::" `find . -mindepth 2 -iname pom.xml | grep -v "target" | grep -R "^\.\/[id][co]*"`
#
# The DOT-output will be modified (replace 'digraph' with 'subgraph') and surround by 'digraph G' and formatting information.
#
# use the DOT file like:
#   xdot --filter=dot $output_file
# or use for print on several A4 paper:
#   dot -Tps2 $output_file | ps2pdf -dSAFER -dOptimize=true -sPAPERSIZE=a4 - $output_file.pdf
# or all in one big PDF:
#  - remove the page size (PAGE="...") from DOT file
#   dot -Tps2 dependencies_nopage.dot | ps2pdf -dSAFER -dOptimize=true - dependencies_nopage.dot.pdf
# @see: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html

#set -x

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m

verbose=0
quiet=0

required_helper=('date' 'mvn' 'tempfile' 'cat' 'grep' 'cut' 'sed' 'awk' 'prune')

timestamp=`date --rfc-3339=seconds`

input_files=('pom.xml')
output_file='dependencies.dot'
# filter for atifacts
includes='de.icongmbh.*:::'
excludes=''

# merge dependencies / remove duplicate lines from DOT file
merge_dependencies=0
# use ONLY SNAPSHOT versions
use_only_snapshot=0

# page size; include in DOT file as page="..."; default DIN A 4
dot_file_header="/* ${timestamp} ${0} ${@} */\ndigraph G {\n\tlabel=\"${timestamp} ${0} ${@}\";\n\tgraph [\n\t\tcompound=true,\n\t\tfontname=Courier,\n\t\tfontsize=8,\n\t\trankdir=LR\n\t];\n\tnode [\n\t\tfontname=Courier,\n\t\tfontsize=8,\n\t\tcolor=Black\n\t\tshape=rect\n\t];"
dot_file_footer="\n}"
page_size='8.3,11.7'

exec_mvn="mvn -B dependency:tree -DoutputType=dot -DappendOutput=true -Denforcer.skip=true"

sed_word_pattern='a-zA-Z\_0-9.-' # \w\d.-
# "groupId:artifactId:type[:classifier]:version[:scope]" -> "artifactId:type:version"
# #1: (groupId:)
# #2: (artifactId:type)
# #3: ([:classifier]:version)
# #3: (:scope)"
exec_sed_normalize_artifacts="sed -e 's/\"\([$sed_word_pattern]*:\)\([$sed_word_pattern]*:[$sed_word_pattern]*\)\(:[$sed_word_pattern]*\)\(\:[$sed_word_pattern]*\)*/\"\2\3/g'"
# rename 'digraph' into 'subgraph'
exec_sed_rename_graph="sed 's/digraph/subgraph/g'"

# remove duplicate lines but not ' }'
# @see: http://theunixshell.blogspot.de/2012/12/delete-duplicate-lines-in-file-in-unix.html
exec_awk_duplicate_lines="awk '\$0 ~ \"}\" || !x[\$0]++'"
# remove duplicate braces (' } ')
# @see: https://www.linuxquestions.org/questions/programming-9/removing-duplicate-lines-with-sed-276169/#post1400421
exec_sed_duplicate_braces_line="sed -e'\$!N; /^\(.*\)\n\1\$/!P; D'"


# filter and cut DOT output out of mvn message
exec_grep_filter_console_message='grep -E "[{;}]" | grep -v -E "[\$@]"'
exec_cut_console_message='cut -d"]" -f2'

show_help() {
cat << EOF

Usage: ${0##*/} [-hmqsuv [-e EXCLUDES] [-i INCLUDES] [-o OUTFILE] [-p PAGE_SIZE] [FILE]...
Create a DOT file based on Maven dependencies (as a 'subgraph') provided by FILE.

With no FILE the default '$input_files' will be used.
    
    -e EXCLUDES  exclude dependencies mode.
                 A comma-separated list of artifacts to filter from the serialized dependency tree, or null (default) not
                 to filter any artifacts from the dependency tree. An empty pattern segment is treated as an implicit wildcard.
    -h           display this help and exit
    -i INCLUDES  include dependencies mode.
                 A comma-separated list of artifacts to filter the serialized dependency tree by, or null not
                 to filter the dependency tree. An empty pattern segment is treated as an implicit wildcard.
                 '$includes' (default)
                 See: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html#includes for more information
    -m           merge dependencies mode.
    -o OUTFILE   Write the result to OUTFILE instead of '$output_file' (default).
    -p PAGE_SIZE The page size in inch.
                 See: http://www.graphviz.org/content/attrs#dpage for more information
    -q           quiet mode.
    -s           ONLY SNAPSHOT versions mode
    -u           force update repositories mode.
                 Forces a check for updated releases and snapshots on remote Maven repositories
    -v           verbose mode. Can be used multiple times for increased verbosity.
    
Example: ${0##*/} \`find . -mindepth 2 -iname pom.xml | grep -v "target"\`
EOF
}

check_required_helper() {
  helper=("$@")
  for executable in "${helper[@]}";
  do
    # @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
    if hash $executable 2>/dev/null
    then
      [[ $verbose -gt 0 ]] && echo "found required executable: $executable"
    else
      echo "the executable: $executable is required!"
      return 1
    fi
  done
  return 0
}
### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "h?mqsuve:i:o:p:" opt;
do
    case "$opt" in
    e)  exec_mvn="$exec_mvn -Dexcludes=\"$OPTARG\""
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
    u)  exec_mvn="$mvn_exec -U"
        ;;
    v)  verbose=$((verbose + 1))
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift;

# use left over arguments as list of POM files
[[ "${#}" -gt "0" ]] && input_files=("$@")

[[ $use_only_snapshot -gt 0 ]] && includes="$includes*-SNAPSHOT"

[[ ! -z "$includes" ]] && exec_mvn="$exec_mvn -Dincludes=\"$includes\""

[[ $verbose -gt 0 ]] && echo -e "input_files: $input_files\noutput_file: $output_file\nincludes: $includes\nexcludes: $excludes\nverbose: $verbose\npage_size: $page_size"
# add Maven verbose option if 'd' command line arg iwas more than once
[[ $verbose -gt 1 ]] && exec_mvn="$exec_mvn -X"
### CMD ARGS

check_required_helper "${required_helper[@]}"

# get count of cpu cores and adapt thread count
# @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
if hash nproc 2>/dev/null
then
  exec_mvn="$exec_mvn -T`nproc`"
fi

### DEPENDENCIES
# temp. working file for collect the mvn output
temp_dependencies_output_file=`tempfile -p"${0##*/}"`
temp_output_file=`tempfile -p"${0##*/}"`

counter=1
# iterate over the POM file list and exec mvn
for pom_file in "${input_files[@]}"
do
  [[ $quiet -lt 1 ]] && echo "working on [$counter/${#input_files[@]}]: $pom_file"
  # -DoutputFile and -Doutput seems not work in this special behaviour :-(
  #    mvn_cmd="$exec_mvn -DoutputFile=$temp_output_file -Doutput=$temp_output_file -Dincludes=\"$include\" -f \"$pom_file\" "
  # use the console output instead
  mvn_cmd="$exec_mvn -f\"$pom_file\" 2>&1 | $exec_grep_filter_console_message | $exec_cut_console_message"
  [[ $verbose -gt 0 ]] && echo "$mvn_cmd"
  # send job to background to get the PID
  eval $mvn_cmd >> $temp_dependencies_output_file &
  # set priviliged I/O access
  ionice -c 2 -n 2 -p $$
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

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ $verbose -lt 2 ]] && trap "rm -f $temp_dependencies_output_file $temp_output_file" EXIT

