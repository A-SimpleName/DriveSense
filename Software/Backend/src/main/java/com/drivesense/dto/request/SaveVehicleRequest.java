package com.drivesense.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public class SaveVehicleRequest {

    @NotBlank
    private String model;

    @NotBlank
    private String licensePlate;

    @Min(0)
    private int mileage;

    public String getModel() {
        return model;
    }

    public int getMileage() {
        return mileage;
    }

    public String getLicensePlate() {
        return licensePlate;
    }
}