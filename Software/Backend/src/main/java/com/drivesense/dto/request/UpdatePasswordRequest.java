package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class UpdatePasswordRequest {
    @NotBlank(message = "Altes Passwort darf nicht leer sein")
    private String oldPassword;
    @NotBlank(message = "Neues Passwort darf nicht leer sein")
    @Size(min = 8, max=50, message = "Passwort muss mindestens 8 Zeichen und maximal 50 haben")
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).*$",
            message = "Passwort muss mindestens einen Großbuchstaben, einen Kleinbuchstaben und eine Zahl enthalten"
    )
    private String newPassword;

    public UpdatePasswordRequest(String oldPassword, String newPassword) {
        this.oldPassword = oldPassword;
        this.newPassword = newPassword;
    }

    public UpdatePasswordRequest(){}

    public String getNewPassword() {
        return newPassword;
    }

    public void setNewPassword(String newPassword) {
        this.newPassword = newPassword;
    }

    public String getOldPassword() {
        return oldPassword;
    }

    public void setOldPassword(String oldPassword) {
        this.oldPassword = oldPassword;
    }
}
