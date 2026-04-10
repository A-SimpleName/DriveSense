package com.drivesense.controller;

import com.drivesense.exceptions.UnauthorizedException;
import com.drivesense.model.Profile;
import com.drivesense.service.ProfileService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/profiles")
public class ProfileController {

    @Autowired
    private ProfileService profileService;

    @GetMapping
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

    @PostMapping
    public ResponseEntity<Profile> insert(@Valid @RequestBody Profile profile,
                                          HttpServletRequest request) {

        int accountId = (int) request.getAttribute("accountId");

        profile.setAccount_id(accountId);

        return ResponseEntity.status(201).body(profileService.insert(profile));
    }


    @PutMapping("/{id}")
    public ResponseEntity<Profile> update(@PathVariable int id,
                                          @Valid @RequestBody Profile profile,
                                          HttpServletRequest request) {

        int profileId = (int) request.getAttribute("profileId");

        if (profileId != id) {
            throw new UnauthorizedException("Profil-Token stimmt nicht");
        }

        profile.setId(profileId);
        profileService.update(profile);

        return ResponseEntity.ok(profile);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id,
                                       HttpServletRequest request) {

        int profileId = (int) request.getAttribute("profileId");

        if (profileId != id) {
            throw new UnauthorizedException("Nicht erlaubt");
        }

        profileService.deleteById(profileId);

        return ResponseEntity.noContent().build();
    }
}