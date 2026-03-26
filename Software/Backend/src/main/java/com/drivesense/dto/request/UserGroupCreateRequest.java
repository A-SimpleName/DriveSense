package com.drivesense.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class UserGroupCreateRequest {
    @NotBlank(message = "Name darf nicht leer sein")
    @Size(max = 100, message = "Name darf maximal 100 Zeichen haben")
    private String name;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}
