// feat-6-contracts-openapi-pipeline, Task 120.120 (REQ-006, ACC-008).
//
// Prints the values of the generated Java enum ErrorCode as a JSON array, in the order of the constants. It uses
// getValue() and not name(): the generator can add a number to the name of a constant if two names are the same, and the
// value is what goes over the wire. tools/gates/test-generate-gate.sh starts it with the source launcher of the JDK, with
// the classes of the Maven build on the class path:
//
//   java -cp backend/target/classes tools/generate/ErrorCodes.java
//
// The class path has no other library. The enum needs none of them to load (the annotations of Jackson are ignored if they
// are not there).
import biz.dfch.specmgrdemo.model.ErrorCode;
import java.util.stream.Collectors;
import java.util.Arrays;

public class ErrorCodes {
    public static void main(String[] arguments) {
        System.out.println(Arrays.stream(ErrorCode.values())
            .map(code -> "\"" + code.getValue() + "\"")
            .collect(Collectors.joining(",", "[", "]")));
    }
}
