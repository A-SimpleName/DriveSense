package com.drivesense.controller;

import com.drivesense.dto.account.*;
import com.drivesense.service.AccountService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/account")
public class AccountController {

    private AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @PostMapping("/register")
    public AccountResponse register(@RequestBody RegisterRequest request) {
        return accountService.register(request);
    }

    @PostMapping("/login")
    public AccountResponse login(@RequestBody LoginRequest request) {
        return accountService.login(request);
    }

    @GetMapping("/{id}")
    public AccountResponse getById(@PathVariable int id) {
        return accountService.getById(id);
    }

    @PutMapping("/{id}")
    public AccountResponse update(@PathVariable int id, @RequestBody UpdateAccountRequest request) {
        return accountService.update(id, request);
    }

    @PutMapping("/{id}/password")
    public void updatePassword(@PathVariable int id, @RequestBody UpdatePasswordRequest request) {
        accountService.updatePassword(id, request);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable int id) {
        accountService.delete(id);
    }
}
