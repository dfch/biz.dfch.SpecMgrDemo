package biz.dfch.specmgrdemo.testtools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import biz.dfch.specmgrdemo.model.ErrorCode;
import net.jqwik.api.Arbitrary;
import net.jqwik.api.Arbitraries;
import net.jqwik.api.ForAll;
import net.jqwik.api.Property;
import net.jqwik.api.Provide;

/**
 * Property tests of the generated code with jqwik (feat-7-verification-architecture-tools, Task 110.130, ACC-002:
 * the case that is successful). The properties run on the JUnit Platform next to the JUnit tests.
 */
class ErrorCodePropertyTest {

    /**
     * The codes of the generated enum (the arbitrary of jqwik for an enum).
     */
    @Provide
    Arbitrary<ErrorCode> codes() {
        return Arbitraries.of(ErrorCode.values());
    }

    @Property(tries = 50)
    void theValueRoundTripsThroughFromValue(@ForAll("codes") ErrorCode code) {
        assertEquals(code, ErrorCode.fromValue(code.getValue()));
        assertEquals(code.getValue(), ErrorCode.fromValue(code.getValue()).getValue());
    }

    @Property(tries = 50)
    void theListHasNoDuplicateValues(@ForAll("codes") ErrorCode code) {
        long count = 0L;
        for (ErrorCode other : ErrorCode.values()) {
            if (other.getValue().equals(code.getValue())) {
                count++;
            }
        }
        assertEquals(1L, count);
    }

    /**
     * A small function of the test: the number of characters of the text that are no letter.
     */
    static int nonLetters(String text) {
        int count = 0;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            boolean letter = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
            if (!letter) {
                count++;
            }
        }
        return count;
    }

    @Property(tries = 200)
    void theCountIsBetweenZeroAndTheLength(@ForAll String text) {
        int count = nonLetters(text);
        assertTrue(count >= 0 && count <= text.length(), "the count of nonLetters is in [0, length]");
        assertEquals(nonLetters(text), count);
    }
}
