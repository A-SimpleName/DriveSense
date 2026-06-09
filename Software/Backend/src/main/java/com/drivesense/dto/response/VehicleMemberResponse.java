package com.drivesense.dto.response;

public class VehicleMemberResponse {
    private int profileId;
    private String profileName;
    private String profileRole;
    private String accountName;
    private String accountEmail;
    private String vehicleRole;

    public int getProfileId() {
        return profileId;
    }

    public void setProfileId(int profileId) {
        this.profileId = profileId;
    }

    public String getProfileName() {
        return profileName;
    }

    public void setProfileName(String profileName) {
        this.profileName = profileName;
    }

    public String getProfileRole() {
        return profileRole;
    }

    public void setProfileRole(String profileRole) {
        this.profileRole = profileRole;
    }

    public String getAccountName() {
        return accountName;
    }

    public void setAccountName(String accountName) {
        this.accountName = accountName;
    }

    public String getAccountEmail() {
        return accountEmail;
    }

    public void setAccountEmail(String accountEmail) {
        this.accountEmail = accountEmail;
    }

    public String getVehicleRole() {
        return vehicleRole;
    }

    public void setVehicleRole(String vehicleRole) {
        this.vehicleRole = vehicleRole;
    }
}
