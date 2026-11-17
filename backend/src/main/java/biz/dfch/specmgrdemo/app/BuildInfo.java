package biz.dfch.specmgrdemo.app;

/**
 * The value of the build (feat-9-walking-skeleton, Phase 200, Task 200.120): the version of the build and the
 * commit of the source of the build. The two values come from the build (the filtered resource
 * build-info.properties, the header comment of backend/pom.xml), and not from a fixed text of the code.
 *
 * @param version the version of the build (the value of the property build.info.version of the pom, 0.1.0)
 * @param commit the commit of the source of the build (the value of the property build.info.commit that the just
 *     recipe replaces with git rev-parse HEAD, the default unknown)
 */
public record BuildInfo(String version, String commit) {}
