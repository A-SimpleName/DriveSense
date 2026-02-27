package app;

import db.*;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class App {
    public static void main(String[] args) {
        System.out.println(AccountDao.findAll());
        System.out.println(UserDao.findAll());
        System.out.println(VehicleDao.findAll());
        System.out.println(TrackingDao.findAll());
        System.out.println(TrackingpointDao.findAll());
        System.out.println(ProtocolDao.findAll());

    }

    public static Connection getConnection() throws SQLException {
        String url = "jdbc:mysql://192.168.1.113:3306/drivesense";
        String user = "javauser";
        String password = "DriveSenseJava";

        return DriverManager.getConnection(url, user, password);
    }
}
