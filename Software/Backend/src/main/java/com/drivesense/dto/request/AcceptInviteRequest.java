package com.drivesense.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.hibernate.validator.constraints.NotEmpty;

public class AcceptInviteRequest {
    @NotBlank(message = "Code darf nicht leer sein")
    private String code;
    @Min(value = 1, message = "Profile darf nicht leer sein")
    private int profileId;

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public int getProfileId() {
        return profileId;
    }

    public void setProfileId(int profileId) {
        this.profileId = profileId;
    }
}
