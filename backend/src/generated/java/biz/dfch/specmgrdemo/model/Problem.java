package biz.dfch.specmgrdemo.model;

import java.net.URI;
import java.util.Objects;
import biz.dfch.specmgrdemo.model.ErrorCode;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import org.springframework.lang.Nullable;
import java.time.OffsetDateTime;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;


import java.util.*;
import jakarta.annotation.Generated;

/**
 * An error, as RFC 9457 (Problem Details) describes it.
 */

@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", comments = "Generator version: 7.27.0")
public class Problem {

  private @Nullable String type;

  private @Nullable String title;

  private @Nullable Integer status;

  private @Nullable String detail;

  private @Nullable String instance;

  private ErrorCode code;

  private String traceId;

  public Problem() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public Problem(ErrorCode code, String traceId) {
    this.code = code;
    this.traceId = traceId;
  }

  public Problem type(@Nullable String type) {
    this.type = type;
    return this;
  }

  /**
   * A URI that names the type of the error.
   * @return type
   */
  
  @JsonProperty("type")
  public @Nullable String getType() {
    return type;
  }

  @JsonProperty("type")
  public void setType(@Nullable String type) {
    this.type = type;
  }

  public Problem title(@Nullable String title) {
    this.title = title;
    return this;
  }

  /**
   * A short summary of the type of the error, for logs and developers.
   * @return title
   */
  
  @JsonProperty("title")
  public @Nullable String getTitle() {
    return title;
  }

  @JsonProperty("title")
  public void setTitle(@Nullable String title) {
    this.title = title;
  }

  public Problem status(@Nullable Integer status) {
    this.status = status;
    return this;
  }

  /**
   * The HTTP status code of the response.
   * @return status
   */
  
  @JsonProperty("status")
  public @Nullable Integer getStatus() {
    return status;
  }

  @JsonProperty("status")
  public void setStatus(@Nullable Integer status) {
    this.status = status;
  }

  public Problem detail(@Nullable String detail) {
    this.detail = detail;
    return this;
  }

  /**
   * A note about this error, for logs and developers.
   * @return detail
   */
  
  @JsonProperty("detail")
  public @Nullable String getDetail() {
    return detail;
  }

  @JsonProperty("detail")
  public void setDetail(@Nullable String detail) {
    this.detail = detail;
  }

  public Problem instance(@Nullable String instance) {
    this.instance = instance;
    return this;
  }

  /**
   * A URI that names this occurrence of the error.
   * @return instance
   */
  
  @JsonProperty("instance")
  public @Nullable String getInstance() {
    return instance;
  }

  @JsonProperty("instance")
  public void setInstance(@Nullable String instance) {
    this.instance = instance;
  }

  public Problem code(ErrorCode code) {
    this.code = code;
    return this;
  }

  /**
   * Get code
   * @return code
   */
  @NotNull @Valid 
  @JsonProperty("code")
  public ErrorCode getCode() {
    return code;
  }

  @JsonProperty("code")
  public void setCode(ErrorCode code) {
    this.code = code;
  }

  public Problem traceId(String traceId) {
    this.traceId = traceId;
    return this;
  }

  /**
   * The trace identifier of OpenTelemetry (32 lower case hexadecimal characters). It links the response to the trace of the request.
   * @return traceId
   */
  @NotNull @Pattern(regexp = "^[0-9a-f]{32}$") 
  @JsonProperty("traceId")
  public String getTraceId() {
    return traceId;
  }

  @JsonProperty("traceId")
  public void setTraceId(String traceId) {
    this.traceId = traceId;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    Problem problem = (Problem) o;
    return Objects.equals(this.type, problem.type) &&
        Objects.equals(this.title, problem.title) &&
        Objects.equals(this.status, problem.status) &&
        Objects.equals(this.detail, problem.detail) &&
        Objects.equals(this.instance, problem.instance) &&
        Objects.equals(this.code, problem.code) &&
        Objects.equals(this.traceId, problem.traceId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(type, title, status, detail, instance, code, traceId);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class Problem {\n");
    sb.append("    type: ").append(toIndentedString(type)).append("\n");
    sb.append("    title: ").append(toIndentedString(title)).append("\n");
    sb.append("    status: ").append(toIndentedString(status)).append("\n");
    sb.append("    detail: ").append(toIndentedString(detail)).append("\n");
    sb.append("    instance: ").append(toIndentedString(instance)).append("\n");
    sb.append("    code: ").append(toIndentedString(code)).append("\n");
    sb.append("    traceId: ").append(toIndentedString(traceId)).append("\n");
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

