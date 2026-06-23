package com.drivesense.dto.request;

import jakarta.validation.constraints.NotBlank;

public class ConfirmEmailChangeRequest {
    @NotBlank(message = "Code darf nicht leer sein")
    private String code;

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
}
