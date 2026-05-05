package com.drivesense.model;

import java.time.LocalDateTime;

public class GroupInvitation {
    private int id;
    private int groupId;
    private int invitedAccountId;
    private int invitedByProfileId;
    private String codeHash;
    private String status;
    private LocalDateTime expiresAt;
    private LocalDateTime createdAt;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getGroupId() {
        return groupId;
    }

    public void setGroupId(int groupId) {
        this.groupId = groupId;
    }

    public int getInvitedAccountId() {
        return invitedAccountId;
    }

    public void setInvitedAccountId(int invitedAccountId) {
        this.invitedAccountId = invitedAccountId;
    }

    public int getInvitedByProfileId() {
        return invitedByProfileId;
    }

    public void setInvitedByProfileId(int invitedByProfileId) {
        this.invitedByProfileId = invitedByProfileId;
    }

    public String getCodeHash() {
        return codeHash;
    }

    public void setCodeHash(String codeHash) {
        this.codeHash = codeHash;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
