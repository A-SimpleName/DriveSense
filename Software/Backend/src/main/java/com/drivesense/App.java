package com.drivesense;

import com.drivesense.service.GeocodingService;
import com.drivesense.service.WeatherService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App {
    public static void main(String[] args) {
       SpringApplication.run(App.class, args);
    }
}