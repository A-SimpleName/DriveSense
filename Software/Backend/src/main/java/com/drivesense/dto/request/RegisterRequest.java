package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class RegisterRequest {
    @NotBlank(message = "Vorname darf nicht leer sein")
    private String fname;
    @NotBlank(message = "Nachname darf nicht leer sein")
    private String lname;
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungültig")
    private String email;
    @NotBlank(message = "Neues Passwort darf nicht leer sein")
    @Size(min = 8, message = "Passwort muss mindestens 8 Zeichen haben")
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).*$",
            message = "Passwort muss mindestens einen Großbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten"
    )
    private String password;

    public RegisterRequest(String fname, String lname, String email, String password) {
        this.fname = fname;
        this.lname = lname;
        this.email = email;
        this.password = password;
    }

    public RegisterRequest(){}

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

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
