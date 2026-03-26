package com.drivesense.service;

import com.drivesense.db.TrackingpointDao;
import com.drivesense.db.TripDao;
import com.drivesense.dto.response.TripDetailedDto;
import com.drivesense.exceptions.*;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;

@Service
public class TripService {
    private final TripDao tripDao;
    private final TrackingpointDao trackingpointDao;
    private final GeocodingService geocodingService;
    private final WeatherService weatherService;

    @Autowired
    public TripService(TripDao tripDao, TrackingpointDao trackingpointDao,
                       GeocodingService geocodingService, WeatherService weatherService) {
        this.tripDao = tripDao;
        this.trackingpointDao = trackingpointDao;
        this.geocodingService = geocodingService;
        this.weatherService = weatherService;
    }

    public void insertTrip(TripSummary tripSummary, List<Trackingpoint> trackingpoints) {
        if (trackingpoints == null || trackingpoints.isEmpty()) {
            throw new BadRequestException("Mindestens ein Trackingpoint muss vorhanden sein");
        }

        if (tripSummary.getEndTime().isBefore(tripSummary.getStartTime())) {
            throw new BadRequestException("Endzeit darf nicht vor der Startzeit liegen");
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

        int id = tripDao.insert(tripSummary);

        for (Trackingpoint trackingpoint : trackingpoints) {
            trackingpoint.setTripId(id);
            trackingpointDao.insert(trackingpoint);
        }
    }

    public List<TripSummary> getAllTrips() {
        return tripDao.getAll();
    }

    public List<TripSummary> getAllByProfileAndProtocolId(int profileId, int protocolId) {
        List<TripSummary> trips = tripDao.getAllByProfileAndProtocolId(profileId, protocolId);
        if (trips == null) {
            throw new NotFoundException("Keine Fahrten gefunden");
        }
        return trips;
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

    public TripDetailedDto getDetailedById(int id, int profileId) {
        TripSummary trip = tripDao.getByIdAndProfileId(id, profileId);
        if (trip == null) {
            throw new NotFoundException("Fahrt nicht gefunden oder kein Zugriff");
        }
        TripDetailedDto tripDetailedDto = new TripDetailedDto(trip);
        enrichWithTrackingPoints(tripDetailedDto);
        return tripDetailedDto;
    }

    private void enrichWithTrackingPoints(TripDetailedDto trip) {
        List<Trackingpoint> points = trackingpointDao.getByTripId(trip.getTripSummary().getId());

        if (points == null || points.isEmpty()) return;

        Trackingpoint start = points.get(0);
        Trackingpoint end = points.get(points.size() - 1);
        Trackingpoint furthest = getFurthestPoint(points, start);

        try {
            trip.getTripSummary().setStartPoint(geocodingService.getCity(start.getLat(), start.getLng()));
            trip.getTripSummary().setEndPoint(geocodingService.getCity(end.getLat(), end.getLng()));
            trip.getTripSummary().setFurthestPoint(geocodingService.getCity(furthest.getLat(), furthest.getLng()));
        } catch (ExternalApiException e) {
            trip.getTripSummary().setStartPoint("Unbekannt");
            trip.getTripSummary().setEndPoint("Unbekannt");
            trip.getTripSummary().setFurthestPoint("Unbekannt");
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
}
