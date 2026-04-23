package com.drivesense.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class Vehicle {
    private int id;
    private int profileId;
    @NotBlank(message = "Model darf nicht leer sein")
    @Size(max = 150, message = "Model darf maximal 150 Zeichen haben")
    private String model;
    @NotBlank(message = "Licenseplate darf nicht leer sein")
    @Size(max = 20,message = "Licenseplate darf maximal 20 Zeichen haben")
    private String licensePlate;
    @Min(value = 0, message = "Kilometerstand darf nicht negativ sein")
    private int mileage;

    public Vehicle() {}

    public Vehicle(int profileId, String model, String licensePlate, int mileage) {
        this.profileId = profileId;
        this.model = model;
        this.licensePlate = licensePlate;
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

    @Override
    public String toString() {
        return "Vehicle: " +
                "id: " + id +
                ", profileId: " + profileId +
                ", model: '" + model + '\'' +
                ", licenseplate: '" + licensePlate + '\'' +
                ", mileage: " + mileage;
    }
}
