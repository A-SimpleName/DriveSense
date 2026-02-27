package com.drivesense.controller;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;
import com.drivesense.service.TripService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/fahrten")
public class TripController {
    private TripService tripService;

    @PostMapping
    public void saveTrip(@RequestBody Trip trip, List<Trackingpoint> trackingpoints) {
        tripService.saveTrip(trip,trackingpoints);
    }
}
