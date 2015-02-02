#!/bin/bash

# Get dependees for Maven artifact.
#
# This script will search all artifacts in remote Maven repository manager,
# where the desired artifact is defined as a dependency.
#

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

input_file='pom.xml'
# temp. working file for wget output
temp_output_file=`tempfile -p"${0##*/}"`

archiva_url="http://archiva.icongmbh.de/archiva/browse"
eyecatcher_in_html="<strong>Version(s):</strong>"
wget_cmd="wget -nv -q --no-proxy -O ${temp_output_file} "

show_help() {
cat << EOF
Usage: ${0##*/} [-h?p] [-f POM_FILE] [-a ARTIFACTID -g GROUPID -v VERSION]

Get dependees for Maven artifact provided by POM_FILE or
artifact coordinates (GROUPID, ARTIFACTID and VERSION).

This script will search all artifacts in remote Maven repository manager,
where the desired artifact is defined as a dependency.

Without POM_FILE and maven artifact coordinates the default '$input_file' of current
will be used.

    -h|-?         display this help and exit.
    -a ARTIFACTID the Maven artifact id.
    -f POM_FILE   the Maven project file ('${input_file}').
    -g GROUPID    the Maven artifact group id.
    -p            disable use of proxy server.
    -v VERSION    the Maven artifact version.

Example:  ${0##*/}
          ${0##*/} -f pom.xml
          ${0##*/} -g my.groupId -a my.artifactId -v 4.7.11
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "a:f:g:h?pv:" opt;
do
    case "$opt" in
      a)  artifactId="$OPTARG"
      ;;
      f)  input_file="$OPTARG"
      ;;
      g)  groupId="$OPTARG"
      ;;
      h|\?)
          show_help
          exit 0
      ;;
      p)  wget_cmd="${wget_cmd} --no-proxy "
      ;;
      v)  version="$OPTARG"
      ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift;

if [[ -z "${groupId}" && -z "${artifactId}" && -f "${input_file}" ]]
  then
    groupId=`mvn help:evaluate -f ${input_file} -Dexpression=project.groupId | grep --color=never -Ev '(^\[|WARNING|Download\w+:)'`
    artifactId=`mvn help:evaluate -f ${input_file} -Dexpression=project.artifactId | grep --color=never -Ev '(^\[|WARNING|Download\w+:)'`
    [ -z "${version}" ] && version=`mvn help:evaluate -f ${input_file} -Dexpression=project.version | grep --color=never -Ev '(^\[|WARNING|Download\w+:)'`
fi

[ -z "${groupId}" ] && echo "The groupId is required." && exit 1 || true
[ -z "${artifactId}" ] && echo "The artifactId is required." && exit 1 || true
[ -z "${version}" ] && echo "The version is required." && exit 1 || true

echo -n -e "Get dependees for artifact: ${groupId}/${artifactId} ${version}\n\n"

${wget_cmd} ${archiva_url}/${groupId}/${artifactId}/${version}/usedby

grep  --color=never -A 4 -B 2 ${eyecatcher_in_html} ${temp_output_file} | grep --color=never -v ${eyecatcher_in_html} | xargs | \
  sed -e 's/\-\-/\n/g' | sed -r 's#^.*<a href=[^"]+>([^<]+)</a>.*<a href=[^"]+>([^<]+)</a>.*$#\1\t\2#' | sed 's/\-.*/\-SNAPSHOT/g' | sort -u
trap "rm -f ${temp_output_file}" EXIT

#
