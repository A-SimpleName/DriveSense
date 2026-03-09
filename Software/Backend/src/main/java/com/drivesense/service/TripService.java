package com.drivesense.service;


import com.drivesense.db.TrackingpointDao;
import com.drivesense.db.TripDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TripService {
    private final TripDao tripDao;
    private final TrackingpointDao trackingpointDao;

    @Autowired
    public TripService(TripDao tripDao, TrackingpointDao trackingpointDao) {
        this.tripDao = tripDao;
        this.trackingpointDao = trackingpointDao;
    }

    public void insertTrip(TripSummary tripSummary, List<Trackingpoint> trackingpoints) {
        int id = tripDao.insert(tripSummary);

        for (Trackingpoint trackingpoint : trackingpoints) {
            trackingpoint.setTripId(id);
            System.out.println("Point tripId before insert: " + trackingpoint.getTripId());
            trackingpointDao.insert(trackingpoint);
        }
    }

    public List<TripSummary> getAllTrips() {
        return tripDao.getAll();
    }
}
