package biz.dfch.specmgrdemo.testtools;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.ResultSet;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * The case that is not successful for Testcontainers (feat-7-verification-architecture-tools, Task 110.100,
 * ACC-002): the container starts, the connection works, and the assertion against the real query result is wrong
 * on purpose. The name has no suffix IT, so the run of the integration tests ("-Dtest=*IT") does not start it, and
 * the committed run is green. The recipe "test-integration-backend" (tools/gates/test-integration-backend.sh) runs
 * this class with "-Dtest=BrokenPostgres" and stops for it: JUnit reports the failed assertion after the container
 * worked.
 */
@Testcontainers
class BrokenPostgres {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void theQueryResultIsWrong() throws Exception {
        try (Connection connection =
                DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
            Statement statement = connection.createStatement()) {
            try (ResultSet result = statement.executeQuery("SELECT 1")) {
                assertTrue(result.next());
                assertEquals(2, result.getInt(1), "the query SELECT 1 gives 1, not 2");
            }
        }
    }
}
