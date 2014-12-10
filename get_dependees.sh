#!/bin/bash

# Get dependees of the passed pom.xml (maven) file.
#
# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html

# set -x
set -m

required_helper=('mvn' 'tempfile' 'xargs' 'grep' 'sed' 'sort' 'wget')
input_file='pom.xml'

archiva_url="http://archiva.icongmbh.de/archiva/browse"

show_help() {
cat << EOF

Usage: ${0##*/} [-f POM_FILE] [-a ARTIFACTID -g GROUPID -v VERSION]
Get dependees of pom.xml (maven) provided by POM_FILE.

With no POM_FILE the default '$input_file' will be used.
    
    -a ARTIFACTID   the artifact id.
    -f POM_FILE     the pom.xml file.
    -g GROUPID      the artifact groupId.
    -v VERSION      the artifact version.
    
Example:  ${0##*/} -f pom.xml
          ${0##*/} -g my.groupId -a my.artifactId -v 4.7.11
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
while getopts "a:f:g:h?v:" opt;
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
      v)  version="$OPTARG"
      ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift;

if [[ -z "${groupId}" && -z "${artifactId}" && -z "${version}" && -f "${input_file}" ]]
  then
    groupId=`mvn help:evaluate -f ${input_file} -Dexpression=project.groupId | grep -Ev '(^\[|Download\w+:)'`
    artifactId=`mvn help:evaluate -f ${input_file} -Dexpression=project.artifactId | grep -Ev '(^\[|Download\w+:)'`
    version=`mvn help:evaluate -f ${input_file} -Dexpression=project.version | grep -Ev '(^\[|Download\w+:)'`
fi

[ -z "${groupId}" ] && echo "The groupId is required." && exit 1 || true
[ -z "${artifactId}" ] && echo "The artifactId is required." && exit 1 || true
[ -z "${version}" ] && echo "The version is required." && exit 1 || true

echo -n -e "Get dependees for artifact: ${groupId}/${artifactId} ${version}\n\n"
# temp. working file for collect the mvn output
temp_output_file=`tempfile -p"${0##*/}"`

wget -nv -q --no-proxy -O ${temp_output_file} ${archiva_url}/${groupId}/${artifactId}/${version}/usedby

grep -A 4 -B 2 "<strong>Version(s):</strong>" ${temp_output_file} | grep -v "<strong>Version(s):</strong>" | xargs | \
  sed -e 's/\-\-/\n/g' | sed -r 's#^.*<a href=[^"]+>([^<]+)</a>.*<a href=[^"]+>([^<]+)</a>.*$#\1\t\2#' | sed 's/\-.*/\-SNAPSHOT/g' | sort -u
trap "rm -f ${temp_output_file}" EXIT