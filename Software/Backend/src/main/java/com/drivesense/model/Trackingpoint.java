package com.drivesense.model;

import jakarta.validation.constraints.*;

import java.time.LocalDateTime;

public class Trackingpoint {
    private int id;
    @Min(value = 1, message = "Trip ID muss größer als 0 sein")
    private int tripId;
    @NotNull(message = "Latitude darf nicht null sein")
    @DecimalMin(value = "-90.0", message = "Latitude muss zwischen -90 und 90 sein")
    @DecimalMax(value = "90.0", message = "Latitude muss zwischen -90 und 90 sein")
    private double lat;
    @NotNull(message = "Longitude darf nicht null sein")
    @DecimalMin(value = "-180.0", message = "Longitude muss zwischen -180 und 180 sein")
    @DecimalMax(value = "180.0", message = "Longitude muss zwischen -180 und 180 sein")
    private double lng;
    private double accuracy;
    private double speed;
    private double bearing;
    @PastOrPresent(message = "Timestamp darf nicht in der Zukunft liegen")
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
