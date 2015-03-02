#!/bin/bash
# Deploy all *-sources.jar files located in export directory into Maven Repository defined by URL.

set -m
#set -x
# commands
grep_cmd="grep --color=never -E "

# required
base_directory="$(readlink -f $(pwd))/"
export_directory="$(readlink -f ${base_directory}./export/)"

maven_repository_id="distribution-icon-development-releases"
maven_repository_url="http://archiva.icongmbh.de/archiva/repository/icon-development-releases/"

for jar in $(find ${export_directory} -name *-sources.jar)
do
  echo ${jar}
  path=$(dirname ${jar})
  pom_path=$(dirname ${path})
  filename="${jar##*\/}"
  if [ -e "${pom_path}/./pom.xml" ]
  then
    pom_file="${pom_path}/./pom.xml"
    groupId=$(mvn help:evaluate -f ${pom_file} -Dexpression=project.groupId | grep --color=never -Ev '(^\[|WARNING|Download\w+:)')
    artifactId=$(mvn help:evaluate -f ${pom_file} -Dexpression=project.artifactId | grep --color=never -Ev '(^\[|WARNING|Download\w+:)')
    version=$(mvn help:evaluate -f ${pom_file} -Dexpression=project.version | grep --color=never -Ev '(^\[|WARNING|Download\w+:)')
    echo -n "Deploy: ${groupId}:${artifactId}:jar:sources:${version} "
    mvn -q -Dfile=${jar} deploy:deploy-file -DrepositoryId=${maven_repository_id} -Durl=${maven_repository_url} -DgeneratePom=false -DartifactId=${artifactId} -DgroupId=${groupId} -Dpackaging=jar -Dclassifier=sources -Dversion=${version} -DupdateReleaseInfo=true 2>&1 | ${grep_cmd} "[ERROR] Failed to execute goal"
    echo ""
  fi
done
