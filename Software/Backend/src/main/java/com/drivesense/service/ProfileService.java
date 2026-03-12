package com.drivesense.service;

import com.drivesense.db.ProfileDao;
import com.drivesense.model.Profile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProfileService {
    private final ProfileDao profileDao;

    @Autowired
    public ProfileService(ProfileDao profileDao) {
        this.profileDao = profileDao;
    }

    public Profile insert (Profile profile) {
        return profileDao.insert(profile);
    }

    public Profile getById(int id) {
        return profileDao.getById(id);
    }

    public List<Profile> getAll() {
        return profileDao.getAll();
    }

    public void update (Profile profile) {
        profileDao.update(profile);
    }

    public void deleteById(int id) {
        profileDao.deleteById(id);
    }

    /* Admin aufruf */
    public List<Profile> getAllUsersByAccount_id(int id) {
        return profileDao.getAllUsersByAccount_id(id);
    }
}
