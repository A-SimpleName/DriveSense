package com.drivesense.dto.response;

import java.time.LocalDateTime;

public class TripSummaryDto {
    private int id;
    private int vehicleId;
    private int protocolId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private int startMileage;
    private int endMileage;
    private String accountFname;
    private String accountLname;
    private String vehicleModel;
    private String licenseplate;
    private String startPoint;
    private String furthestPoint;
    private String endPoint;
    private double distance;
    private String protocolName;
    private String roadSurfaceConditions;
    private String type;

    public TripSummaryDto () {

    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public String getProtocolName() {
        return protocolName;
    }

    public void setProtocolName(String protocolName) {
        this.protocolName = protocolName;
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

    public String getLicensePlate() {
        return licenseplate;
    }

    public void setLicensePlate(String licensePlate) {
        this.licenseplate = licensePlate;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }
}