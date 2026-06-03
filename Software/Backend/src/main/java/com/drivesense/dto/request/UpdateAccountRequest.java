package com.drivesense.dto.request;

import jakarta.validation.constraints.NotBlank;

public class UpdateAccountRequest {

    @NotBlank(message = "Vorname darf nicht leer sein")
    private String firstName;

    @NotBlank(message = "Nachname darf nicht leer sein")
    private String lastName;

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
}
