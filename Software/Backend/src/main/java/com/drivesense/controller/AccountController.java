package com.drivesense.controller;

import com.drivesense.dto.request.*;
import com.drivesense.dto.response.AccountResponse;
import com.drivesense.dto.response.LoginResponse;
import com.drivesense.dto.response.RefreshResponse;
import com.drivesense.dto.response.SelectProfileResponse;
import com.drivesense.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/account")
public class AccountController {
    @Autowired
    private AccountService accountService;

    @PostMapping("/register")
    public AccountResponse register(@Valid @RequestBody RegisterRequest request) {
        return accountService.register(request);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(accountService.login(request));
    }

    @PostMapping("/select-profile")
    public ResponseEntity<SelectProfileResponse> selectProfile(@RequestParam int profileId, @RequestHeader("Authorization") String authHeader) {
        String token = authHeader.substring(7);
        return ResponseEntity.ok(accountService.selectProfile(profileId, token));
    }

    @PostMapping("/refresh")
    public ResponseEntity<RefreshResponse> refresh(@RequestBody RefreshRequest request) {
        return ResponseEntity.ok(accountService.refresh(request.getRefreshToken()));
    }

    @GetMapping("/{id}")
    public AccountResponse getById(@PathVariable int id) {
        return accountService.getById(id);
    }

    @PutMapping("/{id}")
    public AccountResponse update(@Valid @PathVariable int id, @RequestBody UpdateAccountRequest request) {
        return accountService.update(id, request);
    }

    @PutMapping("/{id}/password")
    public void updatePassword(@Valid @PathVariable int id, @RequestBody UpdatePasswordRequest request) {
        accountService.updatePassword(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable int id) {
        accountService.delete(id);
    }
}
