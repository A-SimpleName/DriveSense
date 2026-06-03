package com.drivesense.controller;

import com.drivesense.dto.request.SaveTripRequest;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.dto.response.TripDetailedDto;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import com.drivesense.service.TripService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/trips")
public class TripController {
    private final TripService tripService;

    @Autowired
    public TripController(TripService tripService) {
        this.tripService = tripService;
    }

    // POST /api/trips
    @PostMapping
    public ResponseEntity<TripDetailedDto> saveTrip(@Valid @RequestBody SaveTripRequest saveTripRequest, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        TripSummary tripSummary = saveTripRequest.getTripSummary();
        tripSummary.setProfileId(profileId);
        if (saveTripRequest.getStartMileage() != null) {
            tripSummary.setStartMileage(saveTripRequest.getStartMileage());
        }
        if (saveTripRequest.getEndMileage() != null) {
            tripSummary.setEndMileage(saveTripRequest.getEndMileage());
        }
        return ResponseEntity.status(201).body(tripService.insertTrip(tripSummary, saveTripRequest.getTrackingpoints()));
    }

    // POST /api/trips/summary
    @PostMapping("/summary")
    public ResponseEntity<TripSummary> createTripSummary(@Valid @RequestBody TripSummary tripSummary, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        tripSummary.setProfileId(profileId);
        return ResponseEntity.status(201).body(tripService.insertTripSummary(tripSummary));
    }

    // POST /api/trips/{id}/trackingpoints
    @PostMapping("/{id}/trackingpoints")
    public ResponseEntity<TripDetailedDto> addTrackingpoints(
            @PathVariable int id,
            @RequestBody List<Trackingpoint> trackingpoints,
            HttpServletRequest request
    ) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.status(201).body(tripService.addTrackingpointsToTrip(id, trackingpoints, profileId));
    }

    // GET /api/trips
    @GetMapping
    public ResponseEntity<List<TripSummaryDto>> getAllTripsByProfileId(HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getAllByProfileId(profileId));
    }

    // GET /api/trips/totalKm
    @GetMapping("/totalKm")
    public ResponseEntity<Double> getTotalKm(HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getTotalKm(profileId));
    }

    // GET /api/trips/latest
    @GetMapping("/latest")
    public ResponseEntity<TripSummaryDto> getLatestTrackedTrip(HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        TripSummaryDto trip = tripService.getLatestTrackedByProfileId(profileId);
        if (trip == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(trip);
    }

    // GET /api/trips/{id}
    @GetMapping("/{id}")
    public ResponseEntity<TripDetailedDto> getDetailedById(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getDetailedById(id, profileId));
    }

    // PUT /api/trips/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Void> update(@PathVariable int id, @Valid @RequestBody TripSummary tripSummary, HttpServletRequest httpRequest) {
        int profileId = (int) httpRequest.getAttribute("profileId");
        tripSummary.setId(id);
        tripService.update(tripSummary, profileId);
        return ResponseEntity.ok().build();
    }

    // DELETE /api/trips/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        tripService.delete(id, profileId);
        return ResponseEntity.noContent().build();
    }

    // GET /api/trips/protocols/{protocolId}
    @GetMapping("/protocols/{protocolId}")
    public ResponseEntity<List<TripSummaryDto>> getAllTripsByProfileAndProtocolId(HttpServletRequest request, @PathVariable int protocolId) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getAllByProfileAndProtocolId(profileId, protocolId));
    }
}
