package com.drivesense.dto.response;

public class GroupMemberResponse {
    private int profileId;
    private String name;
    private String groupRole;

    public GroupMemberResponse (){}

    public GroupMemberResponse(int profileId, String name, String groupRole) {
        this.profileId = profileId;
        this.name = name;
        this.groupRole = groupRole;
    }

    public int getProfileId() {
        return profileId;
    }

    public void setProfileId(int profileId) {
        this.profileId = profileId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getGroupRole() {
        return groupRole;
    }

    public void setGroupRole(String groupRole) {
        this.groupRole = groupRole;
    }
}
