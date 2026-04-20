package com.drivesense.model;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class Protocol {
    private int id;
    @Min(value = 1, message = "Profile ID muss größer als 0 sein")
    private int createdByProfileId;
    private Integer usergroupId;
    @NotBlank(message = "Name darf nicht leer sein")
    @Size(max = 100, message = "Name darf maximal 100 Zeichen haben")
    private String name;

    public Protocol(){}

    public Protocol(int createdByProfileId, Integer usergroupId, String name) {
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

    public Integer getUsergroupId() {
        return usergroupId;
    }

    public void setUsergroupId(Integer usergroupId) {
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
