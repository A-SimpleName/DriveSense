package com.drivesense.service;

import com.drivesense.db.UserDao;
import com.drivesense.model.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserService {

    @Autowired
    private UserDao userDao;

    public User insert (User user) {
        return userDao.insert(user);
    }

    public User getById(int id) {
        return userDao.getById(id);
    }

    public List<User> getAll() {
        return userDao.getAll();
    }

    public void update (User user) {
        userDao.update(user);
    }

    public void deleteById(int id) {
        userDao.deleteById(id);
    }

    public List<User> getByGroup_id(int id) {
        return userDao.getByGroup_id(id);
    }

    /* Admin aufruf */
    public List<User> getAllUsersByAccount_id(int id) {
        return userDao.getAllUsersByAccount_id(id);
    }
}
