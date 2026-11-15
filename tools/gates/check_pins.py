#!/usr/bin/env python3
"""Gate: the pins in the workflows (ACC-013), the lock files of cdxgen and Spectral, the download of oasdiff, and the Python tools.

feat-5-foundation-monorepo-ci, Task 130.142 (REQ-003, REQ-015).
feat-16-cdxgen-lockfile, Task 110.100 (REQ-003, REQ-005).
feat-22-python-tools-lockfile, Task 120.100 (REQ-003, REQ-004).
feat-6-contracts-openapi-pipeline, Task 110.110 (REQ-009): the same check for the lock file of Spectral.
feat-6-contracts-openapi-pipeline, Task 115.100 (REQ-009, ACC-011): the check of the pin of oasdiff.
feat-6-contracts-openapi-pipeline, Task 120.105 (REQ-009, ACC-011, ACC-012): the pin of the generator plugin.
feat-6-contracts-openapi-pipeline, Task 120.110 (REQ-009, ACC-011): the pnpm module frontend/ (Kubb, Zod, TypeScript).

Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions> <project-root> <sbom-tool-dir>
                      <python-lock-dir> <lint-tool-dir> <breaking-tool-dir> <generator-tool-dir>

The script stops for each of these:

  * a `uses:` that is not `<owner>/<name>[/<path>]@<40 hexadecimal characters>` (a tag, a branch,
    a short SHA, a local action `./...`, and `docker://...` are not allowed);
  * a `uses:` with no comment on the same line, or a comment that is not `# <owner>/<name> <tag>`
    (the name is the name of the action, the tag is a release tag such as v7.0.1);
  * an action that is not in <allowed-actions> (the actions of the license table), or whose tag
    or SHA is not the one in this file;
  * a setup action whose version input is missing, is not a text, or is not the same as the
    value in tools/versions.env (see TOOL_INPUTS below);
  * `actions/setup-java` with a distribution that is not `temurin`;
  * a version input of an action that has no entry in TOOL_INPUTS (the gate cannot check it);
  * a `uses:` in the YAML that the text check did not find, or the other way round (this stops
    a form of the YAML that the text check does not read, for example a `uses:` in two lines).

The Maven pin (the finding G1 of the review; REQ-003 wants the same Maven version in CI as in
tools/versions.env, and the repository has no Maven setup action). The Maven Wrapper pins Maven in the
repository, so the script looks in <project-root> (not in .git, node_modules, build, target, and from the
root only .specmgr and the fixtures of the gates; EXCLUDED_* below, the same list as manifest_files in
_lib.sh) and stops for each of these:

  * a `.mvn/wrapper/maven-wrapper.properties` whose `distributionUrl` has no file
    `apache-maven-<MAVEN_VERSION>-bin.zip` (or `.tar.gz`), with MAVEN_VERSION of tools/versions.env;
  * a wrapper with no `distributionSha256Sum` (64 hexadecimal characters). The script cannot compare the
    value with versions.env (the file has the sha512 of the tar.gz), so it checks that the value is there;
  * a project with a `pom.xml` and no wrapper (fail closed: sbom.sh does not use the Maven of the runner).

A project with no `pom.xml` and no wrapper passes, and the script says "no Maven project". A `pom.xml`
with no wrapper stops this gate on purpose. feat-6-contracts-openapi-pipeline (Task 105.100) added backend/pom.xml
and the wrapper.

The lock file of the SBOM tool cdxgen (the finding G2 of the review, feat-16-cdxgen-lockfile; REQ-003, REQ-005).
tools/versions.env is the one source of truth for CDXGEN_VERSION and CDXGEN_INTEGRITY. <sbom-tool-dir> is the
pnpm project tools/sbom/. The check is always on (also if frontend/ does not exist), and it fails closed. The
script stops for each of these:

  * <sbom-tool-dir>, its package.json or its pnpm-lock.yaml is missing, or the folder has a file that pnpm
    could read as a setting (for example `.npmrc`, `pnpm-workspace.yaml`, `.pnpmfile.cjs`): only package.json,
    pnpm-lock.yaml, README.md, node_modules and cyclonedx-maven-plugin.sha256 (the second place of the pin of
    the jar of the SBOM plugin) are allowed (PNPM_TOOL_FILES below);
  * CDXGEN_VERSION is not an exact version (a range, a tag), or CDXGEN_INTEGRITY is not a sha512 value;
  * package.json: it has a key that is not in PACKAGE_JSON_KEYS (this stops devDependencies,
    optionalDependencies, peerDependencies, overrides, `pnpm`, `packageManager` and every other key), its
    `dependencies` is not exactly {"@cyclonedx/cdxgen": CDXGEN_VERSION} (another version, a range, a tag, one
    more dependency), or the file is not JSON, has a key two times, or is not an object;
  * the lock file: it is not exactly one YAML document with no key twice (a `packageManager` in package.json
    adds a second document), `lockfileVersion` is not a text that starts with `9.`, it has a top-level key
    that is not in LOCK_KEYS (for example `overrides`), it has not exactly one importer `.` with exactly one
    direct dependency `@cyclonedx/cdxgen` whose `specifier` and `version` are CDXGEN_VERSION, the entry of
    cdxgen in `packages` is missing or has another integrity value than CDXGEN_INTEGRITY;
  * a package in the lock file with no integrity value, with an integrity value that is not sha256, sha384 or
    sha512, with a `resolution` that has another key than `integrity` (`tarball`, `repo`, `commit`,
    `directory`, `type`: a package from another place than the registry), or with a key that is not
    `<name>@<exact version>`; a `snapshots` entry for a package that is not in `packages`;
  * the file `<sbom-tool-dir>/cyclonedx-maven-plugin.sha256` is missing, has no line, has a line that is not a
    sha256 value, or has a value that is not `CYCLONEDX_MAVEN_PLUGIN_SHA256` (feat-6-contracts-openapi-pipeline,
    the second place of the pin of the jar of the SBOM plugin, as `oasdiff-checksums.txt` is the second place of
    the pin of oasdiff).

The lock file of the OpenAPI linter Spectral (feat-6-contracts-openapi-pipeline, Task 110.110; REQ-009) has the
same check, with the function check_pnpm_tool and the data SPECTRAL: SPECTRAL_VERSION and SPECTRAL_INTEGRITY of
tools/versions.env, the package `@stoplight/spectral-cli`, and <lint-tool-dir> (the pnpm project tools/spectral/).
The messages start with `Lint tool:` and not with `SBOM tool:`. The tree of Spectral is not in the SBOM (rule A:
Spectral does not go to users), but its lock file is checked here.

The check reads the lock file as text with PyYAML (it does not need Node or pnpm), so the job `check-pins` of CI
runs it. The frozen install in sbom.sh does the real check of each tarball against the lock file; this check
ties the lock file to tools/versions.env and stops a lock file that the install would accept but that has a
source that is not the registry. A change of only one of the three places (versions.env, package.json, the
lock file) stops the check.

The pin of the tool for breaking changes oasdiff (feat-6-contracts-openapi-pipeline, Task 115.100; REQ-009, ACC-011).
oasdiff is a binary that the gate downloads (install_oasdiff in _lib.sh), so it has no lock file. tools/versions.env has
OASDIFF_VERSION and OASDIFF_SHA256 (the sha256 of the file oasdiff_<version>_linux_amd64.tar.gz). <breaking-tool-dir> is
tools/breaking/, and it has the file oasdiff-checksums.txt: the file `checksums.txt` of the release of the vendor, without
a change (lines `<sha256>  <file name>`). The vendor file is the second place of the pin. The check is always on, and it
fails closed. The script stops for each of these:

  * OASDIFF_VERSION is missing or is not an exact version, or OASDIFF_SHA256 is missing or is not 64 lower case
    hexadecimal characters;
  * <breaking-tool-dir> or the file oasdiff-checksums.txt is missing, or a line of the file is not
    `<sha256 value>  <file name>`;
  * the file has no line for oasdiff_<OASDIFF_VERSION>_linux_amd64.tar.gz, has more than one such line, or the sha256 of
    the line is not OASDIFF_SHA256.

A change of only one of the two places (versions.env, oasdiff-checksums.txt) stops the check. The real check of the
download is in install_oasdiff (the sha256 of the file against OASDIFF_SHA256, before the file is unpacked).

The pin of the generator plugin openapi-generator-maven-plugin (feat-6-contracts-openapi-pipeline, Task 120.105; REQ-009,
ACC-011, ACC-012). The plugin is a Maven plugin, so its version is in a pom.xml, and tools/versions.env has the same version
(OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION) and the sha256 of its jar (OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256). The sha256 is
compared with the jar in the local Maven repository at run time (verify_generator_plugin in _lib.sh; the dependencies of the
plugin are not checked, GitHub issue #23). This check is always on. The script looks at each pom.xml in <project-root> (the
same folders as the Maven check) and stops for each of these:

  * OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION is missing or is not an exact version, or the sha256 is missing or is not 64 lower
    case hexadecimal characters;
  * a pom.xml has the plugin `org.openapitools:openapi-generator-maven-plugin` with a version that is not
    OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION (the version can be a `${property}` of the same pom.xml), with no version, or with
    a version that this script cannot resolve;
  * a pom.xml cannot be read as XML;
  * the file `<generator-tool-dir>/openapi-generator-maven-plugin.sha256` is missing, has no line, has a line
    that is not a sha256 value, or has a value that is not OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256 (the second
    place of the pin of the jar, as `oasdiff-checksums.txt` is the second place of the pin of oasdiff).

A pom.xml with no such plugin is no problem for this check. A change of only one of the two places (versions.env,
pom.xml) stops the check for the version, and a change of only one of the two places (versions.env, the
`openapi-generator-maven-plugin.sha256` file) stops the check for the sha256 of the jar. The real check of the
jar is in verify_generator_plugin (the sha256 of the jar in the local Maven repository against versions.env and
against the file, before the plugin generates).

The pnpm module frontend/ (feat-6-contracts-openapi-pipeline, Task 120.110; REQ-009, ACC-011; the test tools of
feat-7-verification-architecture-tools, Phase 110, the mutation tool Stryker, Phase 120, and the architecture tool
ArchUniTS, Phase 130; the coverage provider @vitest/coverage-v8, Phase 140): the Zod generator Kubb,
Zod and TypeScript, the test tools Vitest, Playwright (@playwright/test), axe-core, fast-check and Vite (the pin of
the peer that vitest and the tree of Kubb take as a dependency or a peer; without the pin, the resolution of pnpm
brings the tree of vite 8 with the package lightningcss, MPL-2.0, not in the permitted list), and the mutation tool
Stryker (the package @stryker-mutator/core, the stryker binary, and the plugin @stryker-mutator/vitest-runner that
runs Vitest as the test runner; the peer of the plugin is vitest >=2.0.0). <project-root>/frontend has package.json,
pnpm-workspace.yaml and pnpm-lock.yaml. The module has fifteen direct packages (FRONTEND_PACKAGES below), each with
a version key and an integrity key in tools/versions.env. The check is on if the folder has one of the three files (a
folder with none of them is "no pnpm module"), and it fails closed. The script stops for each of these:

  * a key of FRONTEND_PACKAGES is missing in tools/versions.env, a version is not an exact version, or an integrity value is
    not a sha512 value of npm;
  * the folder has a file that could change where pnpm gets the packages (`.npmrc`, `.pnpmfile.cjs`, `.pnpmfile.mjs`,
    `pnpmfile.cjs`, `.yarnrc`, `.yarnrc.yml`, `yarn.lock`, `package-lock.json`, `bunfig.toml`), or one of the three files is missing;
  * pnpm-workspace.yaml is not exactly `packages: ["."]` (a key such as `overrides`, `catalog` or `registry` changes the install);
  * package.json has a key that is not in FRONTEND_PACKAGE_JSON_KEYS (this stops optionalDependencies, peerDependencies,
    overrides, `pnpm` and `packageManager`), its `dependencies` is not exactly Zod in the exact version of versions.env, or
    its `devDependencies` is not exactly the other fourteen packages in the exact versions of versions.env;
  * the lock file: the same checks as for the lock file of cdxgen (one YAML document, no key twice, `lockfileVersion` 9.x,
    only the known top-level keys, an integrity value for each package and no source other than the registry), the importer `.`
    does not have each of the fifteen packages with `specifier` and `version` as in versions.env (the version can have a suffix in
    brackets for the peer dependencies), or `packages` has no entry of a package in that version with the integrity value of
    versions.env.

A change of only one of the three places (versions.env, package.json, the lock file) stops the check. The install itself
(install_frontend in _lib.sh: `pnpm install --frozen-lockfile --ignore-scripts`) compares each tarball with the lock file.

The tie of the transitive package caniuse-lite (feat-7-verification-architecture-tools, Phase 120; REQ-002, ACC-011): the
package is in the tree of Stryker of the pnpm module (the chain @stryker-mutator/core -> @stryker-mutator/instrumenter ->
@babel/core -> @babel/helper-compilation-targets -> browserslist -> caniuse-lite), and its license CC-BY-4.0 is not in
tools/license/permitted-licenses.txt (no class in DEC 84c37f7d-08cb-457d-8ab3-1db37dba9bc9; the deviation is in the
register DEC 93a6d588-e002-4daf-9a47-45e2d77786e9, the section of 2026-11-11). The rule X1 of sbom.sh keeps the pinned
version out of the SBOM of the frontend, so <project-root>/frontend/pnpm-lock.yaml must resolve caniuse-lite to exactly
CANIUSE_LITE_VERSION of tools/versions.env. The check is on if the lock file exists (a folder with no lock file is "no
pnpm module", as for the frontend check), and it fails closed. The script stops for each of these:

  * CANIUSE_LITE_VERSION is missing in tools/versions.env, or the version is not an exact version;
  * the lock file cannot be read as YAML (one document, no key twice), or it has no `packages`;
  * `packages` has no caniuse-lite, or it has caniuse-lite with another version than CANIUSE_LITE_VERSION (or more than
    one version of the package).

A change of only one of the two places (versions.env, the lock file) stops the check. The package is transitive, so it has
no entry in frontend/package.json and no integrity key.

The test tools of the Maven module (feat-7-verification-architecture-tools, Phase 110, 120, 130 and 140; REQ-001,
REQ-002, REQ-003, ACC-011): JUnit, Testcontainers (the core, the JUnit module and the PostgreSQL module), the JDBC driver, jqwik,
the test runner maven-surefire-plugin, the mutation tool PIT (the plugin org.pitest:pitest-maven and its plugin
dependency org.pitest:pitest-junit5-plugin, the JUnit5 support of PIT), and the architecture tools Spring Modulith (the
artifact org.springframework.modulith:spring-modulith-core and the jar org.springframework.boot:spring-boot that the
code of Spring Modulith 1.4.14 needs for the module detection), ArchUnit (the artifacts com.tngtech.archunit:archunit
and com.tngtech.archunit:archunit-junit5), the reader of the workspace structurizr-client
(com.structurizr:structurizr-client) and the coverage tool JaCoCo (the plugin org.jacoco:jacoco-maven-plugin,
Phase 140). <project-root>/backend has the pom.xml with the test tools in <scope>test</scope>
(the cyclonedx plugin keeps the test scope out of the SBOM; the plugin and the plugin dependency are in <build><plugins>
and have no scope). tools/versions.env has the version of each tool (MAVEN_TEST_DEPENDENCIES and MAVEN_TEST_PLUGINS
below). The check is always on, and it fails closed. The script stops for each of these:

  * a key of MAVEN_TEST_DEPENDENCIES or MAVEN_TEST_PLUGINS is missing in tools/versions.env, or the version is not an
    exact version;
  * a pom.xml has one of the test dependencies (or the plugin) with a version that is not the version of
    tools/versions.env (the version can be a `${property}` of the same pom.xml), with no version, or with a version
    that this script cannot resolve;
  * a test dependency in the direct `<dependencies>` section of a pom.xml has a `<scope>` that is not `test`, or has
    no `<scope>` at all (the default of Maven is `compile`): the test tools must stay out of the SBOM (the cyclonedx
    plugin has `includeTestScope`, the default false). A plugin dependency (for example pitest-junit5-plugin, the
    JUnit5 support of PIT, in `<build><plugins>`) has no scope and is no problem;
  * a pom.xml cannot be read as XML.

A pom.xml without the test tools is no problem for this check (as for the generator plugin). A change of only one of
the two places (versions.env, pom.xml) stops the check.

The lock files of the Python tools (the finding G2 of the review, feat-22-python-tools-lockfile; REQ-003, REQ-004).
<python-lock-dir> is tools/python/. It has one lock file for each tool (PYTHON_LOCKS below), and no other lock
file. The check is always on, and it fails closed. The script reads each lock file as text (it does not start uv
and does not make the file again, so the result does not depend on the version of uv). It stops for each of these:

  * the folder or a lock file is missing, the folder has a file that is not in PYTHON_LOCK_FILES, or a lock file has
    no package;
  * a line of a lock file that is not a comment, an empty line or an entry `name==version` (with an optional
    marker after ` ; `) that has one or more `--hash=sha256:<64 hexadecimal characters>` values. This stops a
    package with no hash, a range or an unpinned package, a URL (`name @ https://...`), a path, `git+...`, `-e`, and an
    option such as `--index-url`, `--extra-index-url`, `--find-links` and `--no-binary` (a line that continues with
    a backslash is one entry);
  * the version of the tool (`SPECMGR_VERSION`, `PYYAML_VERSION`, `LICENSE_EXPRESSION_VERSION`) is missing in
    tools/versions.env or is not an exact version, or the lock file has no entry of the tool or an entry with
    another version (the name is compared after the normalization of PEP 503).

A change of only one of the two places (versions.env, the lock file) stops the check. The install itself checks
each file against the hashes (make_python_env in _lib.sh); this check ties the lock file to tools/versions.env and
stops a lock file that has a source that is not an exact pin with hashes.

The comment is not in the YAML data, so the script reads the lines of the file for the comment,
and the YAML data for the inputs. Exit codes: 0 pass; 1 a pin is not correct; 2 an error in a file (versions.env or a workflow).
"""

