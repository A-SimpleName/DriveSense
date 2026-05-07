package com.drivesense.service;

import com.drivesense.db.*;
import com.drivesense.dto.response.TripDetailedDto;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.exceptions.*;
import com.drivesense.model.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class TripService {

    private final TripDao tripDao;
    private final ProtocolDao protocolDao;
    private final TrackingpointService trackingpointService;
    private final GeocodingService geocodingService;
    private final WeatherService weatherService;
    private final ProfileService profileService;
    private final ProtocolService protocolService;

    @Autowired
    public TripService(
            TripDao tripDao,
            ProtocolDao protocolDao,
            TrackingpointService trackingpointService,
            GeocodingService geocodingService,
            WeatherService weatherService,
            ProtocolService protocolService,
            ProfileService profileService
    ) {
        this.tripDao = tripDao;
        this.protocolDao = protocolDao;
        this.trackingpointService = trackingpointService;
        this.geocodingService = geocodingService;
        this.weatherService = weatherService;
        this.profileService = profileService;
        this.protocolService = protocolService;
    }

    // =========================================================
    // INSERT
    // =========================================================

    public TripDetailedDto insertTrip(TripSummary tripSummary, List<Trackingpoint> trackingpoints) {
        validateTripSummary(tripSummary);

        TripSummary createdTrip = insertTripSummary(tripSummary);
        return addTrackingpointsToTrip(createdTrip.getId(), trackingpoints, createdTrip.getProfileId());
    }

    public TripSummary insertTripSummary(TripSummary tripSummary) {
        validateTripSummary(tripSummary);

        if (!protocolDao.isAccessibleByProfile(tripSummary.getProtocolId(), tripSummary.getProfileId())) {
            throw new UnauthorizedException("Kein Zugriff auf dieses Protokoll");
        }

        if (tripSummary.getType() == null ||
                "null".equalsIgnoreCase(tripSummary.getType().trim())) {
            tripSummary.setType(null);
        }

        if (tripSummary.getRoadSurfaceConditions() == null || tripSummary.getRoadSurfaceConditions().isBlank()) {
            tripSummary.setRoadSurfaceConditions("Unbekannt");
        }

        // initial fallback (wird später ersetzt)
        if (tripSummary.getStartPoint() == null) tripSummary.setStartPoint("Unbekannt");
        if (tripSummary.getEndPoint() == null) tripSummary.setEndPoint("Unbekannt");
        if (tripSummary.getFurthestPoint() == null) tripSummary.setFurthestPoint("Unbekannt");

        int id = tripDao.insert(tripSummary);
        tripSummary.setId(id);
        return tripSummary;
    }

    // =========================================================
    // ADD TRACKINGPOINTS
    // =========================================================

    public TripDetailedDto addTrackingpointsToTrip(int tripId, List<Trackingpoint> trackingpoints, int profileId) {

        if (trackingpoints == null || trackingpoints.isEmpty()) {
            throw new BadRequestException("Mindestens ein Trackingpoint muss vorhanden sein");
        }

        TripSummary tripSummary = tripDao.getById(tripId);

        if (tripSummary == null) {
            throw new NotFoundException("Trip nicht gefunden");
        }

        if (tripSummary.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf diesen Trip");
        }

        Trackingpoint start = trackingpoints.get(0);
        Trackingpoint end = trackingpoints.get(trackingpoints.size() - 1);

        Trackingpoint furthest = getFurthestPoint(trackingpoints, start);

        try {
            tripSummary.setRoadSurfaceConditions(
                    weatherService.getRoadSurfaceCondition(start.getLat(), start.getLng())
            );
        } catch (Exception e) {
            tripSummary.setRoadSurfaceConditions("Unbekannt");
        }

        List<Trackingpoint> created = new ArrayList<>();
        for (Trackingpoint tp : trackingpoints) {
            tp.setTripId(tripSummary.getId());
            created.add(trackingpointService.insert(tp, tripSummary));
        }

        TripDetailedDto dto = new TripDetailedDto(tripSummary, created);

        enrichWithTrackingPoints(dto, start, end, furthest);

        tripDao.update(tripSummary);

        return dto;
    }

    // =========================================================
    // ENRICH
    // =========================================================

    private void enrichWithTrackingPoints(
            TripDetailedDto trip,
            Trackingpoint start,
            Trackingpoint end,
            Trackingpoint furthest
    ) {

        try {

            trip.getTripSummary().setStartPoint(
                    geocodingService.getCity(start.getLat(), start.getLng())
            );

            trip.getTripSummary().setEndPoint(
                    geocodingService.getCity(end.getLat(), end.getLng())
            );

            trip.getTripSummary().setFurthestPoint(
                    geocodingService.getCity(furthest.getLat(), furthest.getLng())
            );

        } catch (Exception e) {
            if (trip.getTripSummary().getStartPoint() == null)
                trip.getTripSummary().setStartPoint("Unbekannt");

            if (trip.getTripSummary().getEndPoint() == null)
                trip.getTripSummary().setEndPoint("Unbekannt");

            if (trip.getTripSummary().getFurthestPoint() == null)
                trip.getTripSummary().setFurthestPoint("Unbekannt");
        }
    }

    // =========================================================
    // PUBLIC API (CONTROLLER FIX)
    // =========================================================

    public List<TripSummaryDto> getAllByProfileId(int profileId) {
        return tripDao.getAllByProfileId(profileId);
    }

    public List<TripSummaryDto> getAllByProfileAndProtocolId(int profileId, int protocolId) {
        return tripDao.getAllByProfileAndProtocolId(protocolId, profileId);
    }

    public double getTotalKm(int profileId) {
        List<TripSummary> trips = tripDao.getByProfileId(profileId);
        if (trips == null) return 0;

        return trips.stream()
                .mapToDouble(TripSummary::getDistance)
                .sum();
    }

    public TripDetailedDto getDetailedById(int id, int profileId) {
        TripSummary trip = tripDao.getByIdAndProfileId(id, profileId);
        if (trip == null) {
            throw new NotFoundException("Trip nicht gefunden");
        }

        List<Trackingpoint> points = trackingpointService.getByTripId(trip.getId());
        return new TripDetailedDto(trip, points);
    }

    public void update(TripSummary tripSummary, int profileId) {
        TripSummary existing = tripDao.getById(tripSummary.getId());

        if (existing == null) {
            throw new NotFoundException("Trip nicht gefunden");
        }

        if (existing.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf diesen Trip");
        }

        tripSummary.setProfileId(profileId);

        tripDao.update(tripSummary);
    }

    public void delete(int id, int profileId) {
        TripSummary trip = tripDao.getById(id);

        if (trip == null) {
            throw new NotFoundException("Trip nicht gefunden");
        }

        if (trip.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf diesen Trip");
        }

        trackingpointService.deleteByTripId(id);
        tripDao.deleteById(id);
    }

    public List<TripSummary> getAllTrips() {
        return tripDao.getAll();
    }

    // =========================================================
    // HELPERS
    // =========================================================

    private Trackingpoint getFurthestPoint(List<Trackingpoint> points, Trackingpoint start) {
        return points.stream()
                .max(Comparator.comparingDouble(p ->
                        calculateDistance(start.getLat(), start.getLng(),
                                p.getLat(), p.getLng())))
                .orElse(start);
    }

    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        final int R = 6371;

        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);

        return 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * R;
    }

    private void validateTripSummary(TripSummary tripSummary) {
        if (tripSummary.getEndTime().isBefore(tripSummary.getStartTime())) {
            throw new BadRequestException("Endzeit darf nicht vor der Startzeit liegen");
        }

        if (tripSummary.getEndMileage() < tripSummary.getStartMileage()) {
            throw new BadRequestException("End-Kilometerstand darf nicht vor dem Start-Kilometerstand liegen");
        }
    }
}