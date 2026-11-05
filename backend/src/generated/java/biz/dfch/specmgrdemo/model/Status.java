package biz.dfch.specmgrdemo.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.time.OffsetDateTime;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.lang.Nullable;
import java.time.OffsetDateTime;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;


import java.util.*;
import jakarta.annotation.Generated;

/**
 * The status of the system.
 */

@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", comments = "Generator version: 7.27.0")
public class Status {

  /**
   * The condition of the system.
   */
  public enum StateEnum {
    UP("up"),
    
    DEGRADED("degraded");

    private final String value;

    StateEnum(String value) {
      this.value = value;
    }

    @JsonValue
    public String getValue() {
      return value;
    }

    @Override
    public String toString() {
      return String.valueOf(value);
    }

    @JsonCreator
    public static StateEnum fromValue(String value) {
      for (StateEnum b : StateEnum.values()) {
        if (b.value.equals(value)) {
          return b;
        }
      }
      throw new IllegalArgumentException("Unexpected value '" + value + "'");
    }
  }

  private StateEnum state;

  @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
  private OffsetDateTime checkedAt;

  public Status() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public Status(StateEnum state, OffsetDateTime checkedAt) {
    this.state = state;
    this.checkedAt = checkedAt;
  }

  public Status state(StateEnum state) {
    this.state = state;
    return this;
  }

  /**
   * The condition of the system.
   * @return state
   */
  @NotNull 
  @JsonProperty("state")
  public StateEnum getState() {
    return state;
  }

  @JsonProperty("state")
  public void setState(StateEnum state) {
    this.state = state;
  }

  public Status checkedAt(OffsetDateTime checkedAt) {
    this.checkedAt = checkedAt;
    return this;
  }

  /**
   * The time of the check.
   * @return checkedAt
   */
  @NotNull @Valid 
  @JsonProperty("checkedAt")
  public OffsetDateTime getCheckedAt() {
    return checkedAt;
  }

  @JsonProperty("checkedAt")
  public void setCheckedAt(OffsetDateTime checkedAt) {
    this.checkedAt = checkedAt;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    Status status = (Status) o;
    return Objects.equals(this.state, status.state) &&
        Objects.equals(this.checkedAt, status.checkedAt);
  }

  @Override
  public int hashCode() {
    return Objects.hash(state, checkedAt);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class Status {\n");
    sb.append("    state: ").append(toIndentedString(state)).append("\n");
    sb.append("    checkedAt: ").append(toIndentedString(checkedAt)).append("\n");
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

