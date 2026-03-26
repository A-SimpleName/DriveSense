package com.drivesense.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class UserGroupUpdateRoleRequest {
    @NotBlank(message = "Rolle darf nicht leer sein")
    @Pattern(
            regexp = "OWNER|ADMIN|MEMBER",
            message = "Rolle muss OWNER, ADMIN oder MEMBER sein"
    )
    private String role;

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}
