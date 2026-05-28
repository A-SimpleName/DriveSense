package com.drivesense.dto.response;

public class AccountResponse {
    private int id;
    private String fName;
    private String lName;
    private String email;
    private String pendingEmail;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getfName() { return fName; }
    public void setfName(String fName) { this.fName = fName; }

    public String getlName() { return lName; }
    public void setlName(String lName) { this.lName = lName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPendingEmail() { return pendingEmail; }
    public void setPendingEmail(String pendingEmail) { this.pendingEmail = pendingEmail; }
}
