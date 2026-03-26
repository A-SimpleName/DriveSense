package com.drivesense.dto.request;

import jakarta.validation.constraints.*;

public class RefreshRequest {
    @NotBlank(message = "Token darf nicht leer sein")
    private String refreshToken;

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }
}
