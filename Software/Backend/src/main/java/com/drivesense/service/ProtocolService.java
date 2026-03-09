package com.drivesense.service;

import com.drivesense.db.*;
import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.model.Trackingpoint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;

@Service
public class ProtocolService {
    @Autowired
    private ProtocolDetailDao protocolDetailDao;

    @Autowired
    private ProtocolDao protocolDao;

    @Autowired
    private ProtocolUserDao protocolUserDao;

    @Autowired
    private TripDao tripDao;

    @Autowired
    private TrackingpointDao trackingpointDao;

    private GeocodingService geocodingService = new GeocodingService();

    public List<ProtocolDto> getAllByUser(int userId) {
        List<ProtocolDto> trips = protocolDetailDao.getAllWithDetailsbyUserId(userId);

        // für jede Fahrt die Punkte berechnen
        if(!trips.isEmpty()) {
            trips.forEach(trip -> enrichWithTrackingPoints(trip));
        }
        return trips;
    }

    // Eine einzelne Fahrt
    public ProtocolDto getById(int id, int userId) {
        ProtocolDto trip = protocolDetailDao.getByIdAndUserId(id, userId);
        if (trip == null) {
            throw new RuntimeException("Fahrt nicht gefunden oder kein Zugriff");
        }
        enrichWithTrackingPoints(trip);
        return trip;
    }

    // Trackingpunkte berechnen und ins DTO schreiben
    private void enrichWithTrackingPoints(ProtocolDto trip) {
        List<Trackingpoint> points = trackingpointDao.getByTripId(trip.getTripId());

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
        trip.setStartPoint(geocodingService.getCity(start.getLat(), start.getLng()));
        trip.setEndPoint(geocodingService.getCity(end.getLat(), end.getLng()));
        trip.setFurthestPoint(geocodingService.getCity(furthest.getLat(), furthest.getLng()));
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
