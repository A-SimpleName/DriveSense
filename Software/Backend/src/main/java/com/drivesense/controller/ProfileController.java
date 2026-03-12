package com.drivesense.controller;


import com.drivesense.model.Profile;
import com.drivesense.service.ProfileService;
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

    @GetMapping("/test")
    public ResponseEntity<String> test() {
        return ResponseEntity.ok("Endpunkt profiles läuft");
    }

    @GetMapping("/")
    public ResponseEntity<List<Profile>> getAll() {
        return ResponseEntity.ok(profileService.getAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Profile> getById(@PathVariable int id) {
        return ResponseEntity.ok(profileService.getById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Profile> update(@PathVariable int id, @RequestBody Profile profile) {
        profile.setId(id);
        profileService.update(profile);
        return ResponseEntity.ok().build();
    }

    @PostMapping
    public ResponseEntity<Profile> insert(@RequestBody Profile profile) {
        return ResponseEntity.status(201).body(profileService.insert(profile));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id) {
        profileService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
