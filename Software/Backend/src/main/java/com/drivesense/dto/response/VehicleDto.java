package com.drivesense.dto.response;

public class VehicleDto {

    private int id;
    private String model;
    private String licensePlate;
    private int mileage;

    private String ownerAccountName;
    private String ownerProfileName;

    private String myRole;

    public VehicleDto() {}

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getLicensePlate() {
        return licensePlate;
    }

    public void setLicensePlate(String licensePlate) {
        this.licensePlate = licensePlate;
    }

    public int getMileage() {
        return mileage;
    }

    public void setMileage(int mileage) {
        this.mileage = mileage;
    }

    public String getOwnerAccountName() {
        return ownerAccountName;
    }

    public void setOwnerAccountName(String ownerAccountName) {
        this.ownerAccountName = ownerAccountName;
    }

    public String getOwnerProfileName() {
        return ownerProfileName;
    }

    public void setOwnerProfileName(String ownerProfileName) {
        this.ownerProfileName = ownerProfileName;
    }

    public String getMyRole() {
        return myRole;
    }

    public void setMyRole(String myRole) {
        this.myRole = myRole;
    }
}