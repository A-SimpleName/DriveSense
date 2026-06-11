package com.drivesense.dto.request;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class ResendVerificationRequest {
    @NotBlank(message = "Email darf nicht leer sein")
    @Email(message = "Email Format ungültig")
    private String email;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}
