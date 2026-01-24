package db;

import app.App;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

public class UserDao {
    public static void insertUser() {
        try (Connection conn = App.getConnection();
        Statement st = conn.prepareStatement("INSERT fname, lastname, user, ")) {

        } catch (SQLException e) {

        }
    }
}
