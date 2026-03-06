package com.drivesense;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {

    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }

<<<<<<< HEAD
    public static Connection getConnection() throws SQLException {
        String url = "jdbc:mysql://172.16.100.202:3306/drivesense";
        String user = "javauser";
        String password = "DriveSenseJava";

        return DriverManager.getConnection(url, user, password);
    }
}
=======
}
>>>>>>> Christof
