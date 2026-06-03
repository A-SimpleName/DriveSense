package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

public class SignUpRequest {
    @NotBlank(message = "Vorname darf nicht leer sein")
    private String firstName;
    @NotBlank(message = "Nachname darf nicht leer sein")
    private String lastName;
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungültig")
    private String email;
    @NotBlank(message = "Neues Passwort darf nicht leer sein")
    @Size(min = 8,max=50, message = "Passwort muss mindestens 8 Zeichen und maximal 50 haben")
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).*$",
            message = "Passwort muss mindestens einen Großbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten"
    )
    private String password;
    @Past
    private LocalDate birthdate;

    public SignUpRequest(String firstName, String lastName, String email, String password,LocalDate birthdate) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.password = password;
        this.birthdate = birthdate;
    }

    public SignUpRequest(){}

    public LocalDate getBirthdate() {
        return birthdate;
    }

    public void setBirthdate(LocalDate birthdate) {
        this.birthdate = birthdate;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
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
