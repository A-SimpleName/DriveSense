package com.drivesense.dto.response;

import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.List;

public class TripDetailedDto {
    private TripSummary tripSummary;
    private List<Trackingpoint> trackingpoints;

    public TripDetailedDto(TripSummary tripSummary, List<Trackingpoint> trackingpoints) {
        this.tripSummary = tripSummary;
        this.trackingpoints = trackingpoints;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(tripSummary).append('\n');
        for (Trackingpoint t : trackingpoints) {
            sb.append(t).append('\n');
        }
        return sb.toString();
    }

    public TripSummary getTripSummary() {
        return tripSummary;
    }

    public void setTripSummary(TripSummary tripSummary) {
        this.tripSummary = tripSummary;
    }

    public List<Trackingpoint> getTrackingpoints() {
        return trackingpoints;
    }

    public void setTrackingpoints(List<Trackingpoint> trackingpoints) {
        this.trackingpoints = trackingpoints;
    }
}
