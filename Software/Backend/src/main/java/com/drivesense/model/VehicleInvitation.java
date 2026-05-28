package com.drivesense.model;

import java.time.LocalDateTime;

public class VehicleInvitation {
    private int id;
    private int vehicleId;
    private int invitedAccountId;
    private int invitedByProfileId;
    private String codeHash;
    private String status;       // PENDING | ACCEPTED | EXPIRED
    private String role;         // OWNER | CO_OWNER | DRIVER
    private LocalDateTime expiresAt;
    private LocalDateTime createdAt;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getVehicleId() { return vehicleId; }
    public void setVehicleId(int vehicleId) { this.vehicleId = vehicleId; }

    public int getInvitedAccountId() { return invitedAccountId; }
    public void setInvitedAccountId(int invitedAccountId) { this.invitedAccountId = invitedAccountId; }

    public int getInvitedByProfileId() { return invitedByProfileId; }
    public void setInvitedByProfileId(int invitedByProfileId) { this.invitedByProfileId = invitedByProfileId; }

    public String getCodeHash() { return codeHash; }
    public void setCodeHash(String codeHash) { this.codeHash = codeHash; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
