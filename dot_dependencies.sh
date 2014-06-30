#!/bin/bash

# Use the passed list of lokal pom.xml (maven) files and create dependency-tree in dot format.
#
# The DOT-output will be modified (replace 'digraph' with 'subgraph') and surround by 'digraph G' and formatting information.
#
# use the DOT file like:
#   xdot --filter=dot $output_file
# or use for print on several A4 paper
#   dot -Tps2 $output_file | ps2pdf -dSAFER -dOptimize=true -sPAPERSIZE=a4 - $output_file.pdf
#
# @see: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html

#set -x
verbose=0
quiet=0

input_files=('pom.xml')
output_file='dependencies.dot'
# filter for atifacts
includes='de.icongmbh.*:::'
excludes=''

merge_dependencies=0

# page size; include in DOT file as page="..."; default DIN A 4
page_size='8.3,11.7'

exec_mvn='mvn -B dependency:tree -DoutputType=dot -DappendOutput=true'

sed_word_pattern='a-zA-Z\_0-9.-' # \w\d.-
# "groupId:artifactId:type[:classifier]:version[:scope]" -> "artifactId:type:version"
# #1: (groupId:)
# #2: (artifactId:type[:classifier]:version)
# #3: (:scope)"
exec_sed_normalize_artifacts="sed -e 's/\"\([$sed_word_pattern]*:\)\([$sed_word_pattern]*:[$sed_word_pattern]*:[$sed_word_pattern]*\)\(\:[$sed_word_pattern]*\)*/\"\2/g'"
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

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "e:h?i:mo:p:qsuv" opt;
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
    s)  include="$include*-SNAPSHOT"
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
if [ "${#}" -gt "1" ];
then
  input_files=("$@")
fi

[[ $verbose -gt 0 ]] && echo -e "input_files: $input_files\noutput_file: $output_file\nincludes: $includes\nexcludes: $excludes\nverbose: $verbose\npage_size: $page_size"
# add Maven verbose option if 'd' command line arg iwas more than once
[[ $verbose -gt 1 ]] && exec_mvn="$exec_mvn -X"
### CMD ARGS

### DEPENDENCIES
# temp. working file for collect the mvn output
temp_output_file=`tempfile -p"${0##*/}"`

counter=1
# iterate over the POM file list and exec mvn
for pom_file in "${input_files[@]}"
do
  [[ $quiet -lt 1 ]] && echo "working on [$counter/${#input_files[@]}]: $pom_file"
  # -DoutputFile and -Doutput seems not work in this special behaviour :-(
  #    mvn_cmd="$exec_mvn -DoutputFile=$temp_output_file -Doutput=$temp_output_file -Dincludes=\"$include\" -f \"$pom_file\" "
  # use the console output instead
  mvn_cmd="$exec_mvn -Dincludes=\"$includes\" -f\"$pom_file\" 2>&1 | $exec_grep_filter_console_message | $exec_cut_console_message"
  [[ $verbose -gt 0 ]] && echo "$mvn_cmd"
  eval $mvn_cmd >> $temp_output_file
  [[ $? -gt 0 ]] && exit $?; # check the return value
  counter=$((counter + 1))
done

if [ ! -s "$temp_output_file" ]
then
  echo "the generated dependencies file ($temp_output_file) is empty"
  exit 1
fi
### DEPENDENCIES

[[ $quiet -lt 1 ]] && echo "create: $output_file"
echo -e 'digraph G { \n ' > $output_file
echo -e "    graph [fontsize=8 fontname=\"Courier\" compound=true];\n    node [shape=record fontsize=8 fontname=\"Courier\"];\n    rankdir=\"LR\";\n    page=\"$page_size\";\n " >> $output_file
cmd="$exec_sed_rename_graph $temp_output_file | $exec_sed_normalize_artifacts"
if [ $merge_dependencies -lt 1 ]
then
  cmd="$cmd"
  [[ $verbose -gt 0 ]] && echo "$cmd"
  eval $cmd >> $output_file
else
### MERGE and CLEAN UP
  [[ $quiet -lt 1 ]] && echo 'merge and clean up dependencies'
  # cleanup and normalize DOT content
  cmd="$cmd | $exec_awk_duplicate_lines | $exec_sed_duplicate_braces_line"
  [[ $verbose -gt 0 ]] && echo "$cmd"
  eval $cmd >> $output_file
### MERGE and CLEAN UP
fi
echo '}' >> $output_file

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ $verbose -lt 2 ]] && trap "rm -f $temp_output_file" EXIT

