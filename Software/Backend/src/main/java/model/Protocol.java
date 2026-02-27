package model;

public class Protocol {
    private int id;
    private int tracking_id;
    private String road_surface_conditions;

    public Protocol(){}

    public Protocol(int tracking_id, String road_surface_conditions) {
        this.tracking_id = tracking_id;
        this.road_surface_conditions = road_surface_conditions;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getTracking_id() {
        return tracking_id;
    }

    public void setTracking_id(int tracking_id) {
        this.tracking_id = tracking_id;
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
                ", tracking_id: " + tracking_id +
                ", road_surface_conditions: '" + road_surface_conditions + '\'';
    }
}
