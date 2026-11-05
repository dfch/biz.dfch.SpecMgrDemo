package biz.dfch.specmgrdemo.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonValue;
import java.time.OffsetDateTime;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;


import java.util.*;
import jakarta.annotation.Generated;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/**
 * The code of an error. The frontend shows the text for each code.
 */

@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", comments = "Generator version: 7.27.0")
public enum ErrorCode {
  
  NOT_FOUND("not_found"),
  
  VALIDATION_FAILED("validation_failed"),
  
  RATE_LIMITED("rate_limited"),
  
  INTERNAL_ERROR("internal_error"),
  
  SERVICE_UNAVAILABLE("service_unavailable");

  private final String value;

  ErrorCode(String value) {
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
  public static ErrorCode fromValue(String value) {
    for (ErrorCode b : ErrorCode.values()) {
      if (b.value.equals(value)) {
        return b;
      }
    }
    throw new IllegalArgumentException("Unexpected value '" + value + "'");
  }
}

