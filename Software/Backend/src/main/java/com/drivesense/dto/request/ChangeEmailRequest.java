package com.drivesense.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class ChangeEmailRequest {

    @NotBlank(message = "Neue E-Mail darf nicht leer sein")
    @Email(message = "Ungültige E-Mail-Adresse")
    private String newEmail;

    public String getNewEmail() { return newEmail; }
    public void setNewEmail(String newEmail) { this.newEmail = newEmail; }
}
