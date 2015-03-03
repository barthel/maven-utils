#!/bin/bash
echo "start"

cat > dependency-pom.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
 <modelVersion>4.0.0</modelVersion>
 <groupId>de.icongmbh.dope</groupId>
 <artifactId>de.icongmbh.dope.dependencies</artifactId>
 <version>4.0.0-SNAPSHOT</version>
 <packaging>pom</packaging>
 <dependencies>
EOF

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
