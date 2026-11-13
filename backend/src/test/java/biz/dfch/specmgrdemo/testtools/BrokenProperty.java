package biz.dfch.specmgrdemo.testtools;

import static org.junit.jupiter.api.Assertions.assertEquals;

import net.jqwik.api.ForAll;
import net.jqwik.api.Property;

/**
 * The case that is not successful for jqwik (feat-7-verification-architecture-tools, Task 110.130, ACC-002): a
 * property that is wrong on purpose. The name has no suffix "Test", so the default run of surefire does not start
 * it, and the committed run of the tests is green. The recipe "test-random-backend"
 * (tools/gates/test-random-backend.sh) runs this class with "-Dtest=BrokenProperty" and stops for it: jqwik finds
 * a counterexample of the property and reports it.
 */
class BrokenProperty {

    @Property(tries = 10)
    void theSumIsAlwaysThree(@ForAll int left, @ForAll int right) {
        assertEquals(3, left + right, "the sum of any two numbers is 3");
    }
}
