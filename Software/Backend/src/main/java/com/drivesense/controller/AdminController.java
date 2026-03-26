package com.drivesense.controller;

import com.drivesense.dto.response.VehicleDto;
import com.drivesense.model.*;
import com.drivesense.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
    @Autowired
    private ProtocolService protocolService;
    @Autowired
    private AccountService accountService;
    @Autowired
    private ProfileService profileService;
    @Autowired
    private TrackingpointService trackingpointService;
    @Autowired
    private TripService tripService;
    @Autowired
    private VehicleService vehicleService;
    @Autowired
    private UsergroupService usergroupService;

    @GetMapping("/protocols")
    public ResponseEntity<List<Protocol>> getAllProtocols() {
        return ResponseEntity.ok(protocolService.getAll());
    }

    @GetMapping("/accounts")
    public ResponseEntity<List<Account>> getAllAccounts() {
        return ResponseEntity.ok(accountService.getAll());
    }

    @GetMapping("/profiles")
    public ResponseEntity<List<Profile>> getAllProfiles() {
        return ResponseEntity.ok(profileService.getAll());
    }

    @GetMapping("/trackingpoints")
    public ResponseEntity<List<Trackingpoint>> getAllTrackingpoints () {
        return ResponseEntity.ok(trackingpointService.getAll());
    }

    @GetMapping("/trips")
    public ResponseEntity<List<TripSummary>> getAllTrips () {
        return ResponseEntity.ok(tripService.getAllTrips());
    }

    @GetMapping("/vehicles")
    public ResponseEntity<List<VehicleDto>> getAllVehicles () {
        return ResponseEntity.ok(vehicleService.getAllVehicles());
    }

    @GetMapping("/groups")
    public ResponseEntity<List<UserGroup>> getAllGroups () {
        return ResponseEntity.ok(usergroupService.getAll());
    }
}
