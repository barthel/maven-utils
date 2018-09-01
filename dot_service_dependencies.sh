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
# Use the passed list of lokal OSGi Declarative Service descriptor XML files.
#
# The DOT-output will be created and surround by 'digraph G' and formatting information.
#
# Example(s):
#
# 1) Complete overview
# Use all XNL files:
#   dot_service_dependencies.sh `find . -ipath \*/OSGI-INF/\*.xml -exec grep -wl "http://www.osgi.org/xmlns/scr/v1" {} \;`
#
# Use the DOT file like:
#   xdot --filter=dot $output_file
# or use for print on several A4 paper:
#   dot -Tps2 $output_file | ps2pdf -dSAFER -dOptimize=true -sPAPERSIZE=a4 - $output_file.pdf
# or all in one big PDF:
#  - remove the page size (PAGE="...") from DOT file
#   dot -Tps2 service_dependencies_nopage.dot | ps2pdf -dSAFER -dOptimize=true - service_dependencies_nopage.dot.pdf
# @see: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html

# Include global functions
# @see: http://wiki.bash-hackers.org/syntax/shellvars
[ -z "${SCRIPT_DIRECTORY}" ] && SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )" && export SCRIPT_DIRECTORY
# @see: https://github.com/koalaman/shellcheck/wiki/SC1090
# shellcheck source=./lib/_global_functions.sh
. "${SCRIPT_DIRECTORY}/lib/_global_functions.sh"

# check the presens of required tools/commands/executables
_check_required_helper 'date' 'mktemp' 'cat' 'grep' 'cut' 'prune' 'xmllint'

timestamp=`date -R`

output_file='service_dependencies.dot'

# page size; include in DOT file as page="..."; default DIN A 4
dot_file_header="digraph G {\n\ttaillabel=\"${timestamp}\";\n\tlabelfontsize=6;\n\tgraph [\n\t\tcompound=true,\n\t\tfontname=Courier,\n\t\tfontsize=8,\n\t\trankdir=LR\n\t];\n\tnode [\n\t\tfontname=Courier,\n\t\tfontsize=8,\n\t\tcolor=Black\n\t\tshape=rect\n\t];"
dot_file_footer="\n}"
page_size='8.3,11.7'

# find all OSGi DS descriptor files:
exec_find_inputfiles='find . -ipath \*/OSGI-INF/\*.xml -exec grep -wl "http://www.osgi.org/xmlns/scr/v1" {} \;'

xpath_implementation_class="string(//implementation/@class)"
xpath_provide_interface="string(//provide/@interface)"
xpath_count_reference_interface="count(//reference/@interface)"

exec_xmllint="xmllint --xpath "

show_help() {
cat << EOF
Usage: ${0##*/} [-h?qv] [-o OUTFILE] [-p PAGE_SIZE] [FILE]...

Create a DOT file based on Maven dependencies (as a 'subgraph') provided by FILE.

With no FILE the default '${input_files}' will be used.

    -h|-?        display this help and exit.
    -o OUTFILE   Write the result to OUTFILE ('${output_file}').
    -p PAGE_SIZE The page size in inch.
                 See: http://www.graphviz.org/content/attrs#dpage for more information
    -q           quiet mode.
    -v           verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} \`find . -ipath \*/OSGI-INF/\*.xml -exec grep -wl "http://www.osgi.org/xmlns/scr/v1" {} \;\`
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "h?qvo:p:" opt;
do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    o)  output_file=$OPTARG
        ;;
    p)  page_size="$OPTARG"
        ;;
    q)  quiet=1
        ;;
    v)  verbose=$((verbose + 1))
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift;

# use left over arguments as list of OSGi DS XML files or try to find these files
[[ "${#}" -gt "0" ]] && input_files=($@) || input_files=($(eval ${exec_find_inputfiles}))


[[ $verbose -gt 0 ]] && echo -e "input_files: $input_files\noutput_file: $output_file\nverbose: $verbose\npage_size: $page_size"
### CMD ARGS

### DEPENDENCIES
# temp. working file for collect the output
# @see: https://stackoverflow.com/a/31397073/4956096
temp_dependencies_output_file=`mktemp "${TMPDIR:-/tmp}/dep_${0##*/}.XXXXXXXXX"`
temp_output_file=`mktemp "${TMPDIR:-/tmp}/${0##*/}.XXXXXXXXX"`

[[ $verbose -gt 1 ]] && echo -e "temp_dependencies_output_file: ${temp_dependencies_output_file}\ntemp_output_file: ${temp_output_file}"

counter=1
# iterate over the file list and grep information
for xml_file in "${input_files[@]}"
do
  [[ $quiet -lt 1 ]] && echo "working on [${counter}/${#input_files[@]}]: ${xml_file}"

  xmllint_cmd="${exec_xmllint} \"${xpath_implementation_class}\" ${xml_file}"
  [[ $verbose -gt 0 ]] && echo "${xmllint_cmd}"
  service_implementation="$(eval ${xmllint_cmd})"

  xmllint_cmd="${exec_xmllint} \"${xpath_provide_interface}\" ${xml_file}"
  [[ $verbose -gt 0 ]] && echo "${xmllint_cmd}"
  service_interface="$(eval ${xmllint_cmd})"

# 	subgraph "${service_interface}" {
#		"${service_interface}" [label="${service_implementation}"] ;
#		"${service_interface}" -> {
#			"${reference_interface}" ;
#			...
#		} ;
#	}

  echo -e "\tsubgraph \"${service_interface}\" {" >> ${temp_dependencies_output_file}
  echo -e "\t\t\"${service_interface}\" [label=\"${service_implementation}\"] ;" >> ${temp_dependencies_output_file}
  echo -e "\t\t\"${service_interface}\" -> {" >> ${temp_dependencies_output_file}

  reference_counts=$(${exec_xmllint} "${xpath_count_reference_interface}" ${xml_file})
  reference_counter=1
  while [ ${reference_counter} -le ${reference_counts} ]
  do
    xmllint_cmd="${exec_xmllint} \"//reference[${reference_counter}]/@interface\" ${xml_file} | cut -d'\"' -f2"
    [[ $verbose -gt 0 ]] && echo "${xmllint_cmd}"
    reference_interface="$(eval ${xmllint_cmd})"
    echo -e "\t\t\t\"${reference_interface}\" ;" >> ${temp_dependencies_output_file}
    reference_counter=$((reference_counter + 1))
  done
  echo -e "\t\t} ;\n\t} ;" >> ${temp_dependencies_output_file}

  counter=$((counter + 1))
done

if [ ! -s "${temp_dependencies_output_file}" ]
then
  echo "the generated dependencies file (${temp_dependencies_output_file}) is empty"
  exit 1
fi
### DEPENDENCIES

[[ ${quiet} -lt 1 ]] && echo "create: ${output_file}"
echo -e "${dot_file_header}" > ${temp_output_file}
[[ -n "${page_size}" ]] && echo -e "\tpage=\"${page_size}\";\n" >> ${temp_output_file}
cmd="cat ${temp_dependencies_output_file} >> ${temp_output_file}"
[[ ${verbose} -gt 0 ]] && echo "${cmd}"
eval ${cmd}

echo -e ${dot_file_footer} >> ${temp_output_file}
prune ${temp_output_file} > ${output_file}

# clean up temp. work file if verbose level is lower than '2'
# @see: http://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files
[[ ${verbose} -lt 2 ]] && trap "rm -f ${temp_dependencies_output_file} ${temp_output_file}" EXIT
