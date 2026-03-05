package com.drivesense.dto;

public class VehicleDto {
    private int id;
    private String model;
    private String userName;
    private String licencePlate;
    private int mileage;

    public VehicleDto() {
    }

    public VehicleDto(int id, String model, String userName, String licencePlate, int mileage) {
        this.id = id;
        this.model = model;
        this.userName = userName;
        this.licencePlate = licencePlate;
        this.mileage = mileage;
    }

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

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getLicencePlate() {
        return licencePlate;
    }

    public void setLicencePlate(String licencePlate) {
        this.licencePlate = licencePlate;
    }

    public int getMileage() {
        return mileage;
    }

    public void setMileage(int mileage) {
        this.mileage = mileage;
    }
}