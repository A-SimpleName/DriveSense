package com.drivesense.model;

import java.time.LocalDate;

public class Account {
    private int id;
    private String fName;
    private String lName;
    private String password;
    private String email;
    private LocalDate birthdate;
    private boolean emailVerified;
    private String pendingEmail;

    public String getPendingEmail() { return pendingEmail; }
    public void setPendingEmail(String pendingEmail) { this.pendingEmail = pendingEmail; }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getfName() {
        return fName;
    }

    public void setfName(String fName) {
        this.fName = fName;
    }

    public String getlName() {
        return lName;
    }

    public void setlName(String lName) {
        this.lName = lName;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public LocalDate getBirthdate() {
        return birthdate;
    }

    public void setBirthdate(LocalDate birthdate) {
        this.birthdate = birthdate;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public boolean isEmailVerified() { return emailVerified; }
    public void setEmailVerified(boolean emailVerified) { this.emailVerified = emailVerified; }

    @Override
    public String toString() {
        return "Account: " +
                "id: " + id +
                ", fName: '" + fName + '\'' +
                ", lName: '" + lName + '\'' +
                ", password: '" + password + '\'' +
                ", email: '" + email + '\'';
    }
}
