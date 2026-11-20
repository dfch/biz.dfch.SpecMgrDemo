package biz.dfch.specmgrdemo.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import org.springframework.lang.Nullable;
import java.time.OffsetDateTime;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;


import java.util.*;
import jakarta.annotation.Generated;

/**
 * The information of the system (the identification and the notice of the license).
 */

@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", comments = "Generator version: 7.27.0")
public class Info {

  private String version;

  private String commit;

  private String copyright;

  private String repository;

  private String license;

  public Info() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public Info(String version, String commit, String copyright, String repository, String license) {
    this.version = version;
    this.commit = commit;
    this.copyright = copyright;
    this.repository = repository;
    this.license = license;
  }

  public Info version(String version) {
    this.version = version;
    return this;
  }

  /**
   * The version of the build.
   * @return version
   */
  @NotNull 
  @JsonProperty("version")
  public String getVersion() {
    return version;
  }

  @JsonProperty("version")
  public void setVersion(String version) {
    this.version = version;
  }

  public Info commit(String commit) {
    this.commit = commit;
    return this;
  }

  /**
   * The commit of the source of the build.
   * @return commit
   */
  @NotNull 
  @JsonProperty("commit")
  public String getCommit() {
    return commit;
  }

  @JsonProperty("commit")
  public void setCommit(String commit) {
    this.commit = commit;
  }

  public Info copyright(String copyright) {
    this.copyright = copyright;
    return this;
  }

  /**
   * The copyright holder of the system.
   * @return copyright
   */
  @NotNull 
  @JsonProperty("copyright")
  public String getCopyright() {
    return copyright;
  }

  @JsonProperty("copyright")
  public void setCopyright(String copyright) {
    this.copyright = copyright;
  }

  public Info repository(String repository) {
    this.repository = repository;
    return this;
  }

  /**
   * The address of the repository of the system.
   * @return repository
   */
  @NotNull 
  @JsonProperty("repository")
  public String getRepository() {
    return repository;
  }

  @JsonProperty("repository")
  public void setRepository(String repository) {
    this.repository = repository;
  }

  public Info license(String license) {
    this.license = license;
    return this;
  }

  /**
   * The license of the system.
   * @return license
   */
  @NotNull 
  @JsonProperty("license")
  public String getLicense() {
    return license;
  }

  @JsonProperty("license")
  public void setLicense(String license) {
    this.license = license;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    Info info = (Info) o;
    return Objects.equals(this.version, info.version) &&
        Objects.equals(this.commit, info.commit) &&
        Objects.equals(this.copyright, info.copyright) &&
        Objects.equals(this.repository, info.repository) &&
        Objects.equals(this.license, info.license);
  }

  @Override
  public int hashCode() {
    return Objects.hash(version, commit, copyright, repository, license);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class Info {\n");
    sb.append("    version: ").append(toIndentedString(version)).append("\n");
    sb.append("    commit: ").append(toIndentedString(commit)).append("\n");
    sb.append("    copyright: ").append(toIndentedString(copyright)).append("\n");
    sb.append("    repository: ").append(toIndentedString(repository)).append("\n");
    sb.append("    license: ").append(toIndentedString(license)).append("\n");
    sb.append("}");
    return sb.toString();
  }

  /**
   * Convert the given object to string with each line indented by 4 spaces
   * (except the first line).
   */
  private String toIndentedString(@Nullable Object o) {
    return o == null ? "null" : o.toString().replace("\n", "\n    ");
  }
}

