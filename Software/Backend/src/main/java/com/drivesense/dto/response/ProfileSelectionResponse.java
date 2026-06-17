package com.drivesense.dto.response;

public class ProfileSelectionResponse {
    private int id;
    private String name;
    private String role;
    private boolean joinable;
    private String joinMessage;
    private String requiredRole;

    public ProfileSelectionResponse(int id, String name, String role) {
        this.id = id;
        this.name = name;
        this.role = role;
        this.joinable = true;
    }

    public ProfileSelectionResponse(
            int id,
            String name,
            String role,
            boolean joinable,
            String joinMessage,
            String requiredRole
    ) {
        this.id = id;
        this.name = name;
        this.role = role;
        this.joinable = joinable;
        this.joinMessage = joinMessage;
        this.requiredRole = requiredRole;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public boolean isJoinable() {
        return joinable;
    }

    public void setJoinable(boolean joinable) {
        this.joinable = joinable;
    }

    public String getJoinMessage() {
        return joinMessage;
    }

    public void setJoinMessage(String joinMessage) {
        this.joinMessage = joinMessage;
    }

    public String getRequiredRole() {
        return requiredRole;
    }

    public void setRequiredRole(String requiredRole) {
        this.requiredRole = requiredRole;
    }
}
