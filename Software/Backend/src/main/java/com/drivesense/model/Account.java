package com.drivesense.model;

import java.time.LocalDate;

public class Account {
    private int id;
    private String fName;
    private String lName;
    private String password;
    private String email;
    private LocalDate birthdate;

    public Account () {}
    public Account(String fName, String lName, String password, String email, LocalDate birthdate) {
        this.fName = fName;
        this.lName = lName;
        this.password = password;
        this.email = email;
        this.birthdate = birthdate;
    }

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
