# maven-utils

Helper scripts around [Apache Maven][maven]¹ usage.

All these scripts are *NOT* speed optimized!
I'm using these scripts often in my daily work and they does what they have to do.

File starting with `_` are primarily to include (source) in other scripts. These files providing global re-usable functions and should not be executed directly.

## Install and Usage

Clone this repository and add it to your `PATH` environment variable.

Most of these scripts has a _help_-option (`-h`, `-?`), a _quiet_-option (`-q`) and a multi-level _verbose_-option (`-vv...`).

The _usage_ information will be displayed if a script will executed without any arguments or with a help-option (`-h`, `-?`).

## Bulk change artifact version

The main intention of scripts with the name prefix `set-dependency-version` is to change the artifact version in a bulk.

These scripts are not using Apache Maven¹ itself rather they based on search-and-replace pattern in specific files (`pom.xml`, `MANIFEST.MF` ...).

See [here][set-dependency-version.md] for more information about these kind of scripts.

## ShellCheck

[ShellCheck][shellcheck]³ is a static analysis tool for shell scripts and I'm use it to check my scripts and try to preventing pitfalls.
[ShellCheck][shellcheck]³ must be configured with the extended option [`-x`][SC1091]⁴ to validate these scripts correctly.

## License

All these scripts are licensed under the [Apache License, Version 2.0][apl]⁵.
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

## Links

* ¹ [Apache Maven][maven]
* ³ [ShellCheck][shellcheck]
* ⁴ [ShellCheck directive SC1091][SC1091]
* ⁵ [Apache License, Version 2.0][apl]

[maven]:https://maven.apache.org
[p2-maven-plugin]:https://github.com/reficio/p2-maven-plugin
[shellcheck]:https://www.shellcheck.net
[SC1091]:https://github.com/koalaman/shellcheck/wiki/SC1091
[apl]:http://www.apache.org/licenses/LICENSE-2.0
