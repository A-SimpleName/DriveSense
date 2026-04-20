package com.drivesense.dto.response;

import com.drivesense.model.Account;
import com.drivesense.model.Profile;
import com.drivesense.model.UserGroup;

import java.time.LocalDateTime;
import java.util.List;

public class ProtocolDto {
    private int id;
    private AccountResponse created_by_account;
    private String protocolRole;
    private UserGroup usergroup;
    private LocalDateTime created_at;
    private String name;
    private List<TripSummaryDto> trips;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public AccountResponse getCreated_by_account() {
        return created_by_account;
    }

    public void setCreated_by_account(AccountResponse created_by_account) {
        this.created_by_account = created_by_account;
    }

    public String getProtocolRole() {
        return protocolRole;
    }

    public void setProtocolRole(String protocolRole) {
        this.protocolRole = protocolRole;
    }

    public UserGroup getUsergroup() {
        return usergroup;
    }

    public void setUsergroup(UserGroup usergroup) {
        this.usergroup = usergroup;
    }

    public LocalDateTime getCreated_at() {
        return created_at;
    }

    public void setCreated_at(LocalDateTime created_at) {
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
