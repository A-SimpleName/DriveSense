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

    public User insertUser (User user) {
        return userDao.insertUser(user);
    }

    public User findById(int id) {
        return userDao.findById(id);
    }

    public List<User> findAll() {
        return userDao.findAll();
    }

    public void updateUser (User user) {
        userDao.update(user);
    }

    public void deleteById(int id) {
        userDao.deleteById(id);
    }

    public List<User> findByGroup_id(int id) {
        return userDao.findByGroup_id(id);
    }

    /* Admin aufruf */
    public List<User> findAllUsersByAccount_id(int id) {
        return userDao.findAllUsersByAccount_id(id);
    }
}
