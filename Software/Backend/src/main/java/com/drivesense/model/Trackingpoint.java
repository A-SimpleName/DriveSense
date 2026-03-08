package com.drivesense.model;

import java.time.LocalDateTime;

public class Trackingpoint {
    private int id;
    private int tripId;
    private double lat;
    private double lng;
    private double accuracy;
    private double speed;
    private double bearing;
    private LocalDateTime timestamp;

    public Trackingpoint(){}

    public Trackingpoint(int tripId, double lat, double accuracy, double lng, double speed, double bearing, LocalDateTime timestamp) {
        this.tripId = tripId;
        this.lat = lat;
        this.accuracy = accuracy;
        this.lng = lng;
        this.speed = speed;
        this.bearing = bearing;
        this.timestamp = timestamp;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getTripId() {
        return this.tripId;
    }

    public void setTripId(int tripId) {
        this.tripId = tripId;
    }

    public double getLat() {
        return lat;
    }

    public void setLat(double lat) {
        this.lat = lat;
    }

    public double getLng() {
        return lng;
    }

    public void setLng(double lng) {
        this.lng = lng;
    }

    public double getAccuracy() {
        return accuracy;
    }

    public void setAccuracy(double accuracy) {
        this.accuracy = accuracy;
    }

    public double getSpeed() {
        return speed;
    }

    public void setSpeed(double speed) {
        this.speed = speed;
    }

    public double getBearing() {
        return bearing;
    }

    public void setBearing(double bearing) {
        this.bearing = bearing;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    @Override
    public String toString() {
        return "Trackingpoint: " +
                "id: " + id +
                ", trip_id: " + tripId +
                ", lat: " + lat +
                ", lng: " + lng +
                ", accuracy: " + accuracy +
                ", speed: " + speed +
                ", bearing: " + bearing +
                ", timestamp: " + timestamp;
    }
}
