package com.drivesense.controller;

import com.drivesense.dto.request.SaveVehicleRequest;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.UnauthorizedException;
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
    public ResponseEntity<List<VehicleDto>> getAllVehiclesByProfile(HttpServletRequest request) {
        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewÃ¤hlt");
        }

        return ResponseEntity.ok(vehicleService.getAllVehiclesByProfile(profileId));
    }

    @GetMapping("/account")
    public ResponseEntity<List<VehicleDto>> getAllVehiclesByAccount(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(vehicleService.getAllVehiclesByAccount(accountId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<VehicleDto> getVehicle(@PathVariable int id, HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(vehicleService.getVehicleById(id, accountId));
    }

    @PostMapping
    public ResponseEntity<Vehicle> saveVehicle(@Valid @RequestBody SaveVehicleRequest req, HttpServletRequest request) {
        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewählt");
        }

        Vehicle v = new Vehicle();
        v.setModel(req.getModel());
        v.setLicensePlate(req.getLicensePlate());
        v.setMileage(req.getMileage());

        return ResponseEntity.status(201)
                .body(vehicleService.saveVehicle(v, profileId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Void> update(@PathVariable int id,
                                       @RequestBody Vehicle vehicle,
                                       HttpServletRequest request) {

        int accountId = (int) request.getAttribute("accountId");
        vehicle.setId(id);

        vehicleService.updateVehicle(vehicle, accountId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id,
                                       HttpServletRequest request) {

        int accountId = (int) request.getAttribute("accountId");
        Object profileIdAttribute = request.getAttribute("profileId");
        if (!(profileIdAttribute instanceof Integer profileId)) {
            throw new UnauthorizedException("Kein aktives Profil ausgewaehlt");
        }

        vehicleService.deleteVehicle(id, accountId, profileId);
        return ResponseEntity.noContent().build();
    }
}
