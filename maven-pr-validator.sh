#!/bin/sh
# set -x

#
# @see: https://gist.github.com/jvanzyl/16da25976f8ad27293fa
#
# PR validator: This script will checkout Maven, apply a PR, build the Maven distribution and
#               run the Maven integration tests against the just-built distribution. If you
#               successfully get to the end of this script then your PR is ready to be reviewed.

# Assumptions:
# 1) You have a functioning version of Maven installed (script tested with 3.2.1)
# 2) You have a decent connection. This script checks out everything from scratch and downloads
#    everything into a clean local repository. Not terribly efficient but makes sure there is no
#    interference from previous Maven operations.
#
# This really serves as a set of instructions to test your changes. Once you see what's required you
# can setup things as you wish, but this will get you started. I have maven and maven-integration-testing
# in sibling directories and iterate through a process of building Maven, installing the distribution and
# running the integration tests. This really just shows you where all the bits are.
#
# To use use this save it to a file called maven-pr-validator.sh and run it using the PR# like the following:
#
# ./maven-pr-validator 16
#
# For use with a corresponding maven-integration-test PR# like:
# ./maven-pr-validator.sh 70 14
#
pr=$1
repository=https://github.com/apache/maven

itpr=$2
itrepository=https://github.com/apache/maven-integration-testing
[ -z ${pr} ] && echo "You need to provide a PR." && exit
patchUrl=${repository}/pull/${pr}.patch
itPatchUrl=${itrepository}/pull/${itpr}.patch
#patchUrl=https://patch-diff.githubusercontent.com/raw/apache/maven/pull/${pr}.patch
workDirectory=`pwd`/z-maven-with-pr-${pr}
localRepository=${workDirectory}/local-repository
MAVEN_OPTS="-Xms1024m -Xmx1024m"
mvn="mvn -Dmaven.repo.local=${localRepository} -Dremoteresources.skip=true"
mkdir ${workDirectory}
(
  cd ${workDirectory}
  curl -L -s -O ${patchUrl}
  [ $? -ne 0 ] && echo "Retrieving patch file from Github failed." && exit
  if [ ! -z "${itpr}" ]
    then
      curl -L -s -o it-${itpr}.patch ${itPatchUrl}
  fi
  echo "Testing patch..."
  git clone ${repository}
  [ $? -ne 0 ] && echo "Cloning Maven failed." && exit
  git clone ${itrepository}
  [ $? -ne 0 ] && echo "Cloning Maven ITs failed." && exit
  ( 
    cd maven
    # We execute this twice to make sure no download spew ends up in mavenVersion.txt.
    # The -q mode of Maven keeps everything from being emitted, including useful output...
    mavenVersion=`${mvn} help:evaluate -Dexpression=project.version | grep -v "^\["`
    mavenVersion=`${mvn} help:evaluate -Dexpression=project.version | grep -v "^\["`
    echo ${mavenVersion} > ${workDirectory}/mavenVersion.txt
    git am --ignore-space-change --signoff < ../${pr}.patch
    [ $? -ne 0 ] && echo "Applying ${pr}.patch failed." && exit
    ${mvn} clean install
    [ $? -ne 0 ] && echo "Maven clean package failed." && exit
    cd apache-maven/target                                                                                                                                                                               
    tar xvzf apache-maven-${mavenVersion}-bin.tar.gz    
  )
  (
    mavenVersion=`cat ${workDirectory}/mavenVersion.txt`
    echo ${mavenVersion}
    distro=${workDirectory}/maven/apache-maven/target/apache-maven-${mavenVersion}
    M2_HOME=${distro}
    cd maven-integration-testing
    if [ -f "../it-${itpr}.patch" ]
      then
        git am --ignore-space-change --signoff < ../it-${itpr}.patch
        [ $? -ne 0 ] && echo "Applying it-${itpr}.patch failed." && exit¬
    fi
    ${mvn} clean install -Prun-its,embedded -DmavenHome=${distro}
  )
) 

