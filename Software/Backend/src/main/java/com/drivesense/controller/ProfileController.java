package com.drivesense.controller;


import com.drivesense.model.Profile;
import com.drivesense.service.ProfileService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/profiles")
public class ProfileController {
    @Autowired
    private ProfileService profileService;

    @GetMapping("/")
    public ResponseEntity<List<Profile>> getAll() {
        return ResponseEntity.ok(profileService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Profile> getById(@PathVariable int id) {
        return ResponseEntity.ok(profileService.getById(id));
    }

    @GetMapping("/byAccount")
    public ResponseEntity<List<Profile>> getProfilesByAccount(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(profileService.getAllProfilesByAccountId(accountId));
    }

    @PutMapping("/")
    public ResponseEntity<Profile> update(@RequestBody Profile profile, HttpServletRequest request) {
        int id = (int) request.getAttribute("profileId");
        profile.setId(id);
        profileService.update(profile);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/")
    public ResponseEntity<Profile> insert(@RequestBody Profile profile, HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        profile.setAccount_id(accountId);
        return ResponseEntity.status(201).body(profileService.insert(profile));
    }

    @DeleteMapping("/")
    public ResponseEntity<Void> delete(HttpServletRequest request) {
        int id = (int) request.getAttribute("profileId");
        profileService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
