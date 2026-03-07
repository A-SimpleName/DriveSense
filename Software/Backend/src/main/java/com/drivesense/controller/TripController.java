package com.drivesense.controller;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;
import com.drivesense.service.TripService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")//origins = "http://localhost:5173")
@RestController
@RequestMapping("/api/trips")
public class TripController {
    private TripService tripService = new TripService();

    @PostMapping("/")
    public void saveTrip(@RequestBody Trip trip, List<Trackingpoint> trackingpoints) {
        tripService.insertTrip(trip,trackingpoints);
    }

    @GetMapping("/")
    public List<Trip> getAllTrips() {
        return tripService.getAllTrips();
    }
}