import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
from typing import Any, NamedTuple

import yaml
from _workflow import GateError, iter_jobs, iter_steps, load_workflows

# The setup actions: the input with the version of the tool, and the key in tools/versions.env.
TOOL_INPUTS: dict[str, dict[str, str]] = {
    "actions/setup-java": {"java-version": "JDK_VERSION"},
    "actions/setup-node": {"node-version": "NODE_VERSION"},
    "pnpm/action-setup": {"version": "PNPM_VERSION"},
    "astral-sh/setup-uv": {"version": "UV_VERSION"},
    "extractions/setup-just": {"just-version": "JUST_VERSION"},
}
# Other inputs that must have a fixed value.
FIXED_INPUTS: dict[str, dict[str, str]] = {"actions/setup-java": {"distribution": "temurin"}}

USES_LINE = re.compile(r"^\s*(?:-\s+)?uses:\s*(\S+)[ \t]*(?:#(.*))?$")
USES_VALUE = re.compile(
    r"(?P<name>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)(?P<path>(?:/[A-Za-z0-9_./-]+)?)@(?P<sha>[0-9a-f]{40})"
)
COMMENT = re.compile(r"\s*(?P<name>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+) (?P<tag>v[0-9]+(?:\.[0-9]+){0,2})\s*")
VERSION_KEY = re.compile(r"(^|[-_])version([-_]|$)", re.IGNORECASE)

# The folders that the search for pom.xml and for the wrapper does not enter (see the header). The names
# are at each level; the paths are relative to the project root. manifest_files in _lib.sh has the same list.
# manifest_files also does not list tools/sbom/package.json and tools/sbom/pnpm-lock.yaml (the lock file of
# cdxgen, feat-16-cdxgen-lockfile). This script needs no entry for them: it searches for pom.xml and for the
# Maven Wrapper only.
EXCLUDED_NAMES = {".git", "node_modules", "build", "target"}
EXCLUDED_PATHS = {".specmgr", "tools/license/fixtures", "tools/gates/fixtures"}
WRAPPER_FILE = Path(".mvn") / "wrapper" / "maven-wrapper.properties"


