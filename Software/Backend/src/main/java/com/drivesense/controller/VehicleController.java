package com.drivesense.controller;

import com.drivesense.dto.VehicleDto;
import com.drivesense.model.Vehicle;
import com.drivesense.service.VehicleService;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

    private VehicleService vehicleService = new VehicleService();

    @GetMapping("/test")
    public String test() {
        return "Backend läuft!";
    }

    // Alle Fahrzeuge anzeigen (DTO mit Username)
    @GetMapping("/get")
    public List<VehicleDto> getAllVehicles() {
        return vehicleService.getAllVehicles();
    }

    // Einzelnes Fahrzeug
    @GetMapping("/{id}")
    public Vehicle getVehicle(@PathVariable int id) {
        return vehicleService.getVehicleById(id);
    }

    // Fahrzeug speichern
    @PostMapping("/save")
    public void saveVehicle(@RequestBody Vehicle vehicle) {
        vehicleService.saveVehicle(vehicle);
    }

    // Fahrzeug bearbeiten
    @PutMapping("/update")
    public void updateVehicle(@RequestBody Vehicle vehicle) {
        vehicleService.updateVehicle(vehicle);
    }

    // Fahrzeug löschen
    @DeleteMapping("/delete/{id}")
    public void deleteVehicle(@PathVariable int id) {
        vehicleService.deleteVehicle(id);
    }
}