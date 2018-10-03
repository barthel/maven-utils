# maven-utils

Helper scripts around [Apache Maven][maven]¹ usage.

All these scripts are *NOT* speed optimized!
I'm using these scripts often in my daily work, and they do what they have to do.

A file located in `lib/` and/or the file name starts with a `_` is primarily for used to include (source) into other scripts. These files providing global re-usable functions and should not be executed directly.

More and deeper documentation could be found in [`doc/`](./doc/).

And, YES, I know that manipulating XML files with [GNU core-utils][core-utils]⁵ like `sed` and `awk` is not recommended to use.
I'll take a deeper look on [`xml-coreutils`][xml-coreutils] or [`XMLStarlet`][xmlstarlet].

## 1. Requirements

Most of these scripts are requires UNIX/Linux standard tools and commands like:

* [GNU core-utils][core-utils]⁵
* [GNU bash][bash]⁶

All scripts are daily used with `GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin17)` on macOS High Sierra and also tested with:

* `GNU bash, Version 4.4.12(3)-release (x86_64-unknown-cygwin)` on [_Cygwin_ 2.11.1][cygwin]
* `GNU bash, version 4.4.19(2)-release (x86_64-pc-msys)` on [_Git for Windows_ 2.18.0][git-bash]

Each script checks the required tools and exits with an error if a required tool is not available.
Please check the script documentation for additional and/or deviating requirements.

## 2. Install and Usage

Clone this repository and add it to your `PATH` environment variable.

Most of these scripts has a _help_-option (`-h`, `-?`), a _quiet_-option (`-q`) and a multi-level _verbose_-option (`-vv...`).

The _usage_ information will be displayed if a script will execute without any arguments or with a help-option (`-h`, `-?`).

## 3. [Bulk change of dependency artifact version](./doc/set-dependency-version.md "doc/set-dependency-version.md")

The main intention of scripts with the name prefix `set-dependency-version` is to change the artifact version in a bulk.

The most of these provided scripts are working on [Apache Maven][maven]¹ [POM][maven-pom] files.
Additionally, for Eclipse RCP development, there are more interesting files which has to manipulate too.
These files are a bunch of XML and non-XML files which have to manipulate easy.

These scripts are not using [Apache Maven][maven]¹, rather they based on search-and-replace pattern in specific files (`pom.xml`, `MANIFEST.MF` ...).

See [here](./doc/set-dependency-version.md "doc/set-dependency-version.md") for more information about this kind of scripts.

## 4. [Bulk change of the parent artifact version](./doc/set-parent-version.md "doc/set-parent-version.md")

The main intention of this script is to change the version of the parent artifact in a bulk of [Apache Maven][maven]¹ [POM][maven-pom] files.

See [here](./doc/set-parent-version.md "doc/set-parent-version.md") for more information about this script.

## 5. Maven Pull Request Validator

The Maven Pull Request Validate script (`maven-pr-validator.sh`) based — with small modification — on a script by [@jvanzyl][jvanzyl] and the original script could be found at his [*GitHub*Gist][maven-pr-validator].

> This script will checkout Maven, apply a PR, build the Maven distribution and run the Maven integration tests against the just-built distribution. If you successfully get to the end of this script then your PR is ready to be reviewed.

## 6. ShellCheck

[ShellCheck][shellcheck]³ is a static analysis tool for shell scripts and I'm use it to check my scripts and try to prevent pitfalls.
[ShellCheck][shellcheck]³ must be configured with the extended option [`-x`][SC1091] to validate these scripts correctly.

## 7. License

All these scripts, expect `maven-pr-validator.sh`, are licensed under the [Apache License, Version 2.0][apl]⁴.
A copy of this license could be also found in the `LICENSE` file.

```bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (c) barthel <barthel@users.noreply.github.com> https://github.com/barthel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

The Maven Pull Request Validate script (`maven-pr-validator.sh`) based — with small modification — on a script by [@jvanzyl][jvanzyl] and the original script could be found at his [*GitHub*Gist][maven-pr-validator].

## 8. Attic

The directory `_attic` is the place where the old and not supported scripts will be moved into it. These scripts are not maintained anymore.

## 9. Links

[//]: # "https://unicode-table.com/en/blocks/superscripts-and-subscripts/"

* ¹ [Apache Maven][maven]
* ³ [ShellCheck][shellcheck]
* ⁴ [Apache License, Version 2.0][apl]
* ⁵ [GNU core-utils][core-utils]
* ⁶ [GNU bash][bash]

[maven]:https://maven.apache.org
[maven-pom]:https://maven.apache.org/pom.html#What_is_the_POM
[p2-maven-plugin]:https://github.com/reficio/p2-maven-plugin
[shellcheck]:https://www.shellcheck.net
[SC1091]:https://github.com/koalaman/shellcheck/wiki/SC1091
[apl]:http://www.apache.org/licenses/LICENSE-2.0
[maven-pr-validator]:https://gist.github.com/jvanzyl/16da25976f8ad27293fa
[jvanzyl]:https://github.com/jvanzyl
[core-utils]:https://www.gnu.org/software/coreutils/manual/coreutils.html
[bash]:https://www.gnu.org/software/bash/bash.html
[git-bash]:https://git-scm.com/download/win
[cygwin]:https://cygwin.com/install.html
[xml-coreutils]:http://xml-coreutils.sourceforge.net/introduction.html
[xmlstarlet]:http://xmlstar.sourceforge.net/
