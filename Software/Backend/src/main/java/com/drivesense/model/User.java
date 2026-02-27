package com.drivesense.model;

public class User {
    private int id;
    private String name;
    private String role;
    private int account_id;
    private int group_id;

    public User () {}

    public User(String name, String role, int account_id, int group_id) {
        this.name = name;
        this.role = role;
        this.account_id = account_id;
        this.group_id = group_id;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public int getAccount_id() {
        return account_id;
    }

    public void setAccount_id(int account_id) {
        this.account_id = account_id;
    }

    public int getGroup_id() {
        return group_id;
    }

    public void setGroup_id(int group_id) {
        this.group_id = group_id;
    }

    @Override
    public String toString() {
        return "User: " +
                "id: " + id +
                ", name: '" + name + '\'' +
                ", role: '" + role + '\'' +
                ", account_id: " + account_id +
                ", group_id: " + group_id;
    }
}
