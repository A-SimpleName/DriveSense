package com.drivesense.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class SaveVehicleRequest {

    @NotBlank(message = "Model darf nicht leer sein")
    @Size(max = 150, message = "Model darf maximal 150 Zeichen haben")
    private String model;

    @NotBlank(message = "Licenseplate darf nicht leer sein")
    @Size(max = 20,message = "Licenseplate darf maximal 20 Zeichen haben")
    private String licensePlate;

    @Min(value = 0, message = "Kilometerstand darf nicht negativ sein")
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