class PnpmTool(NamedTuple):
    """A tool of the gates that is one npm package in a small pnpm project with a lock file.

    label: the start of each message of the check. name: the name of the tool in a text. package: the npm package.
    version_key, integrity_key: the keys of tools/versions.env. jar_sha_file, jar_sha_key: the second place of the
    pin of the jar of a Maven plugin that the folder may have (None if the folder has no such file: the check of
    cdxgen compares the jar of cyclonedx-maven-plugin with versions.env, as the check of oasdiff compares the
    download with the file of the release).
    """

    label: str
    name: str
    package: str
    version_key: str
    integrity_key: str
    jar_sha_file: str | None = None
    jar_sha_key: str | None = None


# The lock file of cdxgen (feat-16-cdxgen-lockfile) and the lock file of Spectral
# (feat-6-contracts-openapi-pipeline, Task 110.110). The same check is for both. See the header.
CDXGEN = PnpmTool(
    "SBOM tool",
    "cdxgen",
    "@cyclonedx/cdxgen",
    "CDXGEN_VERSION",
    "CDXGEN_INTEGRITY",
    "cyclonedx-maven-plugin.sha256",
    "CYCLONEDX_MAVEN_PLUGIN_SHA256",
)
SPECTRAL = PnpmTool("Lint tool", "Spectral", "@stoplight/spectral-cli", "SPECTRAL_VERSION", "SPECTRAL_INTEGRITY")
# The files that tools/sbom/ may have. A settings file (.npmrc, pnpm-workspace.yaml, .pnpmfile.cjs, ...) could
# change where pnpm gets the packages, so each other file stops the check (node_modules is the install). The file
# cyclonedx-maven-plugin.sha256 is the second place of the pin of the jar of the SBOM plugin
# (feat-6-contracts-openapi-pipeline, ACC-011).
PNPM_TOOL_FILES = {
    "package.json",
    "pnpm-lock.yaml",
    "README.md",
    "node_modules",
    "cyclonedx-maven-plugin.sha256",
}
# The keys that package.json may have. All of them are text that does not change the install.
PACKAGE_JSON_KEYS = {"name", "private", "description", "dependencies"}
# The top-level keys of pnpm-lock.yaml (lockfileVersion 9) that the check knows. `overrides`,
# `patchedDependencies`, `catalogs` and the other keys change the install, so they stop the check.
LOCK_KEYS = {"lockfileVersion", "settings", "importers", "packages", "snapshots"}
EXACT_VERSION = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?")
INTEGRITY = re.compile(r"sha(?:256|384|512)-[A-Za-z0-9+/]+={0,2}")
SHA512_INTEGRITY_FORM = re.compile(r"sha512-[A-Za-z0-9+/]{86}==")


# The lock files of the Python tools (feat-22-python-tools-lockfile): the file, the name of the package of the
# tool (normalized) and the key of its version in tools/versions.env. PYTHON_LOCK_FILES are the only files that
# the folder may have.
PYTHON_LOCKS = (
    ("specmgr.lock", "biz-dfch-specmgr", "SPECMGR_VERSION"),
    ("pyyaml.lock", "pyyaml", "PYYAML_VERSION"),
    ("license-expression.lock", "license-expression", "LICENSE_EXPRESSION_VERSION"),
)
PYTHON_LOCK_FILES = {lock[0] for lock in PYTHON_LOCKS} | {"README.md", "make-locks.sh"}
# `name==version`, with an optional marker after ` ; `. The marker has no `@`, `/` or `:`, so a URL is not a marker.
LOCK_REQUIREMENT = re.compile(
    r"(?P<name>[A-Za-z0-9][A-Za-z0-9._-]*)==(?P<version>[0-9][0-9A-Za-z.+!_-]*)(?: ; [A-Za-z0-9_.'\"()<>=! ,~-]+)?"
)
LOCK_HASH = re.compile(r"--hash=sha256:[0-9a-f]{64}")
MAX_LOCK_PROBLEMS = 5

# The pin of the generator plugin (feat-6-contracts-openapi-pipeline, Task 120.105): the keys of tools/versions.env and the
# plugin in the pom.xml.
GENERATOR_VERSION_KEY = "OPENAPI_GENERATOR_MAVEN_PLUGIN_VERSION"
GENERATOR_SHA256_KEY = "OPENAPI_GENERATOR_MAVEN_PLUGIN_SHA256"
# The second place of the pin of the jar, in <generator-tool-dir> (tools/generate, the folder of the generators).
GENERATOR_SHA_FILE = "openapi-generator-maven-plugin.sha256"
GENERATOR_GROUP_ID = "org.openapitools"
GENERATOR_ARTIFACT_ID = "openapi-generator-maven-plugin"
POM_NAMESPACE = "{http://maven.apache.org/POM/4.0.0}"

# The test tools of the Maven module (feat-7-verification-architecture-tools, Phase 110 and 120): the
# (groupId, artifactId, version key) of each dependency that a pom.xml may have, and the same for the
# plugins (the test runner and the mutation tool). The three modules of Testcontainers have the version of the
# core (TESTCONTAINERS_VERSION). The dependency pitest-junit5-plugin is a dependency of the plugin pitest-maven
# (the JUnit5 support of PIT; pitest-maven loads the test framework plugins from its own classpath), and the
# check finds it with the same search for <dependency> elements as the other dependencies.
MAVEN_TEST_DEPENDENCIES: tuple[tuple[str, str, str], ...] = (
    ("org.junit.jupiter", "junit-jupiter", "JUNIT_VERSION"),
    ("org.testcontainers", "testcontainers", "TESTCONTAINERS_VERSION"),
    ("org.testcontainers", "junit-jupiter", "TESTCONTAINERS_VERSION"),
    ("org.testcontainers", "postgresql", "TESTCONTAINERS_VERSION"),
    ("org.postgresql", "postgresql", "POSTGRESQL_VERSION"),
    ("net.jqwik", "jqwik", "JQWIK_VERSION"),
    ("org.pitest", "pitest-junit5-plugin", "PIT_JUNIT5_PLUGIN_VERSION"),
    ("org.springframework.modulith", "spring-modulith-core", "SPRING_MODULITH_VERSION"),
    ("org.springframework.boot", "spring-boot", "SPRING_BOOT_VERSION"),
    ("com.tngtech.archunit", "archunit", "ARCHUNIT_VERSION"),
    ("com.tngtech.archunit", "archunit-junit5", "ARCHUNIT_VERSION"),
    ("com.structurizr", "structurizr-client", "STRUCTURIZR_VERSION"),
)
MAVEN_TEST_PLUGINS: tuple[tuple[str, str, str], ...] = (
    ("org.apache.maven.plugins", "maven-surefire-plugin", "MAVEN_SUREFIRE_PLUGIN_VERSION"),
    ("org.pitest", "pitest-maven", "PIT_VERSION"),
    ("org.jacoco", "jacoco-maven-plugin", "JACOCO_VERSION"),
)


class FrontendPackage(NamedTuple):
    """A direct package of the pnpm module frontend/: where it is in package.json and the keys of tools/versions.env."""

    name: str
    section: str
    version_key: str
    integrity_key: str


# The pnpm module frontend/ (feat-6-contracts-openapi-pipeline, Task 120.110; the test tools of
# feat-7-verification-architecture-tools, Phase 110; the mutation tool Stryker, Phase 120; the
# architecture tool ArchUniTS, Phase 130).
# @kubb/core has the version of `kubb`.
FRONTEND_PACKAGES = (
    FrontendPackage("kubb", "devDependencies", "KUBB_VERSION", "KUBB_INTEGRITY"),
    FrontendPackage("@kubb/core", "devDependencies", "KUBB_VERSION", "KUBB_CORE_INTEGRITY"),
    FrontendPackage("@kubb/plugin-zod", "devDependencies", "KUBB_PLUGIN_ZOD_VERSION", "KUBB_PLUGIN_ZOD_INTEGRITY"),
    FrontendPackage("@kubb/plugin-ts", "devDependencies", "KUBB_PLUGIN_TS_VERSION", "KUBB_PLUGIN_TS_INTEGRITY"),
    FrontendPackage("zod", "dependencies", "ZOD_VERSION", "ZOD_INTEGRITY"),
    FrontendPackage("typescript", "devDependencies", "TYPESCRIPT_VERSION", "TYPESCRIPT_INTEGRITY"),
    FrontendPackage("vitest", "devDependencies", "VITEST_VERSION", "VITEST_INTEGRITY"),
    FrontendPackage("@playwright/test", "devDependencies", "PLAYWRIGHT_VERSION", "PLAYWRIGHT_INTEGRITY"),
    FrontendPackage("axe-core", "devDependencies", "AXE_CORE_VERSION", "AXE_CORE_INTEGRITY"),
    FrontendPackage("fast-check", "devDependencies", "FAST_CHECK_VERSION", "FAST_CHECK_INTEGRITY"),
    FrontendPackage("vite", "devDependencies", "VITE_VERSION", "VITE_INTEGRITY"),
    FrontendPackage("@stryker-mutator/core", "devDependencies", "STRYKER_VERSION", "STRYKER_INTEGRITY"),
    FrontendPackage(
        "@stryker-mutator/vitest-runner",
        "devDependencies",
        "STRYKER_VITEST_RUNNER_VERSION",
        "STRYKER_VITEST_RUNNER_INTEGRITY",
    ),
    FrontendPackage("archunit", "devDependencies", "ARCHUNIT_TS_VERSION", "ARCHUNIT_TS_INTEGRITY"),
    FrontendPackage(
        "@vitest/coverage-v8", "devDependencies", "VITEST_COVERAGE_V8_VERSION", "VITEST_COVERAGE_V8_INTEGRITY"
    ),
)
# The keys that package.json of frontend/ may have. `scripts` does not change the install (the gates use --ignore-scripts).
FRONTEND_PACKAGE_JSON_KEYS = {
    "name",
    "private",
    "version",
    "description",
    "type",
    "scripts",
    "dependencies",
    "devDependencies",
}
FRONTEND_FILES = ("package.json", "pnpm-workspace.yaml", "pnpm-lock.yaml")
# Files that could change where pnpm gets the packages, or that make a second lock file.
FRONTEND_FORBIDDEN_FILES = {
    ".npmrc",
    ".pnpmfile.cjs",
    ".pnpmfile.mjs",
    "pnpmfile.cjs",
    ".yarnrc",
    ".yarnrc.yml",
    "yarn.lock",
    "package-lock.json",
    "bunfig.toml",
}

