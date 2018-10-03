# Bulk change of the parent artifact version

The main intention of this script is to change the version of the parent artifact in a bulk of [Apache Maven][maven]¹ [POM][maven-pom] files.

This script is working on [Apache Maven][maven]¹ [POM][maven-pom] files but not using [Apache Maven][maven]¹, rather this based on search-and-replace pattern.

[ShellCheck][shellcheck]³ must be configured with the extended option [`-x`][SC1091]⁴ to validate this script correctly.

And, YES, I know that manipulating XML files with [GNU core-utils][core-utils]⁵ like `sed` and `awk` is not recommended to use.
I'll take a deeper look on [`xml-coreutils`][xml-coreutils] or [`XMLStarlet`][xmlstarlet].

## Requirements

Used command line tools:

* `grep`
* `xargs`
* `sed`
* `awk`

### `set-parent-version-in-all-poms.sh`

Replaces the version of the parent artifact in any kind of [POM][maven-pom]-file.

```xml
    <parent>
        <groupId>my.groupId</groupId>
        <artifactId>my.artifactId</artifactId>
        <version>0.8.15-SNAPSHOT</version>
    </parent>
```

Locates transitively all [POM][maven-pom]-files in the current directory.
In each found [POM][maven-pom]-file will the entry,  matches the pattern:

```xml
    <parent>
        <groupId>[groupId]</groupId>
        <artifactId>[artifactId]</artifactId>
        <version>[old_version]</version>
    </parent>
```

, modify to replace the `[old_version]` with the given new version argument.

#### [POM][maven-pom]-file example

1. `pom.xml` file before modification:

```xml
    [...]
    <parent>
        <groupId>my.groupId</groupId>
        <artifactId>my.artifactId</artifactId>
        <version>0.8.15-SNAPSHOT</version>
    </parent>
    [...]
```

2a. `pom.xml` file after executing this script with parameter "my.artifactId" "47.11.0-SNAPSHOT"

```xml
    [...]
    <parent>
        <groupId>my.groupId</groupId>
        <artifactId>my.artifactId</artifactId>
        <version>47.11.0-SNAPSHOT</version>
    </parent>
    [...]
```

2b. `pom.xml` file after executing this script with parameter "my.artifactId" "47.11.0"

```xml
    [...]
    <parent>
        <groupId>my.groupId</groupId>
        <artifactId>my.artifactId</artifactId>
        <version>47.11.0</version>
    </parent>
    [...]
```

#### Usage

```bash
set-parent-version-in-all-poms.sh "my.artifactId" "47.11.0"
```

```bash
set-parent-version-in-all-poms.sh "my.artifactId" "0.8.15-SNAPSHOT"
```

## ShellCheck

## Links

* ¹ [Apache Maven][maven]
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
