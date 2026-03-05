package com.drivesense.model;

public class Protocol {
    private int id;
    private int trip_id;
    private String road_surface_conditions;

    public Protocol(){}

    public Protocol(int trip_id, String road_surface_conditions) {
        this.trip_id = trip_id;
        this.road_surface_conditions = road_surface_conditions;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getTrip_id() {
        return trip_id;
    }

    public void setTrip_id(int tracking_id) {
        this.trip_id = tracking_id;
    }

    public String getRoad_surface_conditions() {
        return road_surface_conditions;
    }

    public void setRoad_surface_conditions(String road_surface_conditions) {
        this.road_surface_conditions = road_surface_conditions;
    }

    @Override
    public String toString() {
        return "Protocol: " +
                "id: " + id +
                ", tracking_id: " + trip_id +
                ", road_surface_conditions: '" + road_surface_conditions + '\'';
    }
}
