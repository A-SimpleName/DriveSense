package com.drivesense.service;


import com.drivesense.db.TrackingpointDao;
import com.drivesense.db.TripDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;

import java.util.List;

public class TripService {

    public void saveTrip (Trip trip, List<Trackingpoint> trackingpoints) {
        TripDao.insertTrip(trip);
        for (Trackingpoint trackingpoint : trackingpoints)
            TrackingpointDao.insertTrackingpoint(trackingpoint);
    }
}
