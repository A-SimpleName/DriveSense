package com.drivesense.dto.request;

import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
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
    @Min(value = 0, message = "Start-Kilometerstand darf nicht negativ sein")
    private Integer startMileage;
    @Min(value = 0, message = "End-Kilometerstand darf nicht negativ sein")
    private Integer endMileage;

    public SaveTripRequest() {
    }

    public SaveTripRequest(TripSummary tripSummary, List<Trackingpoint> trackingpoints) {
        this.tripSummary = tripSummary;
        this.trackingpoints = trackingpoints;
    }

    public SaveTripRequest(TripSummary tripSummary, List<Trackingpoint> trackingpoints, Integer startMileage, Integer endMileage) {
        this.tripSummary = tripSummary;
        this.trackingpoints = trackingpoints;
        this.startMileage = startMileage;
        this.endMileage = endMileage;
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

    public Integer getStartMileage() {
        return startMileage;
    }

    public void setStartMileage(Integer startMileage) {
        this.startMileage = startMileage;
    }

    public Integer getEndMileage() {
        return endMileage;
    }

    public void setEndMileage(Integer endMileage) {
        this.endMileage = endMileage;
    }
}
