package com.drivesense.app;


import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

    public static Connection getConnection() throws SQLException {
        String url = "jdbc:mysql://192.168.1.113:3306/drivesense";
        String user = "javauser";
        String password = "DriveSenseJava";

        return DriverManager.getConnection(url, user, password);
    }
}
