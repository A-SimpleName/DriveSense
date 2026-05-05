package com.drivesense.controller;

import com.drivesense.dto.request.SaveVehicleRequest;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.model.Vehicle;
import com.drivesense.service.VehicleService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

    @Autowired
    private VehicleService vehicleService;

    @GetMapping
    public ResponseEntity<List<VehicleDto>> getAllVehicles() {
        return ResponseEntity.ok(vehicleService.getAllVehicles());
    }

    @GetMapping("/account")
    public ResponseEntity<List<VehicleDto>> getAllVehiclesByAccount(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(vehicleService.getAllVehiclesByAccount(accountId));
    }

    @PostMapping
    public ResponseEntity<Vehicle> saveVehicle(@Valid @RequestBody SaveVehicleRequest vehicleRequest, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        Vehicle vehicle = new Vehicle();
        vehicle.setModel(vehicleRequest.getModel());
        vehicle.setLicensePlate(vehicleRequest.getLicensePlate());
        vehicle.setMileage(vehicleRequest.getMileage());

        vehicle.setProfileId(profileId);
        return ResponseEntity.status(201).body(vehicleService.saveVehicle(vehicle));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Vehicle> getVehicle(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(vehicleService.getVehicleById(id, profileId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Void> updateVehicle(@PathVariable int id, @Valid @RequestBody Vehicle vehicle, HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        vehicle.setId(id);
        vehicleService.updateVehicle(vehicle, accountId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteVehicle(@PathVariable int id, HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        vehicleService.deleteVehicle(id, accountId);
        return ResponseEntity.noContent().build();
    }
}