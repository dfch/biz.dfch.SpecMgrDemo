package biz.dfch.specmgrdemo.testtools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import biz.dfch.specmgrdemo.api.StatusApi;
import biz.dfch.specmgrdemo.model.ErrorCode;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * Unit tests of the generated code with JUnit (feat-7-verification-architecture-tools, Task 110.100, ACC-002: the
 * case that is successful). The module has no product code, so the tests exercise the generated code (the enum
 * ErrorCode and the interface StatusApi).
 */
class ErrorCodeTest {

    /**
     * The five codes of the contract, with the value of each one.
     */
    static Stream<Arguments> codes() {
        return Stream.of(
            Arguments.of(ErrorCode.NOT_FOUND, "not_found"),
            Arguments.of(ErrorCode.VALIDATION_FAILED, "validation_failed"),
            Arguments.of(ErrorCode.RATE_LIMITED, "rate_limited"),
            Arguments.of(ErrorCode.INTERNAL_ERROR, "internal_error"),
            Arguments.of(ErrorCode.SERVICE_UNAVAILABLE, "service_unavailable"));
    }

    @ParameterizedTest(name = "the value of {0} is {1}")
    @MethodSource("codes")
    void theValueRoundTrips(ErrorCode code, String value) {
        assertEquals(value, code.getValue());
        assertEquals(code, ErrorCode.fromValue(value));
    }

    @Test
    void theListHasTheFiveCodes() {
        assertEquals(5, ErrorCode.values().length);
    }

    @Test
    void aValueThatIsNotACodeIsAFinding() {
        IllegalArgumentException error =
            assertThrows(IllegalArgumentException.class, () -> ErrorCode.fromValue("nope"));
        assertTrue(error.getMessage().contains("nope"));
    }

    @Test
    void thePathOfTheStatusApiIsThePathOfTheContract() {
        assertEquals("/status", StatusApi.PATH_GET_STATUS);
    }
}
