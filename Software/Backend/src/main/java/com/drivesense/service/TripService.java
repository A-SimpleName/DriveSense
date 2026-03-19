package com.drivesense.service;


import com.drivesense.db.TrackingpointDao;
import com.drivesense.db.TripDao;
import com.drivesense.dto.response.TripDetailedDto;
import com.drivesense.model.TripSummary;
import com.drivesense.model.Trackingpoint;
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
    public TripService(TripDao tripDao, TrackingpointDao trackingpointDao, GeocodingService geocodingService,WeatherService weatherService) {
        this.tripDao = tripDao;
        this.trackingpointDao = trackingpointDao;
        this.geocodingService = geocodingService;
        this.weatherService = weatherService;
    }

    public void insertTrip(TripSummary tripSummary, List<Trackingpoint> trackingpoints) {
        int id = tripDao.insert(tripSummary);
        TripDetailedDto tripDetailedDto = new TripDetailedDto(tripSummary, trackingpoints);

        enrichWithTrackingPoints(tripDetailedDto);
        System.out.println(tripDetailedDto);
        Trackingpoint firstPoint = trackingpoints.get(0);
        tripSummary.setRoadSurfaceConditions(weatherService.getRoadSurfaceCondition(firstPoint.getLat(),firstPoint.getLng()));

        for (Trackingpoint trackingpoint : trackingpoints) {
            trackingpoint.setTripId(id);
            trackingpointDao.insert(trackingpoint);
        }
    }

    public List<TripSummary> getAllTrips() {
        return tripDao.getAll();
    }

    public List<TripSummary> getAllByProfileAndProtocolId(int profileId, int protocolId) {
        return this.tripDao.getAllByProfileAndProtocolId(profileId, protocolId);
    }

    public double getTotalKm (int profileId) {
        List<TripSummary> tripSummaries = tripDao.getByProfileId(profileId);
        if (tripSummaries == null) {
            return 0;
        } else {
            return tripSummaries.stream()
                    .mapToDouble(TripSummary::getDistance)
                    .sum();
        }
    }

    // Eine einzelne Fahrt
    public TripDetailedDto getDetailedById(int id, int profileId) {
        TripSummary trip = this.tripDao.getByIdAndProfileId(id, profileId);
        if (trip == null) {
            throw new RuntimeException("Fahrt nicht gefunden oder kein Zugriff");
        }
        List<Trackingpoint> trackingpoints  = this.trackingpointDao.getByTripId(trip.getId());
        TripDetailedDto tripDetailedDto = new TripDetailedDto(trip, trackingpoints);
        enrichWithTrackingPoints(tripDetailedDto);
        return tripDetailedDto;
    }

    // Trackingpunkte berechnen und ins DTO schreiben
    private void enrichWithTrackingPoints(TripDetailedDto trip) {
        List<Trackingpoint> points = trackingpointDao.getByTripId(trip.getTripSummary().getId());

        if (points == null || points.isEmpty()) return;

        // erster Punkt = Startpunkt
        Trackingpoint start = points.get(0);
        // letzter Punkt = Endpunkt
        Trackingpoint end = points.get(points.size() - 1);
        // weitester Punkt vom Start = Punkt mit größter Distanz zum Startpunkt
        Trackingpoint furthest = points.stream()
                .max(Comparator.comparingDouble(p ->
                        calculateDistance(
                                start.getLat(), start.getLng(),
                                p.getLat(), p.getLng()
                        )
                ))
                .orElse(start);
        trip.getTripSummary().setStartPoint(geocodingService.getCity(start.getLat(), start.getLng()));
        trip.getTripSummary().setEndPoint(geocodingService.getCity(end.getLat(), end.getLng()));
        trip.getTripSummary().setFurthestPoint(geocodingService.getCity(furthest.getLat(), furthest.getLng()));
    }

    // Haversine Formel – Distanz zwischen zwei GPS-Punkten in km
    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        final int R = 6371; // Erdradius in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
