package db;

import app.App;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;


public class ProtocolDao {

    public static void saveProtocol() {
        try (Connection conn = App.getConnection();
             Statement st = conn.prepareStatement("INSERT ")) {

        } catch (SQLException e) {

        }
    }
}
