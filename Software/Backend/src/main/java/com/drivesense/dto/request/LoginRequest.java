package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class LoginRequest {
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungültig")
    private String email;
    @NotBlank(message = "Passwort darf nicht leer sein")
    private String password;

    public LoginRequest(String email, String password) {
        this.email = email;
        this.password = password;
    }
    public LoginRequest(){}

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
