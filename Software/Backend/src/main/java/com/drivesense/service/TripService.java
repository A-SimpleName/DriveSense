package com.drivesense.service;


import com.drivesense.db.TripDao;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.Trip;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TripService {
    @Autowired
    private TripDao tripDao;

    public void insert (Trip trip, List<Trackingpoint> trackingpoints) {
        TripDao tripDao = new TripDao();
        Trip savedtrip = tripDao.insert(trip);

        TrackingpointService trackingpointService = new TrackingpointService();

        for (Trackingpoint trackingpoint : trackingpoints) {
            trackingpointService.insert(trackingpoint,savedtrip);
        }
    }

    public List<Trip> getByUserId (int userId) {
        return tripDao.getByUserId(userId);
    }

    public Trip getById (int id) {
        return tripDao.getById(id);
    }

    public void update (Trip trip) {
        tripDao.update(trip);
    }

    public void delete (int id) {
        tripDao.deleteById(id);
    }

    public List<Trip> getAllTrips() {
        return tripDao.getAll();
    }
}
