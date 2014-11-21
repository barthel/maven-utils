#!/bin/bash
echo "start"

echo '<?xml version="1.0" encoding="UTF-8"?>' > dependency-pom.xml
echo '<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> dependency-pom.xml
echo '  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">' >> dependency-pom.xml
echo ' ' >> dependency-pom.xml
echo ' <modelVersion>4.0.0</modelVersion>' >> dependency-pom.xml
echo ' ' >> dependency-pom.xml
echo ' <groupId>de.icongmbh.dope</groupId>' >> dependency-pom.xml
echo ' <artifactId>de.icongmbh.dope.dependencies</artifactId>' >> dependency-pom.xml
echo ' <version>4.0.0-SNAPSHOT</version>' >> dependency-pom.xml
echo ' <packaging>pom</packaging>' >> dependency-pom.xml
echo ' ' >> dependency-pom.xml
echo ' <dependencies>' >> dependency-pom.xml

POM_LIST=`find . -mindepth 2 -maxdepth 2 -iname pom.xml`

for i in $POM_LIST;
do

  echo "working on: $i"

# may use: grep --color=never -oPm1 "(?<=<${tagName}>)[^<]+"
  GROUP_ID=`mvn help:evaluate -f $i -Dexpression=project.groupId | grep -Ev '(^\[|Download\w+:)'`
  ARTIFACT_ID=`mvn help:evaluate -f $i -Dexpression=project.artifactId | grep -Ev '(^\[|Download\w+:)'`
  VERSION=`mvn help:evaluate -f $i -Dexpression=project.version | grep -Ev '(^\[|Download\w+:)'`
  TYPE=`mvn help:evaluate -f $i -Dexpression=project.packaging | grep -Ev '(^\[|Download\w+:)'`

  echo "  <dependency>\n   <groupId>$GROUP_ID</groupId>\n   <artifactId>$ARTIFACT_ID</artifactId>\n   <version>$VERSION</version>\n   <type>$TYPE</type>\n  </dependency>" >> dependency-pom.xml
done

echo ' </dependencies>' >> dependency-pom.xml
echo '</project>' >> dependency-pom.xml

echo "done"
