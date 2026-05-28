package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class UpdateAccountRequest {
    @NotBlank(message = "Vorname darf nicht leer sein")
    private String firstName;
    @NotBlank(message = "Nachname darf nicht leer sein")
    private String lastName;
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungültig")
    private String email;

    public UpdateAccountRequest(String firstName, String lastName, String email) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
    }
    public UpdateAccountRequest(){}

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
}
