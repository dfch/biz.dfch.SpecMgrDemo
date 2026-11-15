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
 * Integration tests with Testcontainers (feat-7-verification-architecture-tools, Task 110.100, ACC-002: the case
 * that is successful). One lightweight container (postgres:16-alpine, the PostgreSQL license, and not an image of
 * the SSPL/RSAL class) starts in this test, and the test connects to it with the JDBC driver and runs a trivial
 * query. The suffix IT keeps the class out of the default run of surefire (the unit run). The recipe
 * "test-integration-backend" (tools/gates/test-integration-backend.sh) runs it with "-Dtest=*IT".
 */
@Testcontainers
class PostgresIT {

    /**
     * The one container of the test. The default user, password and database of the image.
     */
    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void theQueryRunsInTheContainer() throws Exception {
        try (Connection connection =
                DriverManager.getConnection(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
            Statement statement = connection.createStatement()) {
            statement.execute("CREATE TABLE status (state TEXT)");
            statement.executeUpdate("INSERT INTO status (state) VALUES ('up')");
            try (ResultSet result = statement.executeQuery("SELECT state FROM status")) {
                assertTrue(result.next());
                assertEquals("up", result.getString(1));
            }
        }
    }
}
