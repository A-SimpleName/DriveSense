package com.drivesense.dto.request;

import jakarta.validation.constraints.NotBlank;

public class ProtocolCreateRequest {
    @NotBlank(message = "Name darf nicht leer sein")
    private String name;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
