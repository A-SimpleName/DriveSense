package com.drivesense.controller;

import com.drivesense.dto.request.*;
import com.drivesense.dto.response.AccountResponse;
import com.drivesense.dto.response.LoginResponse;
import com.drivesense.dto.response.RefreshResponse;
import com.drivesense.dto.response.SelectProfileResponse;
import com.drivesense.service.AccountService;
import jakarta.servlet.http.HttpServletRequest;
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
    public ResponseEntity<AccountResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(accountService.register(request));
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
    public ResponseEntity<RefreshResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(accountService.refresh(request.getRefreshToken()));
    }

    @GetMapping("/")
    public ResponseEntity<AccountResponse> getById(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(accountService.getById(accountId));
    }
    @PutMapping("/")
    public ResponseEntity<AccountResponse> update(@Valid @RequestBody UpdateAccountRequest request, HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        return ResponseEntity.ok(accountService.update(accountId, request));
    }

    @PutMapping("/password")
    public ResponseEntity<Void> updatePassword(@Valid @RequestBody UpdatePasswordRequest request, HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        accountService.updatePassword(accountId, request);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/")
    public ResponseEntity<Void> delete(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        accountService.delete(accountId);
        return ResponseEntity.noContent().build();
    }
}
