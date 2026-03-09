package com.drivesense.service;

import com.drivesense.db.AccountDao;
import com.drivesense.dto.request.LoginRequest;
import com.drivesense.dto.request.RegisterRequest;
import com.drivesense.dto.request.UpdateAccountRequest;
import com.drivesense.dto.request.UpdatePasswordRequest;
import com.drivesense.dto.response.AccountResponse;
import com.drivesense.model.Account;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;

@Service
public class AccountService {
    @Autowired
    private AccountDao accountDao;

    // Registrieren
    public AccountResponse register(RegisterRequest request) {
        Account existing = accountDao.getByEmail(request.getEmail());
        if (existing != null) {
            throw new RuntimeException("Email bereits vergeben");
        }

        String hashedPassword = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt());

        Account account = new Account();
        account.setfName(request.getFname());
        account.setlName(request.getLname());
        account.setEmail(request.getEmail());
        account.setPassword(hashedPassword);
        accountDao.insert(account);

        return toResponse(account);
    }

    // Login
    public AccountResponse login(LoginRequest request) {
        // 1. Account per Email suchen
        Account account = accountDao.getByEmail(request.getEmail());
        if (account == null) {
            throw new RuntimeException("Email oder Passwort falsch");
        }

        // 2. Passwort prüfen
        if (!BCrypt.checkpw(request.getPassword(), account.getPassword())) {
            throw new RuntimeException("Email oder Passwort falsch");
        }

        return toResponse(account);
    }

    // Account anzeigen
    public AccountResponse getById(int id) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new RuntimeException("Account nicht gefunden");
        }
        return toResponse(account);
    }

    // Account updaten
    public AccountResponse update(int id, UpdateAccountRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new RuntimeException("Account nicht gefunden");
        }

        account.setfName(request.getFname());
        account.setlName(request.getLname());
        account.setEmail(request.getEmail());
        accountDao.update(account);

        return toResponse(account);
    }

    // Passwort ändern
    public void updatePassword(int id, UpdatePasswordRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new RuntimeException("Account nicht gefunden");
        }

        // altes Passwort prüfen
        if (!BCrypt.checkpw(request.getOldPassword(), account.getPassword())) {
            throw new RuntimeException("Altes Passwort falsch");
        }

        String hashedPassword = BCrypt.hashpw(request.getNewPassword(), BCrypt.gensalt());
        accountDao.updatePassword(id, hashedPassword);
    }

    // Account löschen
    public void delete(int id) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new RuntimeException("Account nicht gefunden");
        }
        accountDao.deleteById(id);
    }

    // Entity → DTO
    private AccountResponse toResponse(Account account) {
        AccountResponse res = new AccountResponse();
        res.setId(account.getId());
        res.setFname(account.getfName());
        res.setLname(account.getlName());
        res.setEmail(account.getEmail());
        return res;
    }
}
