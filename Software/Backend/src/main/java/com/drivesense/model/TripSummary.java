package com.drivesense.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;

import java.time.LocalDateTime;

public class TripSummary {
    private int id;
    private int profileId;
    @Min(value = 1, message = "Vehicle ID muss größer als 0 sein")
    private int vehicleId;
    @Min(value = 1, message = "Protocol ID muss größer als 0 sein")
    private int protocolId;
    @NotNull(message = "Startzeit darf nicht null sein")
    @PastOrPresent(message = "Startzeit darf nicht in der Zukunft liegen")
    private LocalDateTime startTime;
    @NotNull(message = "Endzeit darf nicht null sein")
    @PastOrPresent(message = "Endzeit darf nicht in der Zukunft liegen")
    private LocalDateTime endTime;
    @Min(value = 0, message = "Distanz darf nicht negativ sein")
    private double distance;
    @Min(value = 0, message = "Dauer darf nicht negativ sein")
    private long durationSeconds;
    private String roadSurfaceConditions;
    private String type;

    private String startPoint;
    private String endPoint;
    private String furthestPoint;
    private String roadSnapStatus = "PENDING";
    private int roadSnapAttempts;
    private String roadSnapLastError;
    private LocalDateTime roadSnapNextRetryAt;
    private LocalDateTime roadSnapUpdatedAt;

    @Min(value = 0, message = "Start-Kilometerstand darf nicht negativ sein")
    private int startMileage;
    @Min(value = 0, message = "End-Kilometerstand darf nicht negativ sein")
    private int endMileage;


    public TripSummary(){}

    public TripSummary(int profileId, int vehicleId, int protocolId, LocalDateTime startTime, LocalDateTime endTime, double distance, String roadSurfaceConditions, String type) {
        this(profileId, vehicleId, protocolId, startTime, endTime, distance, roadSurfaceConditions, type, 0, 0);
    }

    public TripSummary(int profileId, int vehicleId, int protocolId, LocalDateTime startTime, LocalDateTime endTime, double distance, String roadSurfaceConditions, String type, int startMileage, int endMileage) {
        this.profileId = profileId;
        this.vehicleId = vehicleId;
        this.protocolId = protocolId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.distance = distance;
        this.roadSurfaceConditions = roadSurfaceConditions;
        this.type = type;
        this.startMileage = startMileage;
        this.endMileage = endMileage;
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

    public int getProtocolId() {
        return protocolId;
    }

    public void setProtocolId(int protocolId) {
        this.protocolId = protocolId;
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

    public long getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(long durationSeconds) {
        this.durationSeconds = durationSeconds;
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

    public String getStartPoint() {
        return startPoint;
    }

    public void setStartPoint(String startPoint) {
        this.startPoint = startPoint;
    }

    public String getEndPoint() {
        return endPoint;
    }

    public void setEndPoint(String endPoint) {
        this.endPoint = endPoint;
    }

    public String getFurthestPoint() {
        return furthestPoint;
    }

    public void setFurthestPoint(String furthestPoint) {
        this.furthestPoint = furthestPoint;
    }

    public int getStartMileage() {
        return startMileage;
    }

    public void setStartMileage(int startMileage) {
        this.startMileage = startMileage;
    }

    public int getEndMileage() {
        return endMileage;
    }

    public void setEndMileage(int endMileage) {
        this.endMileage = endMileage;
    }

    public String getRoadSnapStatus() {
        return roadSnapStatus;
    }

    public void setRoadSnapStatus(String roadSnapStatus) {
        this.roadSnapStatus = roadSnapStatus;
    }

    public int getRoadSnapAttempts() {
        return roadSnapAttempts;
    }

    public void setRoadSnapAttempts(int roadSnapAttempts) {
        this.roadSnapAttempts = roadSnapAttempts;
    }

    public String getRoadSnapLastError() {
        return roadSnapLastError;
    }

    public void setRoadSnapLastError(String roadSnapLastError) {
        this.roadSnapLastError = roadSnapLastError;
    }

    public LocalDateTime getRoadSnapNextRetryAt() {
        return roadSnapNextRetryAt;
    }

    public void setRoadSnapNextRetryAt(LocalDateTime roadSnapNextRetryAt) {
        this.roadSnapNextRetryAt = roadSnapNextRetryAt;
    }

    public LocalDateTime getRoadSnapUpdatedAt() {
        return roadSnapUpdatedAt;
    }

    public void setRoadSnapUpdatedAt(LocalDateTime roadSnapUpdatedAt) {
        this.roadSnapUpdatedAt = roadSnapUpdatedAt;
    }

    @Override
    public String toString() {
        return "Trip: " +
                "id: " + id +
                ", profile_id: " + profileId +
                ", vehicle_id: " + vehicleId +
                ", protocol_id: " + protocolId +
                ", startTime: " + startTime +
                ", endTime: " + endTime +
                ", distance: " + distance +
                ", durationSeconds: " + durationSeconds +
                ", road_surface_conditions: '" + roadSurfaceConditions + '\'' +
                ", type: '" + type + '\'' +
                ", startPoint: " + startPoint +
                ", furthestPoint: " + furthestPoint +
                ", endPoint: " + endPoint +
                ", startMileage: " + startMileage +
                ", endMileage: " + endMileage +
                ", roadSnapStatus: " + roadSnapStatus;
    }
}
