package com.drivesense.service;

import com.drivesense.db.TrackingpointDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class TrackingpointService {
    @Autowired
    private TrackingpointDao trackingpointDao;

    public void insert (Trackingpoint trackingpoint, Trip trip) {
        trackingpoint.setTrip_id(trip.getId());
        trackingpointDao.insert(trackingpoint);
    }
}
