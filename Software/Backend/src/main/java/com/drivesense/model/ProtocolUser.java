package com.drivesense.model;

public class ProtocolUser {
    private int protocolId;
    private int userId;
    private String userRole;

    public ProtocolUser(){}

    public ProtocolUser(int protocolId, int userId, String userRole) {
        this.protocolId = protocolId;
        this.userId = userId;
        this.userRole = userRole;
    }

    public int getProtocolId() {
        return protocolId;
    }

    public void setProtocolId(int protocolId) {
        this.protocolId = protocolId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getUserRole() {
        return userRole;
    }

    public void setUserRole(String userRole) {
        this.userRole = userRole;
    }

    @Override
    public String toString() {
        return "ProtocolUser: " +
                "protocolId: " + protocolId +
                ", userId: " + userId +
                ", userRole: '" + userRole + '\'';
    }
}
