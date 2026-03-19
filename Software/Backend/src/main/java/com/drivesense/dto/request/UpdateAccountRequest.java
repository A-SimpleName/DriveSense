package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class UpdateAccountRequest {
    @NotBlank(message = "Vorname darf nicht leer sein")
    private String fname;
    @NotBlank(message = "Nachname darf nicht leer sein")
    private String lname;
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungültig")
    private String email;

    public UpdateAccountRequest(String fname, String lname, String email) {
        this.fname = fname;
        this.lname = lname;
        this.email = email;
    }
    public UpdateAccountRequest(){}

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
