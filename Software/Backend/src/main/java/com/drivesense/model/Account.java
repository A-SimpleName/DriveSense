package com.drivesense.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class Account {
    private int id;
    private String fName;
    private String lName;
    private String password;
    private String email;
    private String pendingEmail;
    private LocalDate birthdate;
    private boolean emailVerified;
    private LocalDateTime deletedAt;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getfName() { return fName; }
    public void setfName(String fName) { this.fName = fName; }

    public String getlName() { return lName; }
    public void setlName(String lName) { this.lName = lName; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPendingEmail() { return pendingEmail; }
    public void setPendingEmail(String pendingEmail) { this.pendingEmail = pendingEmail; }

    public LocalDate getBirthdate() { return birthdate; }
    public void setBirthdate(LocalDate birthdate) { this.birthdate = birthdate; }

    public boolean isEmailVerified() { return emailVerified; }
    public void setEmailVerified(boolean emailVerified) { this.emailVerified = emailVerified; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public boolean isDeleted() { return deletedAt != null; }
}
