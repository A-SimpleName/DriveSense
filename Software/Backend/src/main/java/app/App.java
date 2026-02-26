package app;

import db.AccountDao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class App {
    public static void main(String[] args) {
        System.out.println(AccountDao.findAll());
    }

    public static Connection getConnection() throws SQLException {
        String url = "jdbc:mysql://172.16.100.202:3306/drivesense";
        String user = "javauser";
        String password = "DriveSenseJava";

        return DriverManager.getConnection(url, user, password);
    }
}
