package com.drivesense.dto.response;

import com.drivesense.model.Profile;

public class SelectProfileResponse {
    private String profileToken;
    private Profile profile;

    public String getProfileToken() {
        return profileToken;
    }

    public void setProfileToken(String profileToken) {
        this.profileToken = profileToken;
    }

    public Profile getProfile() {
        return profile;
    }

    public void setProfile(Profile profile) {
        this.profile = profile;
    }
}
