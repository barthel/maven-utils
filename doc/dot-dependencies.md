# Create [Graphviz DOT][graphviz-dot]² (graph description language) file of all dependencies

## Requirements

Used command line tools:

### `dot-dependencies-of-all-poms.sh`

#### [POM][maven-pom]-file example

#### Usage

```bash
dot-dependencies-of-all-poms.sh
```

```bash
dot-dependencies-of-all-poms.sh  -m -a `find . -iname pom.xml -exec grep -H -v "<modules>" {} \; | grep -v target | cut -d':' -f1 | sort | uniq`
```

### `dot-dependencies-of-all-osgi-services.sh`

#### [POM][maven-pom]-file example

#### Usage

```bash
dot-dependencies-of-all-osgi-services.sh
```

```bash
dot-dependencies-of-all-osgi-services.sh `find . -ipath \*/OSGI-INF/\*.xml -exec grep -wl "http://www.osgi.org/xmlns/scr/v1" {} \;`
```

## ShellCheck

## Links

* ¹ [Apache Maven][maven]
* ² [Graphviz DOT][graphviz-dot]
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
[graphviz-dot]:https://graphviz.gitlab.io/_pages/doc/info/lang.html
