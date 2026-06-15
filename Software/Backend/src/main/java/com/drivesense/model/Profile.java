package com.drivesense.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class Profile {
    private int id;
    @NotBlank(message = "Profilname darf nicht leer sein")
    @Size(max = 100, message = "Name darf maximal 100 Zeichen haben")
    private String name;
    @NotBlank(message = "Rolle darf nicht leer sein")
    @Pattern(
            regexp = "PRIVAT|FAHRSCHÜLER|FAHRSCHUELER|FAHRSCHULER|BERUFSFAHRER",
            message = "Rolle muss PRIVAT, FAHRSCHUELER oder BERUFSFAHRER sein"
    )
    private String role;
    private int account_id;

    public Profile() {}

    public Profile(String name, String role, int account_id) {
        this.name = name;
        this.role = role;
        this.account_id = account_id;
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

    @Override
    public String toString() {
        return "User: " +
                "id: " + id +
                ", name: '" + name + '\'' +
                ", role: '" + role + '\'' +
                ", account_id: " + account_id;
    }
}
