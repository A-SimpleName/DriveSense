package com.drivesense.service;


import com.drivesense.db.TrackingpointDao;
import com.drivesense.db.TripDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;

import java.util.List;

public class TripService {
    private TripDao tripDao;

    public TripService () {
        tripDao = new TripDao();
    }

    public void insertTrip (Trip trip, List<Trackingpoint> trackingpoints) {
        TripDao tripDao = new TripDao();
        tripDao.insertTrip(trip);

        TrackingpointDao trackingpointDao = new TrackingpointDao();

        for (Trackingpoint trackingpoint : trackingpoints)
            trackingpointDao.insertTrackingpoint(trackingpoint);
    }

    public List<Trip> getAllTrips() {
        return tripDao.findAll();
    }
}
