package example;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/* A block comment over some lines.
   The lines do not start with a star.
   vcr:33333333-3333-4333-8333-333333333333
*/
/**
 * @DisplayName("the javadoc has a quote and vcr:33333333-3333-4333-8333-333333333333")
 */
class ExampleTest {

    @Test
    @DisplayName("a test with no vcr in the name") // vcr:33333333-3333-4333-8333-333333333333
    void theStatusHasAState() {
        System.out.println("x"); // "vcr:33333333-3333-4333-8333-333333333333"
    }
}
