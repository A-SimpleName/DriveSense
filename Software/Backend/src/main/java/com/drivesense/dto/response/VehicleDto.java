package com.drivesense.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public class VehicleDto {
    private int id;
    private String model;
    private String profileName;

    @JsonProperty("licensePlate")
    private String licensePlate;
    private int mileage;

    public VehicleDto() {}

    public VehicleDto(int id, String model, String profileName, String licencePlate, int mileage) {
        this.id = id;
        this.model = model;
        this.profileName = profileName;
        this.licensePlate = licensePlate;
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

    public String getProfileName() {
        return profileName;
    }

    public void setProfileName(String profileName) {
        this.profileName = profileName;
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
}