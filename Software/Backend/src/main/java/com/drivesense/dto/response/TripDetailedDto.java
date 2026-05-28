package com.drivesense.dto.response;

import com.drivesense.model.Trackingpoint;

import java.util.ArrayList;
import java.util.List;

public class TripDetailedDto {
    private TripSummaryDto tripSummary;
    private List<Trackingpoint> trackingpoints;

    public TripDetailedDto(TripSummaryDto tripSummary, List<Trackingpoint> trackingpoints) {
        this.tripSummary = tripSummary;
        this.trackingpoints = trackingpoints;
    }

    public TripDetailedDto(TripSummaryDto tripSummary) {
        this.tripSummary = tripSummary;
        this.trackingpoints = new ArrayList<>();
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

    public TripSummaryDto getTripSummary() {
        return tripSummary;
    }

    public void setTripSummary(TripSummaryDto tripSummary) {
        this.tripSummary = tripSummary;
    }

    public List<Trackingpoint> getTrackingpoints() {
        return trackingpoints;
    }

    public void setTrackingpoints(List<Trackingpoint> trackingpoints) {
        this.trackingpoints = trackingpoints;
    }
}
