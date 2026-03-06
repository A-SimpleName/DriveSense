package com.drivesense.controller;


import com.drivesense.model.User;
import com.drivesense.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/users")
public class UserController {
    @Autowired
    private UserService userService;

    @GetMapping("/test")
    public String test() {
        return "Endpunkt users läuft";
    }

    @GetMapping("/")
    public List<User> getAll() {
        return userService.getAll();
    }

    @GetMapping("/{id}")
    public User getUserById(int id) {
        return userService.getById(id);
    }
    @PutMapping("/")
    public void updateUser(User user) {
        userService.update(user);
    }

    @PostMapping("/")
    public User insertUser(User user) {
        return userService.insert(user);
    }

    @DeleteMapping("/")
    public void deleteUser(int id) {
        userService.deleteById(id);
    }
}
