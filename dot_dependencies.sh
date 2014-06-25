#!/bin/bash
DOT_FILE_NAME=dependencies.dot
# Use the lokal pom.xml (maven) and create dependency-tree in dot format.
# The dot-output will be modified (replace 'digraph' with 'subgraph') and surround by 'digraph G' and formatting information.
#
# use dot file like:
#   xdot --filter=dot $DOT_FILE_NAME
# or use for print on several A4 paper
#   dot -Tps2 $DOT_FILE_NAME | ps2pdf -dSAFER -dOptimize=true -sPAPERSIZE=a4 - $DOT_FILE_NAME.pdf
#
# see: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html
INCLUDE="de.icongmbh.*:::*-SNAPSHOT"
EXCLUDE="de.icongmbh.release*:::"

echo -e 'digraph G { \n ' > $DOT_FILE_NAME
echo -e '    graph [fontsize=8 fontname="Courier" compound=true];\n    node [shape=record fontsize=8 fontname="Courier"];\n    rankdir="LR";\n    page="8.3,11.7";\n ' >> $DOT_FILE_NAME

mvn dependency:tree -Dincludes="$INCLUDE" -Dexcludes="$EXCLUDE" -DoutputType=dot | grep -E '\{|\;|\}' | cut -d']' -f2  | sed 's/digraph/subgraph/g' >> $DOT_FILE_NAME

echo '}' >> $DOT_FILE_NAME

