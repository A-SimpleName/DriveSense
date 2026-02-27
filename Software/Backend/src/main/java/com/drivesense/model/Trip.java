package com.drivesense.model;

import java.time.LocalDateTime;

public class Trip {
    private int id;
    private int user_id;
    private int car_id;
    private LocalDateTime starttime;
    private LocalDateTime endtime;
    private double distance;
    private String weather_main;
    private String type;

    public Trip(){}

    public Trip(int user_id, int car_id, LocalDateTime starttime, LocalDateTime endtime, double distance, String weather_main, String type) {
        this.user_id = user_id;
        this.car_id = car_id;
        this.starttime = starttime;
        this.endtime = endtime;
        this.distance = distance;
        this.weather_main = weather_main;
        this.type = type;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUser_id() {
        return user_id;
    }

    public void setUser_id(int user_id) {
        this.user_id = user_id;
    }

    public int getCar_id() {
        return car_id;
    }

    public void setCar_id(int car_id) {
        this.car_id = car_id;
    }

    public LocalDateTime getStarttime() {
        return starttime;
    }

    public void setStarttime(LocalDateTime starttime) {
        this.starttime = starttime;
    }

    public LocalDateTime getEndtime() {
        return endtime;
    }

    public void setEndtime(LocalDateTime endtime) {
        this.endtime = endtime;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }

    public String getWeather_main() {
        return weather_main;
    }

    public void setWeather_main(String weather_main) {
        this.weather_main = weather_main;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    @Override
    public String toString() {
        return "Tracking: " +
                "id: " + id +
                ", user_id: " + user_id +
                ", car_id: " + car_id +
                ", starttime: " + starttime +
                ", endtime: " + endtime +
                ", distance: " + distance +
                ", weather_main: '" + weather_main + '\'' +
                ", type: '" + type + '\'';
    }
}
