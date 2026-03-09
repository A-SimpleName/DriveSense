package com.drivesense.controller;

import com.drivesense.dto.response.VehicleDto;
import com.drivesense.model.Vehicle;
import com.drivesense.service.VehicleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

    @Autowired
    private VehicleService vehicleService;

    @GetMapping("/test")
    public String test() {
        return "Endpunkt vehicles läuft!";
    }
    // Alle Fahrzeuge anzeigen (DTO mit Username)
    @GetMapping("/")
    public List<VehicleDto> getAllVehicles() {
        return vehicleService.getAllVehicles();
    }

    // Fahrzeug speichern
    @PostMapping("/")
    public void saveVehicle(@RequestBody Vehicle vehicle) {
        vehicleService.saveVehicle(vehicle);
    }

    // Einzelnes Fahrzeug
    @GetMapping("/{id}")
    public Vehicle getVehicle(@PathVariable int id) {
        return vehicleService.getVehicleById(id);
    }

    // Fahrzeug bearbeiten
    @PutMapping("/{id}")
    public void updateVehicle(@PathVariable int id, @RequestBody Vehicle vehicle) {
        vehicle.setId(id);
        vehicleService.updateVehicle(vehicle);
    }

    // Fahrzeug löschen
    @DeleteMapping("/{id}")
    public void deleteVehicle(@PathVariable int id) {
        vehicleService.deleteVehicle(id);
    }
}