# The pin of oasdiff (feat-6-contracts-openapi-pipeline, Task 115.100): the keys of tools/versions.env, the name of the
# release file for Linux x86_64, and the file of the vendor (checksums.txt of the release) in tools/breaking/.
OASDIFF_VERSION_KEY = "OASDIFF_VERSION"
OASDIFF_SHA256_KEY = "OASDIFF_SHA256"
OASDIFF_ASSET = "oasdiff_{version}_linux_amd64.tar.gz"
OASDIFF_CHECKSUMS_FILE = "oasdiff-checksums.txt"
SHA256_VALUE = re.compile(r"[0-9a-f]{64}")
CHECKSUM_LINE = re.compile(r"([0-9a-f]{64})  (\S+)")

# The tie of the transitive package caniuse-lite (feat-7-verification-architecture-tools, Phase 120): the name of the
# package in the lock file of frontend/, and the key of tools/versions.env. The rule X1 of sbom.sh excludes the pinned
# version from the SBOM of the frontend (the deviation DEC, the register), and the lock file is the tie (the package is
# not a direct package of the module).
CANIUSE_LITE_PACKAGE = "caniuse-lite"
CANIUSE_LITE_VERSION_KEY = "CANIUSE_LITE_VERSION"


def read_versions(path: Path) -> dict[str, str]:
    """Read tools/versions.env (lines `KEY=value`)."""
    versions: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Z][A-Z0-9_]*)=(\S*)", line)
        if not match:
            raise GateError(f"{path}, line {number}: the form is not KEY=value")
        versions[match.group(1)] = match.group(2)
    return versions


def read_allowed(path: Path) -> dict[str, tuple[str, str]]:
    """Read the allowed actions: lines `<owner>/<name> <tag> <sha>`."""
    allowed: dict[str, tuple[str, str]] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"(\S+/\S+) (v[0-9]+(?:\.[0-9]+){0,2}) ([0-9a-f]{40})", line.strip())
        if not match:
            raise GateError(f"{path}, line {number}: the form is not `<owner>/<name> <tag> <sha>`")
        allowed[match.group(1)] = (match.group(2), match.group(3))
    if not allowed:
        raise GateError(f"{path} has no action")
    return allowed


def check_use(location: str, text: str, comment: str | None, allowed: dict[str, tuple[str, str]]) -> list[str]:
    """Check one `uses:` value and its comment. Return the problems."""
    value = USES_VALUE.fullmatch(text)
    if not value:
        return [f"{location}: `uses: {text}` is not `<owner>/<name>@<40 hexadecimal characters>`"]
    name, sha = value.group("name"), value.group("sha")
    if value.group("path"):
        return [f"{location}: `uses: {text}` has a path in the action. The table has the action {name} only"]
    if comment is None:
        return [f"{location}: `uses: {text}` has no comment `# {name} <tag>` on the same line"]
    match = COMMENT.fullmatch(comment)
    if not match or match.group("name") != name:
        return [f"{location}: the comment `#{comment}` must be `# {name} <tag>` (a release tag such as v7.0.1)"]
    tag = match.group("tag")
    if name not in allowed:
        return [f"{location}: the action {name} is not in the table of allowed actions (the license table)"]
    if allowed[name] != (tag, sha):
        return [
            f"{location}: {name} is {tag} {sha}, but the table has {allowed[name][0]} {allowed[name][1]}",
        ]
    return []


def check_inputs(location: str, name: str, with_block: Any, versions: dict[str, str]) -> list[str]:
    """Check the inputs of an action step against tools/versions.env."""
    problems: list[str] = []
    inputs = with_block if isinstance(with_block, dict) else {}
    tool_inputs = TOOL_INPUTS.get(name, {})
    for input_name, key in tool_inputs.items():
        if key not in versions:
            problems.append(f"{location}: {key} is not in tools/versions.env")
            continue
        value = inputs.get(input_name)
        if value is None:
            problems.append(f"{location}: {name} has no input `{input_name}` (it must be {versions[key]})")
        elif not isinstance(value, str):
            problems.append(f"{location}: the input `{input_name}` must be a text in quotes ({value!r})")
        elif value != versions[key]:
            problems.append(
                f"{location}: `{input_name}` is {value}, but {key} in tools/versions.env is {versions[key]}"
            )
    for input_name, expected in FIXED_INPUTS.get(name, {}).items():
        if inputs.get(input_name) != expected:
            problems.append(f"{location}: `{input_name}` of {name} must be {expected}")
    for input_name in inputs:
        if VERSION_KEY.search(str(input_name)) and input_name not in tool_inputs:
            problems.append(f"{location}: the input `{input_name}` of {name} has a version that the gate cannot check")
    return problems


def check_file(
    path: Path, workflow: dict[Any, Any], versions: dict[str, str], allowed: dict[str, tuple[str, str]]
) -> tuple[int, list[str]]:
    """Check one workflow file. Return the number of `uses:` steps and the problems."""
    problems: list[str] = []

    # The text check: each `uses:` line, with its comment.
    from_text: list[tuple[str, str | None, int]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = USES_LINE.match(line)
        if match:
            from_text.append((match.group(1), match.group(2), number))

    # The YAML check: each `uses:` of a step (a job with `uses:` has no steps, and stops iter_steps).
    from_yaml: list[tuple[str, str, Any]] = []
    for job_id, job in iter_jobs(path, workflow):
        for index, step in enumerate(iter_steps(path, job_id, job), start=1):
            if "uses" in step:
                from_yaml.append((f"job '{job_id}', step {index}", str(step["uses"]), step.get("with")))

    if Counter(text for text, _, _ in from_text) != Counter(uses for _, uses, _ in from_yaml):
        problems.append(
            f"{path}: the `uses:` entries in the text and in the YAML are not the same. "
            "Write each `uses: <owner>/<name>@<sha> # <owner>/<name> <tag>` on one line"
        )
        return len(from_yaml), problems

    for text, comment, number in from_text:
        problems += check_use(f"{path}:{number}", text, comment, allowed)
    for where, uses, with_block in from_yaml:
        value = USES_VALUE.fullmatch(uses)
        if value:
            problems += check_inputs(f"{path}, {where}", value.group("name"), with_block, versions)
    return len(from_yaml), problems


def find_files(root: Path, name: str) -> list[Path]:
    """Return the paths (relative to the root) of the files with this name, without the excluded folders."""
    found: list[Path] = []
    for folder, dirs, files in os.walk(root):
        relative = Path(folder).relative_to(root)
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDED_NAMES and (relative / d).as_posix() not in EXCLUDED_PATHS)
        if name in files:
            found.append(relative / name)
    return sorted(found)


def read_properties(path: Path) -> dict[str, str]:
    """Read a Java properties file (lines `key=value`; `#` and `!` start a comment; `\\:` is a colon)."""
    properties: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise GateError(f"cannot read {path}: {error}") from error
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped[0] in "#!" or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        properties[key.strip()] = value.strip().replace("\\:", ":")
    return properties


