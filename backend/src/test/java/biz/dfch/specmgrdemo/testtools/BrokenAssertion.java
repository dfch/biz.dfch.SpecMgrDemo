package biz.dfch.specmgrdemo.testtools;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

/**
 * The case that is not successful for JUnit (feat-7-verification-architecture-tools, Task 110.100, ACC-002): an
 * assertion that is wrong on purpose. The name has no suffix "Test", so the default run of surefire does not start
 * it, and the committed run of the tests is green. The recipe "test-unit-backend" (tools/gates/test-unit-backend.sh)
 * runs this class with "-Dtest=BrokenAssertion" and stops for it: JUnit reports the failed assertion.
 */
class BrokenAssertion {

    @Test
    void theAssertionIsWrong() {
        assertEquals(3, 1 + 1, "the sum of 1 and 1 is 3");
    }
}
