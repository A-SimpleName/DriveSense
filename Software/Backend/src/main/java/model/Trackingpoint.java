package model;

import java.time.LocalDateTime;

public class Trackingpoint {
    private int id;
    private int tracking_id;
    private double lat;
    private double lng;
    private double accuracy;
    private double speed;
    private double bearing;
    private LocalDateTime timestamp;

    public Trackingpoint(){}

    public Trackingpoint(int tracking_id, double lat, double accuracy, double lng, double speed, double bearing, LocalDateTime timestamp) {
        this.tracking_id = tracking_id;
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

    public int getTracking_id() {
        return tracking_id;
    }

    public void setTracking_id(int tracking_id) {
        this.tracking_id = tracking_id;
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
                ", tracking_id: " + tracking_id +
                ", lat: " + lat +
                ", lng: " + lng +
                ", accuracy: " + accuracy +
                ", speed: " + speed +
                ", bearing: " + bearing +
                ", timestamp: " + timestamp;
    }
}
