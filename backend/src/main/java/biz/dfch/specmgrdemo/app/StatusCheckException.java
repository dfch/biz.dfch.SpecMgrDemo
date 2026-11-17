package biz.dfch.specmgrdemo.app;

/**
 * The failure of the check of the state (feat-9-walking-skeleton, Phase 200, Task 200.110): the system cannot
 * give its state (REQ 1ca335d7-969a-443e-9392-165fdeea99a0: "If the system cannot give its state, it sends an
 * error response"). The handler of the error (ProblemAdvice) maps the exception to the response of the error
 * (the media type application/problem+json, the code service_unavailable, the status 503, the trace
 * identifier, and no text in a language in the members code and traceId that the client uses).
 */
public class StatusCheckException extends RuntimeException {

  /**
   * Make the failure with the note of the log (English, for the log and the developer; the client does not show
   * the note).
   *
   * @param message the note of the log
   */
  public StatusCheckException(String message) {
    super(message);
  }
}
