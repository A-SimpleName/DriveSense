package com.drivesense.dto.request;

import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;

import java.util.List;

public class SaveTripRequest {
    private TripSummary tripSummary;
    private List<Trackingpoint> trackingpoints;

    public SaveTripRequest() {
    }

    public TripSummary getTripSummary() {
        return this.tripSummary;
    }

    public void setTripSummary(TripSummary tripSummary) {
        this.tripSummary = tripSummary;
    }

    public List<Trackingpoint> getTrackingpoints() {
        return this.trackingpoints;
    }

    public void setTrackingpoints(List<Trackingpoint> trackingpoints) {
        this.trackingpoints = trackingpoints;
    }
}
