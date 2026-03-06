package com.drivesense.controller;
import com.drivesense.db.TripDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;
import com.drivesense.service.TripService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")//origins = "http://localhost:5173")
@RestController
@RequestMapping("/api/trips")
public class TripController {
    private TripService tripService;

    @PostMapping("/save")
    public void saveTrip(@RequestBody Trip trip, List<Trackingpoint> trackingpoints) {
        tripService.saveTrip(trip,trackingpoints);
    }
    @GetMapping("/test")
    public String test() {
        return "Backend läuft!";
    }
    @GetMapping("/get")
    public List<Trip> getAllTrips() {
        return TripDao.findAll();
    }
}
