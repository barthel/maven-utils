# Bulk change of dependency artifact version

The main intention of scripts with the name prefix `set-dependency-version` is to change the version of a dependency artifact in a bulk.

The most of these provided scripts are working on [Apache Maven][maven]¹ [POM][maven-pom] files.
Additionally, for Eclipse RCP development, there are more interesting files which has to manipulate too.
These files are a bunch of XML and non-XML files which have to manipulate easy.

These scripts are not using [Apache Maven][maven]¹, rather they based on search-and-replace pattern in specific files (`pom.xml`, `MANIFEST.MF` ...).

[ShellCheck][shellcheck]³ must be configured with the extended option [`-x`][SC1091]⁴ to validate these scripts correctly.

And, YES, I know that manipulating XML files with [GNU core-utils][core-utils]⁵ like `sed` and `awk` is not recommended to use.
I'll take a deeper look on [`xml-coreutils`][xml-coreutils] or [`XMLStarlet`][xmlstarlet].

## Requirements

Used command line tools:

* `grep`
* `xargs`
* `sed`
* `awk`

### `set-dependency-version.sh`

Replaces the version of a artifact in any kind of file.

This script executes all scripts with the file name pattern:
`set-dependency-version-in*.sh`

#### Usage

`set-dependency-version.sh "my.artifactId" "47.11.0"`

`set-dependency-version.sh "my.artifactId" "0.8.15-SNAPSHOT"`

### `set-dependency-version-in-all-feature.sh`

Replaces the version in Eclipse RCP `feature.xml` file where the entries following the pattern:

```xml
    <plugin
          id="my.artifactId"
          download-size="0"
          install-size="0"
          version="1.0.0-SNAPSHOT"
          unpack="false"/>
```

Locates transitively all feature.xml files in the current directory.
In each found feature.xml file will the entry,  matches the pattern:

```xml
    <plugin
          id="[artifactId]"
          download-size="0"
          install-size="0"
          version="[old_version]"
          unpack="false"/>
```

, modify to replace the `[old_version]` with the given new version argument.

#### `feature.xml` file example

1. `feature.xml` file before modification:

```ini
    [...]
    <plugin
          id="my.artifactId"
          download-size="0"
          install-size="0"
          version="1.0.0-SNAPSHOT"
          unpack="false"/>
    [...]
```

2a. `feature.xml` file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"

```ini
    [...]
    <plugin
          id="my.artifactId"
          download-size="0"
          install-size="0"
          version="47.11.0.qualifier"
          unpack="false"/>
    [...]
```

2b. `feature.xml` file after executing this script with parameter "my.artifactId" "47.11.0"

```ini
    [...]
    <plugin
          id="my.artifactId"
          download-size="0"
          install-size="0"
          version="47.11.0"
          unpack="false"/>
    [...]
```

#### Usage

`set-dependency-version-in-all-feature.sh "my.artifactId" "47.11.0"`

`set-dependency-version-in-all-feature.sh "my.artifactId" "0.8.15-SNAPSHOT"`

### `set-dependency-version-in-all-manifests.sh`

Replaces the version in MANIFEST-file, with a OSGI header _Require-Bundle_, where the entries following the pattern:
`[artifactId];bundle-version="[version number or version range]"`

Locates transitively all MANIFEST-files (MANIFEST.MF) in the current directory.
In each found MANIFEST-file will the entry,  matches the pattern:
`[artifactId];bundle-version="[old_version]"`
, modify to replace the `[old_version]` with the given new version argument.

#### MANIFEST-file example

1. MANIFEST-file before modification:

```ini
[...]
Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
 my.artifactId;bundle-version="[0.8.15,0.8.15]",
[...]
```

2a. MANIFEST-file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"

```ini
[...]
Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
 my.artifactId;bundle-version="47.11.0",
[...]
```

2b. MANIFEST-file after executing this script with parameter "my.artifactId" "47.11.0"

```ini
[...]
Require-Bundle: org.eclipse.osgi;bundle-version="3.10.102",
 my.artifactId;bundle-version="[47.11.0,47.11.0]",
[...]
```

#### Usage

`set-dependency-version-in-all-manifests.sh "my.artifactId" "47.11.0"`

`set-dependency-version-in-all-manifests.sh "my.artifactId" "0.8.15-SNAPSHOT"`

### `set-dependencies-in-all-p2-maven-plugin-poms.sh`

Replaces version in Apache Maven¹ POM-file wich use the _p2-maven-plugin_², where the dependency definition following the pattern:
`<id>group.id:[artifactId]:[version number]</id>`

 Locates transitively all POM-files (pom.xml) in the current directory.
Checks in each found POM-file the present of the _p2-maven-plugin_² configuration.

In each POM-file will the `<id>`-element, where the element matches the pattern:
`<id>group.id:[artifactId]:[old_version]</id>`
, modify to replace the `[old_version]` with the given new version argument.

#### Non-SNAPSHOT version

The non-SNAPSHOT version will be replaced.

If there is a SNAPSHOT version available in this script the given next version will be set or the next patch version will be generated and used.

#### SNAPSHOT version

Only the SNAPSHOT version will be replaced.

#### POM-file example

1. POM-file before modification:

```xml
    [...]
    <plugin>
      <groupId>org.reficio</groupId>
      <artifactId>p2-maven-plugin</artifactId>
    [...]
            <configuration>
    [...]
              <artifacts>
                <artifact>
                  <id>group.id:artifactId:0.8.15</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
                <artifact>
                  <id>group.id:artifactId:0.8.16-SNAPSHOT</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
```

2a. POM-file after executing this script with parameter "artifactId" "47.11.0-SNAPSHOT"

