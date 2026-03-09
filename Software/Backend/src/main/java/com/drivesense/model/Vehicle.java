package com.drivesense.model;

public class Vehicle {
    private int id;
    private int profileId;
    private String model;
    private String licenseplate;
    private int mileage;

    public Vehicle() {}

    public Vehicle(int profileId, String model, String licenseplate, int mileage) {
        this.profileId = profileId;
        this.model = model;
        this.licenseplate = licenseplate;
        this.mileage = mileage;
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

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getLicenseplate() {
        return licenseplate;
    }

    public void setLicenseplate(String licenseplate) {
        this.licenseplate = licenseplate;
    }

    public int getMileage() {
        return mileage;
    }

    public void setMileage(int mileage) {
        this.mileage = mileage;
    }

    @Override
    public String toString() {
        return "Vehicle: " +
                "id: " + id +
                ", profileId: " + profileId +
                ", model: '" + model + '\'' +
                ", licenseplate: '" + licenseplate + '\'' +
                ", mileage: " + mileage;
    }
}
