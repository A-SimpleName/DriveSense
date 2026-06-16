package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class UpdateAccountRequest {
    @NotBlank(message = "Vorname darf nicht leer sein")
    private String firstName;
    @NotBlank(message = "Nachname darf nicht leer sein")
    private String lastName;

    public UpdateAccountRequest(String firstName, String lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
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
}
