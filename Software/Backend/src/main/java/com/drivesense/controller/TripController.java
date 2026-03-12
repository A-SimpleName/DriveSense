package com.drivesense.controller;

import com.drivesense.dto.request.SaveTripRequest;
import com.drivesense.model.TripSummary;
import com.drivesense.service.TripService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")//origins = "http://localhost:5173")
@RestController
@RequestMapping("/api")
public class TripController {
    private final TripService tripService;

    @Autowired
    public TripController(TripService tripService) {
        this.tripService = tripService;
    }

    @PostMapping("/trips")
    public ResponseEntity<Void> saveTrip(@RequestBody SaveTripRequest saveTripRequest) {
        System.out.println(saveTripRequest.getTripSummary());
        System.out.println(saveTripRequest.getTrackingpoints());
        tripService.insertTrip(saveTripRequest.getTripSummary(), saveTripRequest.getTrackingpoints());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/profiles/{profileId}/protocols/{protocolId}/trips")
    public ResponseEntity<List<TripSummary>> getAllTripsByProfileAndProtocolId(@PathVariable int profileId, @PathVariable int protocolId) {
        return ResponseEntity.ok(tripService.getAllByProfileAndProtocolId(profileId, protocolId));
    }

    @GetMapping("/totalKm")
    public ResponseEntity<Double> getTotalKm (@RequestParam int profileId) {
        return ResponseEntity.ok(tripService.getTotalKm(profileId));
    }

    @GetMapping("/trips")
    public ResponseEntity<List<TripSummary>> getAllTripsByProfileAndProtocolId() {
        return ResponseEntity.ok(tripService.getAllTrips());
    }
}