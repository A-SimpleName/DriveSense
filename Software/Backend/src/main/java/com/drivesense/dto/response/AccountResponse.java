package com.drivesense.dto.response;

public class AccountResponse {
    private int id;
    private String fname;
    private String lname;
    private String email;

    public AccountResponse(int id, String lname, String fname, String email) {
        this.id = id;
        this.lname = lname;
        this.fname = fname;
        this.email = email;
    }
    public AccountResponse(){}

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getFname() {
        return fname;
    }

    public void setFname(String fname) {
        this.fname = fname;
    }

    public String getLname() {
        return lname;
    }

    public void setLname(String lname) {
        this.lname = lname;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
