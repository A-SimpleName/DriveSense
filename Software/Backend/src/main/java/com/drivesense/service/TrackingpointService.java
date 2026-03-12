package com.drivesense.service;

import com.drivesense.db.TrackingpointDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TrackingpointService {
    @Autowired
    private TrackingpointDao trackingpointDao;

    public Trackingpoint insert (Trackingpoint trackingpoint, TripSummary trip) {
        trackingpoint.setTripId(trip.getId());
        return trackingpointDao.insert(trackingpoint);
    }

    public Trackingpoint getById (int id) {
        return trackingpointDao.getById(id);
    }

    public List<Trackingpoint> getByTripId (int tripId) {
        return trackingpointDao.getByTripId(tripId);
    }

    public List<Trackingpoint> getAll () {
        return trackingpointDao.getAll();
    }

    public void update (Trackingpoint trackingpoint) {
        trackingpointDao.update(trackingpoint);
    }

    public void delete (int id) {
        trackingpointDao.deleteById(id);
    }
}
