package com.drivesense.dto.response;

import java.time.LocalDateTime;

public class TripSummaryDto {
    private int id;
    private LocalDateTime startTime;
    private int startMileage;
    private int endMileage;
    private String accountFname;
    private String accountLname;
    private String vehicleModel;
    private String licenseplate;
    private String startPoint;
    private String furthestPoint;
    private String endPoint;
    private int distance;
    private String roadSurfaceConditions;
    private String type;

    public TripSummaryDto () {

    }

    public String getFurthestPoint() {
        return furthestPoint;
    }

    public void setFurthestPoint(String furthestPoint) {
        this.furthestPoint = furthestPoint;
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

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
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

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getAccountFname() {
        return accountFname;
    }

    public void setAccountFname(String accountFname) {
        this.accountFname = accountFname;
    }

    public String getAccountLname() {
        return accountLname;
    }

    public void setAccountLname(String accountLname) {
        this.accountLname = accountLname;
    }

    public String getVehicleModel() {
        return vehicleModel;
    }

    public void setVehicleModel(String vehicleModel) {
        this.vehicleModel = vehicleModel;
    }

    public String getLicenseplate() {
        return licenseplate;
    }

    public void setLicenseplate(String licenseplate) {
        this.licenseplate = licenseplate;
    }

    public int getDistance() {
        return distance;
    }

    public void setDistance(int distance) {
        this.distance = distance;
    }
}