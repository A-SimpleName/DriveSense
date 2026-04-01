package com.drivesense.controller;

import com.drivesense.dto.request.SaveTripRequest;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.dto.request.UpdatePasswordRequest;
import com.drivesense.dto.response.TripDetailedDto;
import com.drivesense.model.TripSummary;
import com.drivesense.service.TripService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class TripController {
    private final TripService tripService;

    @Autowired
    public TripController(TripService tripService) {
        this.tripService = tripService;
    }

    @PostMapping("/trips")
    public ResponseEntity<Void> saveTrip(@Valid @RequestBody SaveTripRequest saveTripRequest, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        saveTripRequest.getTripSummary().setProfileId(profileId);

        tripService.insertTrip(saveTripRequest.getTripSummary(), saveTripRequest.getTrackingpoints());

        return ResponseEntity.ok().build();
    }

    @GetMapping("/profiles/protocols/{protocolId}/trips")
    public ResponseEntity<List<TripSummaryDto>> getAllTripsByProfileAndProtocolId(HttpServletRequest request, @PathVariable int protocolId) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getAllByProfileAndProtocolId(profileId, protocolId));
    }

    @GetMapping("/totalKm")
    public ResponseEntity<Double> getTotalKm (HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getTotalKm(profileId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TripDetailedDto> getDetailedById(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(tripService.getDetailedById(id,profileId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Void> update(@PathVariable int id, @Valid @RequestBody TripSummary tripSummary, HttpServletRequest httpRequest) {
        int profileId = (int) httpRequest.getAttribute("profileId");
        tripSummary.setId(id);
        tripService.update(tripSummary,profileId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        tripService.delete(id,profileId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/trips")
    public ResponseEntity<List<TripSummary>> getAllTripsByProfileAndProtocolId() {
        return ResponseEntity.ok(tripService.getAllTrips());
    }
}