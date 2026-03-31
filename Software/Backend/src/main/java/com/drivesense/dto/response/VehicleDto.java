package com.drivesense.dto.response;

public class VehicleDto {
    private int id;
    private String model;
    private String profileName;
    private String licenseplate;
    private int mileage;

    public VehicleDto() {}

    public VehicleDto(int id, String model, String profileName, String licencePlate, int mileage) {
        this.id = id;
        this.model = model;
        this.profileName = profileName;
        this.licenseplate = licencePlate;
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

    public String getLicencePlate() {
        return licenseplate;
    }

    public void setLicencePlate(String licenseplate) {
        this.licenseplate = licenseplate;
    }

    public int getMileage() {
        return mileage;
    }

    public void setMileage(int mileage) {
        this.mileage = mileage;
    }
}