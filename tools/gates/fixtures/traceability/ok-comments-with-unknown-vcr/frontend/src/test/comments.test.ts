/* A block comment over some lines.
   The lines do not start with a star.
   vcr:99999999-9999-4999-8999-999999999999
*/
foo("x"); // vcr:99999999-9999-4999-8999-999999999999
foo("y"); /* vcr:99999999-9999-4999-8999-999999999999 */
foo("z"); // a 'quote' and vcr:99999999-9999-4999-8999-999999999999
