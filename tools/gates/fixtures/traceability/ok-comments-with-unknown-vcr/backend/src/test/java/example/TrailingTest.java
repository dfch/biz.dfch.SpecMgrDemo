package example;

class TrailingTest {

    void aTest() {
        System.out.println("x"); // vcr:99999999-9999-4999-8999-999999999999
        System.out.println("y"); /* vcr:99999999-9999-4999-8999-999999999999 */
        System.out.println("z"); // a "quote" and vcr:99999999-9999-4999-8999-999999999999
    }
}
