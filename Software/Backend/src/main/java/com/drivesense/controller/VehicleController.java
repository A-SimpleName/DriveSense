package com.drivesense.controller;

import com.drivesense.dto.response.VehicleDto;
import com.drivesense.model.Vehicle;
import com.drivesense.service.VehicleService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

    @Autowired
    private VehicleService vehicleService;

    @GetMapping
    public ResponseEntity<List<VehicleDto>> getAllVehicles() {
        return ResponseEntity.ok(vehicleService.getAllVehicles());
    }

    @PostMapping
    public ResponseEntity<Vehicle> saveVehicle(@RequestBody Vehicle vehicle, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        vehicle.setProfileId(profileId);
        return ResponseEntity.status(201).body(vehicleService.saveVehicle(vehicle));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Vehicle> getVehicle(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(vehicleService.getVehicleById(id, profileId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Void> updateVehicle(@PathVariable int id, @RequestBody Vehicle vehicle, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        vehicle.setId(id);
        vehicleService.updateVehicle(vehicle, profileId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteVehicle(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        vehicleService.deleteVehicle(id, profileId);
        return ResponseEntity.noContent().build();
    }
}