```xml
    [...]
    <plugin>
      <groupId>org.reficio</groupId>
      <artifactId>p2-maven-plugin</artifactId>
    [...]
            <configuration>
    [...]
              <artifacts>
                <artifact>
                  <id>group.id:artifactId:0.8.15</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
                <artifact>
                  <id>group.id:artifactId:47.11.0-SNAPSHOT</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
```

2b. POM-file after executing this script with parameter "artifactId" "47.11.0"

```xml
    [...]
    <plugin>
      <groupId>org.reficio</groupId>
      <artifactId>p2-maven-plugin</artifactId>
    [...]
            <configuration>
    [...]
              <artifacts>
                <artifact>
                  <id>group.id:artifactId:47.11.0</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
                <artifact>
                  <id>group.id:artifactId:47.11.1-SNAPSHOT</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
```

2c. POM-file after executing this script with parameter "artifactId" "47.11.0" "48.0.0-SNAPSHOT"

```xml
    [...]
    <plugin>
      <groupId>org.reficio</groupId>
      <artifactId>p2-maven-plugin</artifactId>
    [...]
            <configuration>
    [...]
              <artifacts>
                <artifact>
                  <id>group.id:artifactId:47.11.0</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
                <artifact>
                  <id>group.id:artifactId:48.0.0-SNAPSHOT</id>
                  <transitive>false</transitive>
                </artifact>
    [...]
```

#### Usage

`set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0-SNAPSHOT"`

`set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0"`

`set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0" "48.0.0-SNAPSHOT"`

### `set-dependencies-in-all-poms-one-pattern.sh`

Replaces version in Maven POM-file property entries following the only one pattern:
`<[artifactId].version>[version number]</[artifactId].version>`.

 Locates transitively all POM-files (pom.xml) in the current directory.
 In each found POM-file will the `<properties>` chield element, where the element matches the only one pattern:
`<[artifactId].version>[old version]</[artifactId].version>`
, modify to replace the [old_version] with the given new version argument.

#### POM-file example

1. POM-file before modification:

```xml
    [...]
    <properties>
      <my.artifactId.version>0.8.15<my.artifactId.version>
    </properties>
    [...]
```

2a. POM-file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"

```xml
    [...]
    <properties>
      <my.artifactId.version>47.11.0-SNAPSHOT<my.artifactId.version>
    </properties>
    [...]
```

2b. POM-file after executing this script with parameter "my.artifactId" "47.11.0"

```xml
    [...]
    <properties>
      <my.artifactId.version>47.11.0<my.artifactId.version>
    </properties>
    [...]
```

#### Usage

`set-dependencies-in-all-poms-one-pattern.sh "my.artifactId" "47.11.0-SNAPSHOT"`

`set-dependencies-in-all-poms-one-pattern.sh "my.artifactId" "47.11.0"`

### `set-dependencies-in-all-poms-two-pattern.sh`

Replaces version in Maven POM-file property entries following these two patterns:

* `<[artifactId].version.release>[version number]</[artifactId].version.release>`
* `<[artifactId].version.snapshot>[next version number]</[artifactId].version.snapshot>`
  
Locates transitively all POM-files (pom.xml) in the current directory.
In each found POM-file will the `<properties>` chield element, where the element matches these two patterns above, modify to replace the `[version number]` with the given new version argument and the `[next version number]` with the third passed (`["NEXT_VERSION"]`) argument or with with the next generated patch version.

#### POM-file example

1. POM-file before modification:

```xml
    [...]
    <properties>
      <artifactId.version.release>0.8.15<artifactId.version.release>
      <artifactId.version.snapshot>0.8.16-SNAPSHOT<artifactId.version.snapshot>
    </properties>
    [...]
```

2a. POM-file after executing this script with parameter "artifactId" "47.11.0"

```xml
    [...]
    <properties>
      <artifactId.version.release>47.11.0<artifactId.version.release>
      <artifactId.version.snapshot>47.11.1-SNAPSHOT<artifactId.version.snapshot>
    </properties>
    [...]
```

2b. POM-file after executing this script with parameter "artifactId" "47.11.0" "48.0.0-SNAPSHOT"

```xml
    [...]
    <properties>
      <artifactId.version.release>47.11.0<artifactId.version.release>
      <artifactId.version.snapshot>48.0.0-SNAPSHOT<artifactId.version.snapshot>
    </properties>
    [...]
```

2c. POM-file after executing this script with parameter "artifactId" "48.0.0-SNAPSHOT"

```xml
    [...]
    <properties>
      <artifactId.version.release>47.11.0<artifactId.version.release>
      <artifactId.version.snapshot>48.0.0-SNAPSHOT<artifactId.version.snapshot>
    </properties>
    [...]
```

#### Usage

`set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0-SNAPSHOT"`

`set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0"`

`set-dependencies-in-all-p2-maven-plugin-poms.sh "artifactId" "47.11.0" "48.0.0-SNAPSHOT"`

## ShellCheck

## Links

* ¹ [Apache Maven][maven]
* ² [p2-maven-plugin][p2-maven-plugin]
* ³ [ShellCheck][shellcheck]
* ⁴ [ShellCheck directive SC1091][SC1091]
* ⁵ [GNU core-utils][core-utils]

[maven]:https://maven.apache.org
[p2-maven-plugin]:https://github.com/reficio/p2-maven-plugin
[shellcheck]:https://www.shellcheck.net
[SC1091]:https://github.com/koalaman/shellcheck/wiki/SC1091
[maven-pom]:https://maven.apache.org/pom.html#What_is_the_POM
[xml-coreutils]:http://xml-coreutils.sourceforge.net/introduction.html
[core-utils]:https://www.gnu.org/software/coreutils/manual/coreutils.html
[xmlstarlet]:http://xmlstar.sourceforge.net/
