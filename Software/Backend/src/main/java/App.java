import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class App {
    private Connection conn;

    public static void main(String[] args) {

        try {
            conn = DriverManager.getConnection("jdbc:sqlite:" + Paths.get("./data/testdb.sqlite"));
        } catch (SQLException e) {
            System.err.println(e.getMessage());
        }

    }
}
