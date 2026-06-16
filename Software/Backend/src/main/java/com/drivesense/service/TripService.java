package com.drivesense.service;


import com.drivesense.db.ProtocolDao;
import com.drivesense.db.TripDao;
import com.drivesense.dto.response.TripDetailedDto;
import com.drivesense.exceptions.*;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.model.Profile;
import com.drivesense.model.TripSummary;
import com.drivesense.model.Trackingpoint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Duration;
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
    public TripService(TripDao tripDao, ProtocolDao protocolDao, TrackingpointService trackingpointService,
                       GeocodingService geocodingService, WeatherService weatherService,
                       ProtocolService protocolService, ProfileService profileService) {
        this.tripDao = tripDao;
        this.protocolDao = protocolDao;
        this.trackingpointService = trackingpointService;
        this.geocodingService = geocodingService;
        this.weatherService = weatherService;
        this.profileService = profileService;
        this.protocolService = protocolService;
    }

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

        // Road condition will be finalized after trackingpoints are attached.
        if (tripSummary.getRoadSurfaceConditions() == null || tripSummary.getRoadSurfaceConditions().isBlank()) {
            tripSummary.setRoadSurfaceConditions("Unbekannt");
        }

        // Set default values for location fields (will be enriched later when tracking points are added)
        if (tripSummary.getStartPoint() == null) {
            tripSummary.setStartPoint("Unbekannt");
        }
        if (tripSummary.getEndPoint() == null) {
            tripSummary.setEndPoint("Unbekannt");
        }
        if (tripSummary.getFurthestPoint() == null) {
            tripSummary.setFurthestPoint("Unbekannt");
        }

        int id = tripDao.insert(tripSummary);
        tripSummary.setId(id);
        return tripSummary;
    }

    public TripDetailedDto addTrackingpointsToTrip(int tripId, List<Trackingpoint> trackingpoints, int profileId) {
        if (trackingpoints == null || trackingpoints.isEmpty()) {
            throw new BadRequestException("Mindestens ein Trackingpoint muss vorhanden sein");
        }

        TripSummary tripSummary = tripDao.getById(tripId);
        if (tripSummary == null) {
            throw new NotFoundException("Trip nicht gefunden");
        }

        if (tripSummary.getEndTime().isBefore(tripSummary.getStartTime())) {
            throw new BadRequestException("Endzeit darf nicht vor der Startzeit liegen");
        }

        if (tripSummary.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf diesen Trip");
        }
        Profile profile = profileService.getById(tripSummary.getProfileId());
        if (!profile.getRole().equals(protocolService.getProtocolRole(tripSummary.getProtocolId()))) {
            throw new BadRequestException("Rolle muss die selbe wie vom Protocol sein");
        }

        Trackingpoint firstPoint = trackingpoints.get(0);
        Trackingpoint lastPoint = trackingpoints.get(trackingpoints.size() - 1);

        double distanceStartEnd = calculateDistance(
                firstPoint.getLat(), firstPoint.getLng(),
                lastPoint.getLat(), lastPoint.getLng()
        );

        Trackingpoint weatherPoint = distanceStartEnd < 0.5
                ? getFurthestPoint(trackingpoints, firstPoint)
                : firstPoint;

        try {
            tripSummary.setRoadSurfaceConditions(
                    weatherService.getRoadSurfaceCondition(weatherPoint.getLat(), weatherPoint.getLng())
            );
        } catch (ExternalApiException e) {
            tripSummary.setRoadSurfaceConditions("Unbekannt");
        }

        List<Trackingpoint> createdTrackingpoints = new ArrayList<>();
        for (Trackingpoint trackingpoint : trackingpoints) {
            trackingpoint.setTripId(tripSummary.getId());
            createdTrackingpoints.add(trackingpointService.insert(trackingpoint, tripSummary));
        }

        enrichWithTrackingPoints(tripSummary);

        // Update trip with enriched location data
        tripDao.update(tripSummary);

        TripSummaryDto createdTripDto = tripDao.getDtoByIdAccessibleByProfile(tripSummary.getId(), profileId);
        if (createdTripDto == null) {
            throw new NotFoundException("Fahrt nicht gefunden oder kein Zugriff");
        }
        return new TripDetailedDto(createdTripDto, createdTrackingpoints);
    }


    public List<TripSummary> getAllTrips() {
        return tripDao.getAll();
    }

    public List<TripSummaryDto> getAllByProfileAndProtocolId(int profileId, int protocolId) {
        List<TripSummaryDto> trips = tripDao.getAllByProfileAndProtocolId(protocolId, profileId);

        return trips != null ? trips : List.of();
    }

    public List<TripSummaryDto> getAllByProfileId(int profileId) {
        List<TripSummary> trips = tripDao.getByProfileId(profileId);
        if (trips == null) return List.of();
        return trips.stream()
                .map(this::mapToDto)
                .toList();
    }

    public TripSummaryDto getLatestTrackedByProfileId(int profileId) {
        return tripDao.getLatestTrackedByProfileId(profileId);
    }

    public double getTotalKm(int profileId) {
        List<TripSummary> tripSummaries = tripDao.getByProfileId(profileId);
        if (tripSummaries == null) {
            return 0;
        }
        return tripSummaries.stream()
                .mapToDouble(TripSummary::getDistance)
                .sum();
    }

    public long getTotalDuration(int profileId) {
        List<TripSummary> tripSummaries = tripDao.getByProfileId(profileId);
        if (tripSummaries == null) {
            return 0;
        }
        return tripSummaries.stream()
                .filter(trip -> trip.getEndTime() != null && trip.getStartTime() != null)
                .mapToLong(trip -> Duration.between(trip.getStartTime(), trip.getEndTime()).toMinutes())
                .sum();
    }

    public TripDetailedDto getDetailedById(int id, int profileId) {
        TripSummaryDto trip = tripDao.getDtoByIdAccessibleByProfile(id, profileId);
        if (trip == null) {
            throw new NotFoundException("Fahrt nicht gefunden oder kein Zugriff");
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
        if (tripSummary.getVehicleId() <= 0) {
            tripSummary.setVehicleId(existing.getVehicleId());
        }
        if (tripSummary.getProtocolId() <= 0) {
            tripSummary.setProtocolId(existing.getProtocolId());
        }
        if (tripSummary.getStartPoint() == null) {
            tripSummary.setStartPoint(existing.getStartPoint());
        }
        if (tripSummary.getEndPoint() == null) {
            tripSummary.setEndPoint(existing.getEndPoint());
        }
        if (tripSummary.getFurthestPoint() == null) {
            tripSummary.setFurthestPoint(existing.getFurthestPoint());
        }
        if (tripSummary.getRoadSurfaceConditions() == null) {
            tripSummary.setRoadSurfaceConditions(existing.getRoadSurfaceConditions());
        }
        if (tripSummary.getType() == null) {
            tripSummary.setType(existing.getType());
        }

        validateTripSummary(tripSummary);

        tripDao.update(tripSummary);
    }

    public void delete(int id, int profileId) {
        TripSummary tripSummary = tripDao.getById(id);
        if (tripSummary == null) {
            throw new NotFoundException("Trip nicht gefunden");
        }
        if (tripSummary.getProfileId() != profileId) {
            throw new UnauthorizedException("Kein Zugriff auf diesen Trip");
        }
        trackingpointService.deleteByTripId(tripSummary.getId());
        tripDao.deleteById(id);
    }


    private void enrichWithTrackingPoints(TripSummary tripSummary) {
        List<Trackingpoint> points = trackingpointService.getByTripId(tripSummary.getId());

        if (points == null || points.isEmpty()) return;

        Trackingpoint start = points.get(0);
        Trackingpoint end = points.get(points.size() - 1);
        Trackingpoint furthest = getFurthestPoint(points, start);

        try {
            tripSummary.setStartPoint(geocodingService.getCity(start.getLat(), start.getLng()));
            tripSummary.setEndPoint(geocodingService.getCity(end.getLat(), end.getLng()));
            tripSummary.setFurthestPoint(geocodingService.getCity(furthest.getLat(), furthest.getLng()));
        } catch (ExternalApiException e) {
            tripSummary.setStartPoint("Unbekannt");
            tripSummary.setEndPoint("Unbekannt");
            tripSummary.setFurthestPoint("Unbekannt");
        }
    }

    private Trackingpoint getFurthestPoint(List<Trackingpoint> points, Trackingpoint start) {
        return points.stream()
                .max(Comparator.comparingDouble(p ->
                        calculateDistance(start.getLat(), start.getLng(), p.getLat(), p.getLng())
                ))
                .orElse(start);
    }

    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    private void validateTripSummary(TripSummary tripSummary) {
        if (tripSummary.getEndTime().isBefore(tripSummary.getStartTime())) {
            throw new BadRequestException("Endzeit darf nicht vor der Startzeit liegen");
        }

        if (tripSummary.getEndMileage() < tripSummary.getStartMileage()) {
            throw new BadRequestException("End-Kilometerstand darf nicht vor dem Start-Kilometerstand liegen");
        }
    }

    private TripSummaryDto mapToDto(TripSummary t) {
        TripSummaryDto dto = new TripSummaryDto();
        dto.setId(t.getId());
        dto.setVehicleId(t.getVehicleId());
        dto.setProtocolId(t.getProtocolId());
        dto.setStartTime(t.getStartTime());
        dto.setEndTime(t.getEndTime());
        dto.setDistance(t.getDistance());
        dto.setRoadSurfaceConditions(t.getRoadSurfaceConditions());
        dto.setType(t.getType());
        return dto;
    }
}
