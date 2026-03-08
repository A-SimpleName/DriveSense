package com.drivesense.model;

import java.time.LocalDateTime;

public class TripSummary {
    private int id;
    private int profileId;
    private int vehicleId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private double distance;
    private String roadSurfaceConditions;
    private String type;

    public TripSummary(){}

    public TripSummary(int profileId, int vehicleId, LocalDateTime startTime, LocalDateTime endTime, double distance, String roadSurfaceConditions, String type) {
        this.profileId = profileId;
        this.vehicleId = vehicleId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.distance = distance;
        this.roadSurfaceConditions = roadSurfaceConditions;
        this.type = type;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getProfileId() {
        return profileId;
    }

    public void setProfileId(int profileId) {
        this.profileId = profileId;
    }

    public int getVehicleId() {
        return vehicleId;
    }

    public void setVehicleId(int vehicleId) {
        this.vehicleId = vehicleId;
    }

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }

    public String getRoadSurfaceConditions() {
        return roadSurfaceConditions;
    }

    public void setRoadSurfaceConditions(String roadSurfaceConditions) {
        this.roadSurfaceConditions = roadSurfaceConditions;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    @Override
    public String toString() {
        return "Trip: " +
                "id: " + id +
                ", profile_id: " + profileId +
                ", vehicle_id: " + vehicleId +
                ", startTime: " + startTime +
                ", endTime: " + endTime +
                ", distance: " + distance +
                ", road_surface_conditions: '" + roadSurfaceConditions + '\'' +
                ", type: '" + type + '\'';
    }
}
