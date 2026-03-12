package com.drivesense.model;

public class ProfileUsergroup {
    private int profileId;
    private int usergroupId;
    private String groupRole;

    public ProfileUsergroup(){}

    public ProfileUsergroup(int profileId, int usergroupId, String groupRole) {
        this.profileId = profileId;
        this.usergroupId = usergroupId;
        this.groupRole = groupRole;
    }

    public int getProfileId() {
        return profileId;
    }

    public void setProfileId(int profileId) {
        this.profileId = profileId;
    }

    public int getUsergroupId() {
        return usergroupId;
    }

    public void setUsergroupId(int usergroupId) {
        this.usergroupId = usergroupId;
    }

    public String getGroupRole() {
        return groupRole;
    }

    public void setGroupRole(String groupRole) {
        this.groupRole = groupRole;
    }

    @Override
    public String toString() {
        return "ProtocolUser: " +
                "profileId: " + profileId +
                ", usergroupId: " + usergroupId +
                ", groupRole: '" + groupRole + '\'';
    }
}
