package com.drivesense.dto.response;

public class TripSummaryDto {
    private int id;
    private String accountFname;
    private String accountLname;
    private String vehicleModel;
    private double distance;
    private String type;

    public TripSummaryDto () {

    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getAccountFname() {
        return accountFname;
    }

    public void setAccountFname(String accountFname) {
        this.accountFname = accountFname;
    }

    public String getAccountLname() {
        return accountLname;
    }

    public void setAccountLname(String accountLname) {
        this.accountLname = accountLname;
    }

    public String getVehicleModel() {
        return vehicleModel;
    }

    public void setVehicleModel(String vehicleModel) {
        this.vehicleModel = vehicleModel;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }
}