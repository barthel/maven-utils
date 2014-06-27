#!/bin/bash

#set -x

input_files='pom.xml'
output_file='dependencies.dot'
iverbose=0¬

show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-f OUTFILE] [FILE]...
Create a DOT file based on Maven dependencies (as a 'subgraph') provided by FILE.

With no FILE the default '$input_files' will be used.
    
    -h          display this help and exit
    -o OUTFILE  write the result to OUTFILE instead of '$output_file' (default).
    -v          verbose mode. Can be used multiple times for increased
                verbosity.
    
Example: ${0##*/} \`find . -mindepth 2 -iname pom.xml | grep -v "target"\`
EOF
}

# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# get arguments
OPTIND=1         # Reset in case getopts has been used previously in the shell.


while getopts "h?vo:" opt;
do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    o)  output_file=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift;

# echo "verbose=$verbose, output_file='$output_file', Leftovers: $@"

if [ "${#}" -gt "1" ];
then
  input_files="$@"
fi

# Use the lokal pom.xml (maven) and create dependency-tree in dot format.
# The dot-output will be modified (replace 'digraph' with 'subgraph') and surround by 'digraph G' and formatting information.
#
# use dot file like:
#   xdot --filter=dot $output_file
# or use for print on several A4 paper
#   dot -Tps2 $output_file | ps2pdf -dSAFER -dOptimize=true -sPAPERSIZE=a4 - $output_file.pdf
#
# @see: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html
INCLUDE="de.icongmbh.*:::*-SNAPSHOT"
EXCLUDE="de.icongmbh.release*:::"
COUNTER=$((COUNTER + 1))

temp_output_file=`tempfile`

for pom_file in $input_files
do
  echo "working on [$COUNTER/${#}]: $pom_file"
  mvn -B -U dependency:tree -Dincludes="$INCLUDE" -Dexcludes="$EXCLUDE" -DoutputType=dot -f "$pom_file" 2>&1 | grep -E '\{|\;|\}' | cut -d']' -f2  | sed 's/digraph/subgraph/g' >> $temp_output_file
  [[ $? -gt 0 ]] && exit $?;
  COUNTER=$((COUNTER + 1))
done

echo "create: $output_file"
echo -e 'digraph G { \n ' > $output_file
echo -e '    graph [fontsize=8 fontname="Courier" compound=true];\n    node [shape=record fontsize=8 fontname="Courier"];\n    rankdir="LR";\n    page="8.3,11.7";\n ' >> $output_file
# remove duplicate lines
awk '$0 ~ "}" || !x[$0]++' $temp_output_file >> $output_file
echo '}' >> $output_file

