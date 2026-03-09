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
@RequestMapping("/api/trips")
public class TripController {
    private final TripService tripService;

    @Autowired
    public TripController(TripService tripService) {
        this.tripService = tripService;
    }

    @PostMapping("/")
    public ResponseEntity<Void> saveTrip(@RequestBody SaveTripRequest saveTripRequest) {
        System.out.println(saveTripRequest.getTripSummary());
        System.out.println(saveTripRequest.getTrackingpoints());
        tripService.insertTrip(saveTripRequest.getTripSummary(), saveTripRequest.getTrackingpoints());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/")
    public List<TripSummary> getAllTrips() {
        return tripService.getAllTrips();
    }
}