package com.drivesense.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class CancelSignUpRequest {
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungueltig")
    private String email;

    @NotBlank(message = "Passwort darf nicht leer sein")
    private String password;

    public CancelSignUpRequest() {}

    public CancelSignUpRequest(String email, String password) {
        this.email = email;
        this.password = password;
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
