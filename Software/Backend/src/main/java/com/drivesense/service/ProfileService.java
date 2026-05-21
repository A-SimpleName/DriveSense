package com.drivesense.service;

import com.drivesense.db.ProfileDao;
import com.drivesense.exceptions.*;
import com.drivesense.model.Profile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

@Service
public class ProfileService {
    private final ProfileDao profileDao;

    @Autowired
    public ProfileService(ProfileDao profileDao) {
        this.profileDao = profileDao;
    }

    public Profile insert(Profile profile) {
        profile.setRole(normalizeRole(profile.getRole()));
        return profileDao.insert(profile);
    }

    public Profile getById(int id) {
        Profile profile = profileDao.getById(id);
        if (profile == null) {
            throw new NotFoundException("Profil nicht gefunden");
        }
        return profile;
    }

    public List<Profile> getAll() {
        return profileDao.getAll();
    }

    public void update(Profile profile) {
        Profile existing = profileDao.getById(profile.getId());
        if (existing == null) {
            throw new NotFoundException("Profil nicht gefunden");
        }
        profile.setRole(normalizeRole(profile.getRole()));
        profileDao.update(profile);
    }

    public void deleteById(int id) {
        Profile existing = profileDao.getById(id);
        if (existing == null) {
            throw new NotFoundException("Profil nicht gefunden");
        }
        profileDao.deleteById(id);
    }

    public List<Profile> getAllProfilesByAccountId(int id) {
        return profileDao.getAllProfilesByAccountId(id);
    }

    private String normalizeRole(String role) {
        if (role == null) {
            return null;
        }

        return switch (role.trim().toUpperCase(Locale.ROOT)) {
            case "FAHRSCHÜLER", "FAHRSCHULER", "FAHRSCHUELER" -> "FAHRSCHUELER";
            case "BERUFSFAHRER" -> "BERUFSFAHRER";
            case "PRIVAT" -> "PRIVAT";
            default -> throw new BadRequestException("Ungueltige Profilrolle");
        };
    }
}
