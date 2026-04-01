package com.drivesense.dto.response;

import java.util.List;

public class ProtocolDto {
    private int id;
    private int created_by_profile_id;
    private int usergroup_id;
    private String created_at;
    private String name;
    private List<TripSummaryDto> trips;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getCreated_by_profile_id() {
        return created_by_profile_id;
    }

    public void setCreated_by_profile_id(int created_by_profile_id) {
        this.created_by_profile_id = created_by_profile_id;
    }

    public int getUsergroup_id() {
        return usergroup_id;
    }

    public void setUsergroup_id(int usergroup_id) {
        this.usergroup_id = usergroup_id;
    }

    public String getCreated_at() {
        return created_at;
    }

    public void setCreated_at(String created_at) {
        this.created_at = created_at;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<TripSummaryDto> getTrips() {
        return trips;
    }

    public void setTrips(List<TripSummaryDto> trips) {
        this.trips = trips;
    }
}
