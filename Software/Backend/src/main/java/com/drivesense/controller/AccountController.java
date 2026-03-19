package com.drivesense.controller;

import com.drivesense.dto.request.LoginRequest;
import com.drivesense.dto.request.RegisterRequest;
import com.drivesense.dto.request.UpdateAccountRequest;
import com.drivesense.dto.request.UpdatePasswordRequest;
import com.drivesense.dto.response.AccountResponse;
import com.drivesense.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
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
    public AccountResponse login(@Valid @RequestBody LoginRequest request) {
        return accountService.login(request);
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
