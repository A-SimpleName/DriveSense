package com.drivesense.model;

public class Protocol {
    private int id;
    private int createdByProfileId;
    private int usergroupId;
    private String name;

    public Protocol(){}

    public Protocol(int createdByProfileId, int usergroupId, String name) {
        this.createdByProfileId = createdByProfileId;
        this.usergroupId = usergroupId;
        this.name = name;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getCreatedByProfileId() {
        return createdByProfileId;
    }

    public void setCreatedByProfileId(int createdByProfileId) {
        this.createdByProfileId = createdByProfileId;
    }

    public int getUsergroupId() {
        return usergroupId;
    }

    public void setUsergroupId(int usergroupId) {
        this.usergroupId = usergroupId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return "Protocol{" +
                "id=" + id +
                ", createdByProfileId=" + createdByProfileId +
                ", usergroupId=" + usergroupId +
                ", name='" + name + '\'' +
                '}';
    }
}