def check_maven(root: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the Maven pin (finding G1). Return a message for the log and the problems."""
    if "MAVEN_VERSION" not in versions:
        return "", ["MAVEN_VERSION is not in tools/versions.env"]
    version = versions["MAVEN_VERSION"]
    poms = find_files(root, "pom.xml")
    wrappers = [path for path in find_files(root, "maven-wrapper.properties") if path.parts[-3:] == WRAPPER_FILE.parts]
    if not poms and not wrappers:
        return "no Maven project (no pom.xml and no Maven Wrapper)", []
    problems: list[str] = []
    if poms and not wrappers:
        problems.append(
            f"Maven: {', '.join(str(p) for p in poms)} exists, but no {WRAPPER_FILE} (the Maven Wrapper). "
            f"Add the wrapper for Maven {version}: CI has no Maven setup action and must not use the Maven of the runner"
        )
    url_pattern = re.compile(r"/apache-maven-" + re.escape(version) + r"-bin\.(zip|tar\.gz)")
    for wrapper in wrappers:
        properties = read_properties(root / wrapper)
        url = properties.get("distributionUrl")
        if url is None:
            problems.append(f"Maven: {wrapper} has no `distributionUrl`")
        elif not url_pattern.search(url):
            problems.append(
                f"Maven: {wrapper}: `distributionUrl` is {url}, but MAVEN_VERSION in tools/versions.env is {version} "
                f"(the URL must have apache-maven-{version}-bin.zip)"
            )
        checksum = properties.get("distributionSha256Sum")
        if checksum is None:
            problems.append(f"Maven: {wrapper} has no `distributionSha256Sum` (the sha256 of the Maven download)")
        elif not re.fullmatch(r"[0-9a-fA-F]{64}", checksum):
            problems.append(f"Maven: {wrapper}: `distributionSha256Sum` is not a sha256 value ({checksum!r})")
    note = f"Maven Wrapper: {len(wrappers)} file(s), Maven {version}" if not problems else ""
    return note, problems


class _UniqueKeyLoader(yaml.SafeLoader):
    """A YAML loader that stops for a key that is there two times (the standard loader keeps the last one)."""


def _construct_unique_mapping(loader: _UniqueKeyLoader, node: yaml.MappingNode, deep: bool = False) -> dict[Any, Any]:
    seen: set[Any] = set()
    for key_node, _ in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in seen:
            raise yaml.constructor.ConstructorError(
                None, None, f"the key {key!r} is there two times", key_node.start_mark
            )
        seen.add(key)
    return yaml.SafeLoader.construct_mapping(loader, node, deep=deep)


_UniqueKeyLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _construct_unique_mapping)


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    """The `object_pairs_hook` of the JSON reader: stop for a key that is there two times."""
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"the key {key!r} is there two times")
        result[key] = value
    return result


def check_package_json(tool: PnpmTool, path: Path, version: str) -> list[str]:
    """Check the package.json of a pnpm tool: the one dependency in the exact version, and no other key that matters."""
    where = f"{tool.label}: {path}"
    try:
        data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except (OSError, ValueError) as error:
        return [f"{where} cannot be read as JSON: {error}"]
    if not isinstance(data, dict):
        return [f"{where} is not a JSON object"]
    problems: list[str] = []
    for key in sorted(set(data) - PACKAGE_JSON_KEYS):
        problems.append(
            f"{where} has the key `{key}`. The project has only {sorted(PACKAGE_JSON_KEYS)}: no other dependency "
            "key (devDependencies, optionalDependencies, peerDependencies), no overrides, no `pnpm` settings and "
            "no `packageManager` (it changes the lock file)"
        )
    dependencies = data.get("dependencies")
    if not isinstance(dependencies, dict):
        problems.append(f"{where} has no `dependencies` object with {tool.package}")
    else:
        for name in sorted(set(dependencies) - {tool.package}):
            problems.append(f"{where} has the dependency {name}. The only dependency is {tool.package}")
        if tool.package not in dependencies:
            problems.append(f"{where} has no dependency {tool.package}")
        elif dependencies[tool.package] != version:
            problems.append(
                f"{where}: {tool.package} is {dependencies[tool.package]!r}, but {tool.version_key} in "
                f"tools/versions.env is {version} (an exact version, no range and no tag)"
            )
    return problems


def _split_package_key(key: str) -> tuple[str, str] | None:
    """Split `name@version` or `@scope/name@version`. Return None if the key has another form."""
    index = key.rfind("@")
    if index <= 0:
        return None
    return key[:index], key[index + 1 :]


def check_lock(tool: PnpmTool, path: Path, version: str, integrity: str) -> list[str]:
    """Check the pnpm-lock.yaml of a pnpm tool (see the header). Return the problems."""
    where = f"{tool.label}: {path}"
    try:
        documents = list(yaml.load_all(path.read_text(encoding="utf-8"), Loader=_UniqueKeyLoader))
    except (OSError, yaml.YAMLError, TypeError, ValueError) as error:
        return [f"{where} cannot be read as YAML: {error}"]
    if len(documents) != 1:
        return [
            f"{where} has {len(documents)} YAML documents, but it must have exactly one"
            + " (a `packageManager` field in package.json makes a second document)"
        ]
    lock = documents[0]
    if not isinstance(lock, dict):
        return [f"{where} is not a YAML mapping"]
    problems: list[str] = []
    lock_version = lock.get("lockfileVersion")
    if not isinstance(lock_version, str) or not lock_version.startswith("9."):
        problems.append(f"{where}: `lockfileVersion` is {lock_version!r}, but it must be a text that starts with `9.`")
    for key in sorted(set(lock) - LOCK_KEYS, key=str):
        problems.append(
            f"{where} has the top-level key `{key}`, which the check does not know (known: {sorted(LOCK_KEYS)})"
        )

    problems += _check_importers(tool, where, lock.get("importers"), version)
    packages = lock.get("packages")
    if not isinstance(packages, dict) or not packages:
        problems.append(f"{where} has no `packages`")
        return problems
    problems += _check_packages(tool, where, packages, version, integrity)
    snapshots = lock.get("snapshots")
    if snapshots is not None:
        if not isinstance(snapshots, dict):
            problems.append(f"{where}: `snapshots` is not a mapping")
        else:
            for key in snapshots:
                if str(key).split("(", 1)[0] not in packages:
                    problems.append(f"{where}: `snapshots` has {key!r}, which is not in `packages`")
    return problems


def _check_importers(tool: PnpmTool, where: str, importers: Any, version: str) -> list[str]:
    """Exactly one importer `.` with exactly one direct dependency: the tool, in the version of versions.env."""
    if not isinstance(importers, dict) or set(importers) != {"."}:
        found = sorted(importers, key=str) if isinstance(importers, dict) else importers
        return [f"{where}: `importers` must have exactly one importer `.` (it has {found!r})"]
    importer = importers["."]
    if not isinstance(importer, dict) or set(importer) != {"dependencies"}:
        found = sorted(importer, key=str) if isinstance(importer, dict) else importer
        return [f"{where}: the importer `.` must have `dependencies` and nothing else (it has {found!r})"]
    dependencies = importer["dependencies"]
    if not isinstance(dependencies, dict) or set(dependencies) != {tool.package}:
        found = sorted(dependencies, key=str) if isinstance(dependencies, dict) else dependencies
        return [f"{where}: the importer `.` must have exactly one dependency, {tool.package} (it has {found!r})"]
    entry = dependencies[tool.package]
    if not isinstance(entry, dict) or set(entry) != {"specifier", "version"}:
        return [f"{where}: the dependency {tool.package} of the importer must have `specifier` and `version`"]
    return [
        f"{where}: the importer has {tool.package} `{field}` {entry[field]!r}, but {tool.version_key} in "
        f"tools/versions.env is {version}"
        for field in ("specifier", "version")
        if entry[field] != version
    ]


def _check_packages(tool: PnpmTool, where: str, packages: dict[Any, Any], version: str, integrity: str) -> list[str]:
    """Each package has a registry source and an integrity value. The tool has the values of versions.env."""
    problems: list[str] = []
    tool_keys = []
    for key, entry in packages.items():
        parts = _split_package_key(str(key)) if isinstance(key, str) else None
        if parts is None or not EXACT_VERSION.fullmatch(parts[1]):
            problems.append(
                f"{where}: the package {key!r} is not `<name>@<exact version>` (a link, a URL or a git source?)"
            )
            continue
        if parts[0] == tool.package:
            tool_keys.append(key)
        resolution = entry.get("resolution") if isinstance(entry, dict) else None
        if not isinstance(resolution, dict):
            problems.append(f"{where}: the package {key} has no `resolution`")
        elif "integrity" not in resolution:
            problems.append(f"{where}: the package {key} has no integrity value")
        elif not isinstance(resolution["integrity"], str) or not INTEGRITY.fullmatch(resolution["integrity"]):
            problems.append(f"{where}: the package {key} has an integrity value that is not sha256, sha384 or sha512")
        elif set(resolution) != {"integrity"}:
            others = sorted(set(resolution) - {"integrity"}, key=str)
            problems.append(
                f"{where}: the package {key} has the `resolution` keys {others}. The check allows `integrity` only"
            )
    expected_key = f"{tool.package}@{version}"
    if tool_keys != [expected_key]:
        problems.append(
            f"{where}: `packages` must have exactly one {tool.package}, and it must be {expected_key} "
            f"({tool.version_key} in tools/versions.env). It has {tool_keys}"
        )
    else:
        resolution = packages[expected_key].get("resolution") if isinstance(packages[expected_key], dict) else None
        found = resolution.get("integrity") if isinstance(resolution, dict) else None
        if found != integrity:
            problems.append(
                f"{where}: the integrity value of {expected_key} is {found}, but {tool.integrity_key} in "
                f"tools/versions.env is {integrity}"
            )
    return problems


def check_pnpm_tool(tool: PnpmTool, tool_dir: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the pnpm project of a tool (cdxgen: feat-16-cdxgen-lockfile; Spectral: feat-6, Task 110.110).

    Return a message for the log and the problems.
    """
    problems: list[str] = []
    version, integrity = versions.get(tool.version_key, ""), versions.get(tool.integrity_key, "")
    for key in (tool.version_key, tool.integrity_key):
        if key not in versions:
            problems.append(f"{key} is not in tools/versions.env")
    if version and not EXACT_VERSION.fullmatch(version):
        problems.append(
            f"{tool.version_key} in tools/versions.env is {version!r}, "
            "but it must be an exact version (no range, no tag)"
        )
    if integrity and not SHA512_INTEGRITY_FORM.fullmatch(integrity):
        problems.append(
            f"{tool.integrity_key} in tools/versions.env is {integrity!r}, "
            "but it must be a sha512 integrity value of npm"
        )
    if not tool_dir.is_dir():
        problems.append(f"{tool.label}: the folder {tool_dir} (the lock file of {tool.name}) does not exist")
        return "", problems
    for name in sorted(path.name for path in tool_dir.iterdir()):
        if name not in PNPM_TOOL_FILES:
            problems.append(
                f"{tool.label}: {tool_dir / name} is not allowed. The folder has only {sorted(PNPM_TOOL_FILES)} "
                "(a settings file could change where pnpm gets the packages)"
            )
    package_json, lock = tool_dir / "package.json", tool_dir / "pnpm-lock.yaml"
    for path in (package_json, lock):
        if not path.is_file():
            problems.append(f"{tool.label}: {path} does not exist")
    if problems:
        return "", problems
    # The version and the integrity value are in the right form here, or the problems above stopped.
    problems += check_package_json(tool, package_json, version)
    problems += check_lock(tool, lock, version, integrity)
    note = f"{tool.label}: {tool_dir}: {tool.package} {version}, package.json and lock file as in tools/versions.env"
    if tool.jar_sha_file and tool.jar_sha_key:
        problems += check_jar_sha_file(tool.label, tool_dir / tool.jar_sha_file, tool.jar_sha_key, versions)
        note += f", and the sha256 of the plugin jar in {tool.jar_sha_file} as in tools/versions.env"
    return ("" if problems else note), problems


def check_jar_sha_file(label: str, path: Path, key: str, versions: dict[str, str]) -> list[str]:
    """The second place of the pin of the jar of a Maven plugin (ACC-011): the file has the value of <key>.

    The file has exactly one line, a sha256 value (64 lower case hexadecimal characters). <label> is the start of
    the message (for example `SBOM tool` or `Generator plugin`). See the header.
    """
    where = f"{label}: {path}"
    if key not in versions:
        return [f"{key} is not in tools/versions.env"]
    value = versions[key]
    if not SHA256_VALUE.fullmatch(value):
        return [
            (
                f"{key} in tools/versions.env is {value!r}, "
                "but it must be a sha256 value (64 lower case hexadecimal characters)"
            )
        ]
    if not path.is_file():
        return [f"{where} does not exist (it is the second place of {key}, the sha256 of the plugin jar)"]
    try:
        lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    except (OSError, UnicodeDecodeError) as error:
        return [f"cannot read {where}: {error}"]
    if len(lines) != 1 or not SHA256_VALUE.fullmatch(lines[0]):
        return [f"{where} has one line with the sha256 value only (64 lower case hexadecimal characters)"]
    if lines[0] != value:
        return [f"{where} has the sha256 {lines[0]} for the plugin jar, but {key} in tools/versions.env is {value}"]
    return []


def check_oasdiff(tool_dir: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the pin of oasdiff (see the header). Return a message for the log and the problems."""
    label = "Breaking-changes tool"
    problems: list[str] = []
    version, sha256 = versions.get(OASDIFF_VERSION_KEY, ""), versions.get(OASDIFF_SHA256_KEY, "")
    for key in (OASDIFF_VERSION_KEY, OASDIFF_SHA256_KEY):
        if key not in versions:
            problems.append(f"{key} is not in tools/versions.env")
    if version and not EXACT_VERSION.fullmatch(version):
        problems.append(f"{OASDIFF_VERSION_KEY} in tools/versions.env is {version!r}, but it must be an exact version")
    if sha256 and not SHA256_VALUE.fullmatch(sha256):
        problems.append(
            f"{OASDIFF_SHA256_KEY} in tools/versions.env is {sha256!r}, "
            "but it must be a sha256 value (64 lower case hexadecimal characters)"
        )
    if problems:
        return "", problems
    path = tool_dir / OASDIFF_CHECKSUMS_FILE
    if not tool_dir.is_dir():
        return "", [f"{label}: the folder {tool_dir} (the checksums of the release of oasdiff) does not exist"]
    if not path.is_file():
        return "", [f"{label}: {path} does not exist (it is the file `checksums.txt` of the release of oasdiff)"]
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return "", [f"{label}: cannot read {path}: {error}"]
    asset = OASDIFF_ASSET.format(version=version)
    found: list[str] = []
    for number, line in enumerate(lines, start=1):
        if not line.strip():
            continue
        match = CHECKSUM_LINE.fullmatch(line)
        if not match:
            problems.append(f"{label}: {path}, line {number}: the form is not `<sha256 value>  <file name>`")
        elif match.group(2) == asset:
            found.append(match.group(1))
    if not found:
        problems.append(
            f"{label}: {path} has no line for {asset}. {OASDIFF_VERSION_KEY} in tools/versions.env is {version}"
        )
    elif len(found) > 1:
        problems.append(f"{label}: {path} has {len(found)} lines for {asset}, but it must have one")
    elif found[0] != sha256:
        problems.append(
            f"{label}: {path} has the sha256 {found[0]} for {asset}, "
            f"but {OASDIFF_SHA256_KEY} in tools/versions.env is {sha256}"
        )
    note = f"{label}: {path}: {asset} has the sha256 of tools/versions.env"
    return ("" if problems else note), problems


def _resolve_pom_value(text: str, properties: dict[str, str]) -> str | None:
    """Resolve a `${name}` of the <properties> of a pom.xml. Return None if the value has another form."""
    text = text.strip()
    match = re.fullmatch(r"\$\{([^${}]+)\}", text)
    if match:
        return properties.get(match.group(1).strip())
    return None if "${" in text else text


def check_generator_plugin(root: Path, tool_dir: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the pin of the generator plugin (see the header). Return a message for the log and the problems.

    tool_dir is the folder that has the file GENERATOR_SHA_FILE, the second place of the pin of the jar
    (tools/generate, the folder of the generators).
    """
    label = "Generator plugin"
    problems: list[str] = []
    version, sha256 = versions.get(GENERATOR_VERSION_KEY, ""), versions.get(GENERATOR_SHA256_KEY, "")
    for key in (GENERATOR_VERSION_KEY, GENERATOR_SHA256_KEY):
        if key not in versions:
            problems.append(f"{key} is not in tools/versions.env")
    if version and not EXACT_VERSION.fullmatch(version):
        problems.append(
            f"{GENERATOR_VERSION_KEY} in tools/versions.env is {version!r}, but it must be an exact version"
        )
    if sha256 and not SHA256_VALUE.fullmatch(sha256):
        problems.append(
            f"{GENERATOR_SHA256_KEY} in tools/versions.env is {sha256!r}, "
            "but it must be a sha256 value (64 lower case hexadecimal characters)"
        )
    if problems:
        return "", problems
    checked: list[str] = []
    for pom in find_files(root, "pom.xml"):
        try:
            tree = ET.parse(root / pom)
        except (OSError, ET.ParseError) as error:
            problems.append(f"{label}: cannot read {pom} as XML: {error}")
            continue
        project = tree.getroot()
        properties_node = project.find(f"{POM_NAMESPACE}properties")
        properties = (
            {child.tag.removeprefix(POM_NAMESPACE): (child.text or "") for child in properties_node}
            if properties_node is not None
            else {}
        )
        for plugin in project.iter(f"{POM_NAMESPACE}plugin"):
            artifact = plugin.findtext(f"{POM_NAMESPACE}artifactId", default="").strip()
            group = plugin.findtext(f"{POM_NAMESPACE}groupId", default="").strip()
            if artifact != GENERATOR_ARTIFACT_ID or group != GENERATOR_GROUP_ID:
                continue
            raw = plugin.findtext(f"{POM_NAMESPACE}version")
            if raw is None or not raw.strip():
                problems.append(f"{label}: {pom} has the plugin {GENERATOR_ARTIFACT_ID} with no <version>")
                continue
            found = _resolve_pom_value(raw, properties)
            if found is None:
                problems.append(
                    f"{label}: {pom}: the version {raw.strip()!r} of the plugin {GENERATOR_ARTIFACT_ID} is not a version "
                    "or a <properties> value of the same pom.xml"
                )
            elif found != version:
                problems.append(
                    f"{label}: {pom} has the plugin {GENERATOR_ARTIFACT_ID} {found}, "
                    f"but {GENERATOR_VERSION_KEY} in tools/versions.env is {version}"
                )
            else:
                checked.append(str(pom))
    # The version and the sha256 are in the right form here, or the problems above stopped.
    problems += check_jar_sha_file(label, tool_dir / GENERATOR_SHA_FILE, GENERATOR_SHA256_KEY, versions)
    note = (
        f"{label}: {', '.join(checked)}: {GENERATOR_ARTIFACT_ID} {version}, the version of tools/versions.env"
        if checked
        else f"{label}: no pom.xml has the plugin {GENERATOR_ARTIFACT_ID}"
    )
    note += f", and the sha256 of the jar in {tool_dir / GENERATOR_SHA_FILE} as in tools/versions.env"
    return ("" if problems else note), problems


def check_maven_test_pins(root: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the pin of the test tools of the Maven module (see the header). Return a note and the problems.

    A pom.xml that has none of the test tools is no problem for this check (as for the generator plugin). A test
    dependency (or the test runner plugin) that is there has the version of tools/versions.env (the version can be a
    `${property}` of the same pom.xml), and a test dependency in the direct `<dependencies>` section of the pom.xml
    has `<scope>test</scope>` (a scope that is absent is the default compile of Maven, and stops the check; a plugin
    dependency has no scope and is no problem).
    """
    label = "Maven test pins"
    problems: list[str] = []
    for _group, _artifact, key in (*MAVEN_TEST_DEPENDENCIES, *MAVEN_TEST_PLUGINS):
        if key not in versions:
            problems.append(f"{key} is not in tools/versions.env")
        elif not EXACT_VERSION.fullmatch(versions[key]):
            problems.append(
                f"{key} in tools/versions.env is {versions[key]!r}, but it must be an exact version (no range, no tag)"
            )
    if problems:
        return "", problems
    checked: list[str] = []
    for pom in find_files(root, "pom.xml"):
        try:
            tree = ET.parse(root / pom)
        except (OSError, ET.ParseError) as error:
            problems.append(f"{label}: cannot read {pom} as XML: {error}")
            continue
        project = tree.getroot()
        properties_node = project.find(f"{POM_NAMESPACE}properties")
        properties = (
            {child.tag.removeprefix(POM_NAMESPACE): (child.text or "") for child in properties_node}
            if properties_node is not None
            else {}
        )
        for group, artifact, key in MAVEN_TEST_DEPENDENCIES:
            for dependency in project.iter(f"{POM_NAMESPACE}dependency"):
                if (
                    dependency.findtext(f"{POM_NAMESPACE}groupId", default="").strip() != group
                    or dependency.findtext(f"{POM_NAMESPACE}artifactId", default="").strip() != artifact
                ):
                    continue
                raw = dependency.findtext(f"{POM_NAMESPACE}version")
                if raw is None or not raw.strip():
                    problems.append(f"{label}: {pom} has the dependency {artifact} with no <version>")
                    continue
                version = _resolve_pom_value(raw, properties)
                if version is None:
                    problems.append(
                        f"{label}: {pom}: the version {raw.strip()!r} of the dependency {artifact} is not a version or a "
                        "<properties> value of the same pom.xml"
                    )
                elif version != versions[key]:
                    problems.append(
                        f"{label}: {pom} has the dependency {artifact} {version}, "
                        f"but {key} in tools/versions.env is {versions[key]}"
                    )
                else:
                    checked.append(f"{pom}: {artifact} {version}")
        # The scope of the test dependencies: a test tool in the direct <dependencies> section of the
        # pom.xml must be in the scope test, so the cyclonedx plugin (includeTestScope, the default
        # false) keeps it out of the SBOM. A scope that is absent is the default compile of Maven, and
        # stops the check. A plugin dependency (for example pitest-junit5-plugin) is no test
        # dependency of the module, has no scope, and is no problem.
        dependencies_node = project.find(f"{POM_NAMESPACE}dependencies")
        direct_dependencies = [child for child in dependencies_node] if dependencies_node is not None else []
        for group, artifact, key in MAVEN_TEST_DEPENDENCIES:
            for dependency in direct_dependencies:
                if (
                    dependency.findtext(f"{POM_NAMESPACE}groupId", default="").strip() != group
                    or dependency.findtext(f"{POM_NAMESPACE}artifactId", default="").strip() != artifact
                ):
                    continue
                scope = (dependency.findtext(f"{POM_NAMESPACE}scope", default="") or "").strip()
                if scope == "test":
                    continue
                if scope:
                    problems.append(
                        f"{label}: {pom} has the dependency {artifact} with <scope>{scope}</scope>, but the test "
                        "tools must be in the scope test (the cyclonedx plugin keeps the test scope out of the SBOM)"
                    )
                else:
                    problems.append(
                        f"{label}: {pom} has the dependency {artifact} with no <scope> (the default of Maven is "
                        "compile), but the test tools must be in the scope test (the cyclonedx plugin keeps the "
                        "test scope out of the SBOM)"
                    )
        for group, artifact, key in MAVEN_TEST_PLUGINS:
            for plugin in project.iter(f"{POM_NAMESPACE}plugin"):
                if (
                    plugin.findtext(f"{POM_NAMESPACE}groupId", default="").strip() != group
                    or plugin.findtext(f"{POM_NAMESPACE}artifactId", default="").strip() != artifact
                ):
                    continue
                raw = plugin.findtext(f"{POM_NAMESPACE}version")
                if raw is None or not raw.strip():
                    problems.append(f"{label}: {pom} has the plugin {artifact} with no <version>")
                    continue
                version = _resolve_pom_value(raw, properties)
                if version is None:
                    problems.append(
                        f"{label}: {pom}: the version {raw.strip()!r} of the plugin {artifact} is not a version or a "
                        "<properties> value of the same pom.xml"
                    )
                elif version != versions[key]:
                    problems.append(
                        f"{label}: {pom} has the plugin {artifact} {version}, "
                        f"but {key} in tools/versions.env is {versions[key]}"
                    )
                else:
                    checked.append(f"{pom}: the plugin {artifact} {version}")
    note = (
        f"{label}: {', '.join(checked)}, the versions of tools/versions.env"
        if checked
        else f"{label}: no pom.xml has a test tool"
    )
    return ("" if problems else note), problems


def _frontend_versions(versions: dict[str, str]) -> tuple[dict[str, tuple[str, str]], list[str]]:
    """The version and the integrity value of each direct package of frontend/, and the problems of versions.env."""
    problems: list[str] = []
    result: dict[str, tuple[str, str]] = {}
    for package in FRONTEND_PACKAGES:
        version, integrity = versions.get(package.version_key, ""), versions.get(package.integrity_key, "")
        for key in (package.version_key, package.integrity_key):
            if key not in versions:
                problems.append(f"{key} is not in tools/versions.env")
        if version and not EXACT_VERSION.fullmatch(version):
            problems.append(
                f"{package.version_key} in tools/versions.env is {version!r}, but it must be an exact version (no range, no tag)"
            )
        if integrity and not SHA512_INTEGRITY_FORM.fullmatch(integrity):
            problems.append(
                f"{package.integrity_key} in tools/versions.env is {integrity!r}, but it must be a sha512 integrity value of npm"
            )
        result[package.name] = (version, integrity)
    return result, sorted(set(problems))


def _check_frontend_package_json(path: Path, expected: dict[str, tuple[str, str]]) -> list[str]:
    where = f"Frontend: {path}"
    try:
        data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except (OSError, ValueError) as error:
        return [f"{where} cannot be read as JSON: {error}"]
    if not isinstance(data, dict):
        return [f"{where} is not a JSON object"]
    problems: list[str] = []
    for key in sorted(set(data) - FRONTEND_PACKAGE_JSON_KEYS):
        problems.append(
            f"{where} has the key `{key}`. The module has only {sorted(FRONTEND_PACKAGE_JSON_KEYS)}: no "
            "optionalDependencies, peerDependencies, overrides, `pnpm` settings or `packageManager`"
        )
    for section in ("dependencies", "devDependencies"):
        wanted = {p.name: p for p in FRONTEND_PACKAGES if p.section == section}
        found = data.get(section)
        if not isinstance(found, dict):
            problems.append(f"{where} has no `{section}` object")
            continue
        for name in sorted(set(found) - set(wanted)):
            problems.append(f"{where}: `{section}` has {name}. It has only {sorted(wanted)}")
        for name, package in sorted(wanted.items()):
            if name not in found:
                problems.append(f"{where}: `{section}` has no {name}")
            elif found[name] != expected[name][0]:
                problems.append(
                    f"{where}: {name} is {found[name]!r}, but {package.version_key} in tools/versions.env is "
                    f"{expected[name][0]} (an exact version, no range and no tag)"
                )
    return problems


def _check_frontend_lock(path: Path, expected: dict[str, tuple[str, str]]) -> list[str]:
    where = f"Frontend: {path}"
    try:
        documents = list(yaml.load_all(path.read_text(encoding="utf-8"), Loader=_UniqueKeyLoader))
    except (OSError, yaml.YAMLError, TypeError, ValueError) as error:
        return [f"{where} cannot be read as YAML: {error}"]
    if len(documents) != 1:
        return [f"{where} has {len(documents)} YAML documents, but it must have exactly one"]
    lock = documents[0]
    if not isinstance(lock, dict):
        return [f"{where} is not a YAML mapping"]
    problems: list[str] = []
    lock_version = lock.get("lockfileVersion")
    if not isinstance(lock_version, str) or not lock_version.startswith("9."):
        problems.append(f"{where}: `lockfileVersion` is {lock_version!r}, but it must be a text that starts with `9.`")
    for key in sorted(set(lock) - LOCK_KEYS, key=str):
        problems.append(
            f"{where} has the top-level key `{key}`, which the check does not know (known: {sorted(LOCK_KEYS)})"
        )
    importers = lock.get("importers")
    if not isinstance(importers, dict) or set(importers) != {"."}:
        found = sorted(importers, key=str) if isinstance(importers, dict) else importers
        problems.append(f"{where}: `importers` must have exactly one importer `.` (it has {found!r})")
    elif not isinstance(importers["."], dict) or not set(importers["."]) <= {"dependencies", "devDependencies"}:
        problems.append(f"{where}: the importer `.` must have `dependencies` and `devDependencies` and nothing else")
    else:
        importer = importers["."]
        for package in FRONTEND_PACKAGES:
            entries = importer.get(package.section)
            entry = entries.get(package.name) if isinstance(entries, dict) else None
            if not isinstance(entry, dict) or set(entry) != {"specifier", "version"}:
                problems.append(
                    f"{where}: the importer has no {package.name} in `{package.section}` with `specifier` and `version`"
                )
                continue
            want = expected[package.name][0]
            if entry["specifier"] != want:
                problems.append(
                    f"{where}: the importer has {package.name} `specifier` {entry['specifier']!r}, "
                    f"but {package.version_key} in tools/versions.env is {want}"
                )
            if str(entry["version"]).split("(", 1)[0] != want:
                problems.append(
                    f"{where}: the importer has {package.name} `version` {entry['version']!r}, "
                    f"but {package.version_key} in tools/versions.env is {want}"
                )
        for section in importer:
            names = {p.name for p in FRONTEND_PACKAGES if p.section == section}
            if isinstance(importer[section], dict):
                for name in sorted(set(importer[section]) - names):
                    problems.append(
                        f"{where}: the importer has the direct dependency {name} in `{section}`, which the check does not know"
                    )
    packages = lock.get("packages")
    if not isinstance(packages, dict) or not packages:
        problems.append(f"{where} has no `packages`")
        return problems
    for key, entry in packages.items():
        parts = _split_package_key(str(key)) if isinstance(key, str) else None
        if parts is None or not EXACT_VERSION.fullmatch(parts[1]):
            problems.append(
                f"{where}: the package {key!r} is not `<name>@<exact version>` (a link, a URL or a git source?)"
            )
            continue
        resolution = entry.get("resolution") if isinstance(entry, dict) else None
        if not isinstance(resolution, dict):
            problems.append(f"{where}: the package {key} has no `resolution`")
        elif "integrity" not in resolution:
            problems.append(f"{where}: the package {key} has no integrity value")
        elif not isinstance(resolution["integrity"], str) or not INTEGRITY.fullmatch(resolution["integrity"]):
            problems.append(f"{where}: the package {key} has an integrity value that is not sha256, sha384 or sha512")
        elif set(resolution) != {"integrity"}:
            others = sorted(set(resolution) - {"integrity"}, key=str)
            problems.append(
                f"{where}: the package {key} has the `resolution` keys {others}. The check allows `integrity` only"
            )
    for package in FRONTEND_PACKAGES:
        version, integrity = expected[package.name]
        key = f"{package.name}@{version}"
        if key not in packages:
            problems.append(f"{where}: `packages` has no {key} ({package.version_key} in tools/versions.env)")
            continue
        resolution = packages[key].get("resolution") if isinstance(packages[key], dict) else None
        found = resolution.get("integrity") if isinstance(resolution, dict) else None
        if found != integrity:
            problems.append(
                f"{where}: the integrity value of {key} is {found}, but {package.integrity_key} in tools/versions.env is {integrity}"
            )
    snapshots = lock.get("snapshots")
    if snapshots is not None:
        if not isinstance(snapshots, dict):
            problems.append(f"{where}: `snapshots` is not a mapping")
        else:
            for key in snapshots:
                if str(key).split("(", 1)[0] not in packages:
                    problems.append(f"{where}: `snapshots` has {key!r}, which is not in `packages`")
    return problems


def check_frontend(root: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the pnpm module frontend/ (see the header). Return a message for the log and the problems."""
    folder = root / "frontend"
    if not any((folder / name).exists() for name in FRONTEND_FILES):
        return "no pnpm module frontend/ (no package.json, no pnpm-workspace.yaml and no pnpm-lock.yaml)", []
    expected, problems = _frontend_versions(versions)
    for name in sorted(path.name for path in folder.iterdir()):
        if name in FRONTEND_FORBIDDEN_FILES:
            problems.append(
                f"Frontend: {folder / name} is not allowed (it could change where pnpm gets the packages, or it makes a second lock file)"
            )
    for name in FRONTEND_FILES:
        if not (folder / name).is_file():
            problems.append(f"Frontend: {folder / name} does not exist (the module needs {', '.join(FRONTEND_FILES)})")
    if problems:
        return "", problems
    try:
        workspace = yaml.load((folder / "pnpm-workspace.yaml").read_text(encoding="utf-8"), Loader=_UniqueKeyLoader)
    except (OSError, yaml.YAMLError, TypeError, ValueError) as error:
        return "", [f"Frontend: {folder / 'pnpm-workspace.yaml'} cannot be read as YAML: {error}"]
    if workspace != {"packages": ["."]}:
        problems.append(
            f'Frontend: {folder / "pnpm-workspace.yaml"} is {workspace!r}, but it must be exactly `packages: ["."]` '
            "(a key such as `overrides`, `catalog` or `registry` changes the install)"
        )
    problems += _check_frontend_package_json(folder / "package.json", expected)
    problems += _check_frontend_lock(folder / "pnpm-lock.yaml", expected)
    note = (
        f"Frontend: {folder}: Kubb, Zod, TypeScript and the test tools "
        "(Vitest, Playwright, axe-core, fast-check, Vite), the mutation tool Stryker, the architecture tool "
        "ArchUniTS and the coverage provider of Vitest (@vitest/coverage-v8), package.json and lock file as in "
        "tools/versions.env"
    )
    return ("" if problems else note), problems


def check_caniuse_lite(root: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the tie of the transitive package caniuse-lite (see the header). Return a note and the problems.

    The lock file of frontend/ must resolve caniuse-lite to CANIUSE_LITE_VERSION of tools/versions.env (the rule X1
    of sbom.sh excludes the pinned version from the SBOM of the frontend). The package is transitive, so it has no
    entry in package.json and no integrity key; the lock file is the tie. A key that is missing, a lock file with
    no entry of the package, or an entry with another version stops the check (fail closed).
    """
    label = "Caniuse-lite pin"
    problems: list[str] = []
    version = versions.get(CANIUSE_LITE_VERSION_KEY, "")
    if CANIUSE_LITE_VERSION_KEY not in versions:
        problems.append(f"{CANIUSE_LITE_VERSION_KEY} is not in tools/versions.env")
    elif not EXACT_VERSION.fullmatch(version):
        problems.append(
            f"{CANIUSE_LITE_VERSION_KEY} in tools/versions.env is {version!r}, "
            "but it must be an exact version (no range, no tag)"
        )
    if problems:
        return "", problems
    lock = root / "frontend" / "pnpm-lock.yaml"
    if not lock.is_file():
        return f"{label}: no pnpm module frontend/ (no lock file to tie)", []
    try:
        documents = list(yaml.load_all(lock.read_text(encoding="utf-8"), Loader=_UniqueKeyLoader))
    except (OSError, yaml.YAMLError, TypeError, ValueError) as error:
        return "", [f"{label}: {lock} cannot be read as YAML: {error}"]
    if len(documents) != 1 or not isinstance(documents[0], dict):
        return "", [f"{label}: {lock} has not exactly one YAML document with a mapping"]
    packages = documents[0].get("packages")
    if not isinstance(packages, dict):
        return "", [f"{label}: {lock} has no `packages`"]
    found: list[str] = []
    for key in packages:
        parts = _split_package_key(str(key)) if isinstance(key, str) else None
        if parts is not None and parts[0] == CANIUSE_LITE_PACKAGE:
            found.append(parts[1])
    if not found:
        problems.append(
            f"{label}: {lock} has no caniuse-lite in `packages` (the transitive package of Stryker that the rule X1 "
            "excludes from the SBOM of the frontend)"
        )
    elif found != [version]:
        problems.append(
            f"{label}: {lock} has caniuse-lite {', '.join(found)} in `packages`, "
            f"but {CANIUSE_LITE_VERSION_KEY} in tools/versions.env is {version}"
        )
    if problems:
        return "", problems
    return f"{label}: {lock}: caniuse-lite {version}, the version of tools/versions.env", []


def _normalize_name(name: str) -> str:
    """The name of a Python package after the normalization of PEP 503."""
    return re.sub(r"[-_.]+", "-", name).lower()


def _python_lock_entries(path: Path) -> tuple[list[tuple[int, str, str]], list[str]]:
    """Read a lock file. Return the entries (line, normalized name, version) and the problems.

    A line that ends with a backslash continues in the next line, and both lines are one entry.
    """
    problems: list[str] = []
    entries: list[tuple[int, str, str]] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return [], [f"Python lock: cannot read {path}: {error}"]
    logical: list[tuple[int, str]] = []
    pending: tuple[int, str] | None = None
    for number, line in enumerate(lines, start=1):
        if pending is not None:
            joined = pending[1] + " " + line.strip()
        else:
            joined = line
        if joined.endswith("\\"):
            pending = (pending[0] if pending is not None else number, joined[:-1].rstrip())
            continue
        logical.append((pending[0] if pending is not None else number, joined))
        pending = None
    if pending is not None:
        problems.append(f"Python lock: {path}, line {pending[0]}: the file ends after a backslash")
    for number, line in logical:
        text = line.strip()
        if not text or text.startswith("#"):
            continue
        requirement, separator, hashes = text.partition(" --hash=")
        match = LOCK_REQUIREMENT.fullmatch(requirement)
        hash_values = ("--hash=" + hashes).split() if separator else []
        if not match or not hash_values or not all(LOCK_HASH.fullmatch(value) for value in hash_values):
            problems.append(
                f"Python lock: {path}, line {number}: {text[:90]!r} is not an exact pin `name==version` with "
                "`--hash=sha256:<64 hexadecimal characters>` values (a package with no hash, a range, a URL, a path, "
                "a VCS source, an editable entry and an option are not allowed)"
            )
            continue
        entries.append((number, _normalize_name(match.group("name")), match.group("version")))
    if len(problems) > MAX_LOCK_PROBLEMS:
        # One broken entry can make a problem for each of its hash lines. The first ones are enough to find the place.
        hidden = len(problems) - MAX_LOCK_PROBLEMS
        problems = problems[:MAX_LOCK_PROBLEMS] + [
            f"Python lock: {path}: and {hidden} more line(s) that are not correct"
        ]
    return entries, problems


def check_python_locks(lock_dir: Path, versions: dict[str, str]) -> tuple[str, list[str]]:
    """Check the lock files of the Python tools (feat-22-python-tools-lockfile). Return a message and the problems."""
    problems: list[str] = []
    if not lock_dir.is_dir():
        return "", [f"Python lock: the folder {lock_dir} (the lock files of the Python tools) does not exist"]
    for name in sorted(path.name for path in lock_dir.iterdir()):
        if name not in PYTHON_LOCK_FILES:
            problems.append(
                f"Python lock: {lock_dir / name} is not allowed. The folder has only {sorted(PYTHON_LOCK_FILES)}"
            )
    notes: list[str] = []
    total = 0
    for lock_name, package, key in PYTHON_LOCKS:
        path = lock_dir / lock_name
        version = versions.get(key, "")
        if not version:
            problems.append(f"{key} is not in tools/versions.env")
        elif not EXACT_VERSION.fullmatch(version):
            problems.append(f"{key} in tools/versions.env is {version!r}, but it must be an exact version")
        if not path.is_file():
            problems.append(f"Python lock: {path} does not exist")
            continue
        entries, found = _python_lock_entries(path)
        problems += found
        total += len(entries)
        if not entries and not found:
            problems.append(f"Python lock: {path} has no package")
        tool_versions = sorted({entry_version for _, entry, entry_version in entries if entry == package})
        if not tool_versions:
            if entries:
                problems.append(f"Python lock: {path} has no entry of {package}")
        elif version and tool_versions != [version]:
            problems.append(
                f"Python lock: {path} has {package} {', '.join(tool_versions)}, but {key} in tools/versions.env is {version}"
            )
        notes.append(f"{package} {version}")
    note = f"Python locks: {lock_dir}: {len(PYTHON_LOCKS)} lock files, {total} entries ({', '.join(notes)}), exact pins with hashes"
    return ("" if problems else note), problems


def main(argv: list[str]) -> int:
    if len(argv) != 10:
        print(
            "Usage: check_pins.py <versions.env> <workflows-dir> <allowed-actions> <project-root> <sbom-tool-dir> "
            "<python-lock-dir> <lint-tool-dir> <breaking-tool-dir> <generator-tool-dir>",
            file=sys.stderr,
        )
        return 2
    try:
        versions = read_versions(Path(argv[1]))
        allowed = read_allowed(Path(argv[3]))
        problems: list[str] = []
        total = 0
        for path, workflow in load_workflows(Path(argv[2])):
            count, found = check_file(path, workflow, versions, allowed)
            print(f"{path}: {count} `uses:` step(s), {len(found)} problem(s)")
            total += count
            problems += found
        note, maven_problems = check_maven(Path(argv[4]), versions)
        print(f"Maven pin: {note or str(len(maven_problems)) + ' problem(s)'}")
        problems += maven_problems
        note, sbom_problems = check_pnpm_tool(CDXGEN, Path(argv[5]), versions)
        print(f"SBOM tool pin: {note or str(len(sbom_problems)) + ' problem(s)'}")
        problems += sbom_problems
        note, lint_problems = check_pnpm_tool(SPECTRAL, Path(argv[7]), versions)
        print(f"Lint tool pin: {note or str(len(lint_problems)) + ' problem(s)'}")
        problems += lint_problems
        note, breaking_problems = check_oasdiff(Path(argv[8]), versions)
        print(f"Breaking-changes tool pin: {note or str(len(breaking_problems)) + ' problem(s)'}")
        problems += breaking_problems
        note, generator_problems = check_generator_plugin(Path(argv[4]), Path(argv[9]), versions)
        print(f"Generator plugin pin: {note or str(len(generator_problems)) + ' problem(s)'}")
        problems += generator_problems
        note, test_pin_problems = check_maven_test_pins(Path(argv[4]), versions)
        print(f"Maven test pins: {note or str(len(test_pin_problems)) + ' problem(s)'}")
        problems += test_pin_problems
        note, frontend_problems = check_frontend(Path(argv[4]), versions)
        print(f"Frontend pin: {note or str(len(frontend_problems)) + ' problem(s)'}")
        problems += frontend_problems
        note, caniuse_problems = check_caniuse_lite(Path(argv[4]), versions)
        print(f"Caniuse-lite pin: {note or str(len(caniuse_problems)) + ' problem(s)'}")
        problems += caniuse_problems
        note, python_problems = check_python_locks(Path(argv[6]), versions)
        print(f"Python lock pin: {note or str(len(python_problems)) + ' problem(s)'}")
        problems += python_problems
    except GateError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if problems:
        for problem in problems:
            print(f"STOP {problem}")
        print(f"RESULT: STOP. {len(problems)} problem(s).")
        return 1
    print(
        f"RESULT: PASS. {total} `uses:` step(s) with a full SHA, a comment and the versions of tools/versions.env. "
        "The lock files of cdxgen and of Spectral, the checksum of oasdiff, the version and the jar checksum of the "
        "generator plugin, the jar checksum of the SBOM plugin, the versions of the test tools of the Maven module, "
        "the module frontend/ (and the tie of caniuse-lite of its lock file) and the lock files of the Python tools are "
        "the ones of tools/versions.env."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
