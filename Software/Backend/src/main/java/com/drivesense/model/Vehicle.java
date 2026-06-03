package com.drivesense.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

public class Vehicle {
    private int id;

    @NotBlank(message = "Model darf nicht leer sein")
    @Size(max = 150, message = "Model darf maximal 150 Zeichen haben")
    private String model;

    @NotBlank(message = "Kennzeichen darf nicht leer sein")
    @Size(max = 20, message = "Kennzeichen darf maximal 20 Zeichen haben")
    private String licensePlate;

    @Min(value = 0, message = "Kilometerstand darf nicht negativ sein")
    private int mileage;

    private LocalDateTime deletedAt;

    public Vehicle() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public String getLicensePlate() { return licensePlate; }
    public void setLicensePlate(String licensePlate) { this.licensePlate = licensePlate; }

    public int getMileage() { return mileage; }
    public void setMileage(int mileage) { this.mileage = mileage; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public boolean isDeleted() { return deletedAt != null; }


    @Override
    public String toString() {
        return "Vehicle: " +
                "id: " + id +
                ", model: '" + model + '\'' +
                ", licensePlate: '" + licensePlate + '\'' +
                ", mileage: " + mileage;
    }
}
