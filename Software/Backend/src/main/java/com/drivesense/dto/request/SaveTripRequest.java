package com.drivesense.dto.request;

import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public class SaveTripRequest {
    @NotNull(message = "TripSummary darf nicht null sein")
    @Valid
    private TripSummary tripSummary;
    @Valid
    @NotNull(message = "Trackingpoints dürfen nicht null sein")
    @Size(min = 2, message = "Mindestens 2 Trackingpoints nötig")
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
