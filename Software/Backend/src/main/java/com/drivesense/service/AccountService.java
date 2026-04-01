package com.drivesense.service;

import com.drivesense.db.AccountDao;
import com.drivesense.db.ProfileDao;
import com.drivesense.dto.request.LoginRequest;
import com.drivesense.dto.request.SignUpRequest;
import com.drivesense.dto.request.UpdateAccountRequest;
import com.drivesense.dto.request.UpdatePasswordRequest;
import com.drivesense.dto.response.AccountResponse;
import com.drivesense.dto.response.LoginResponse;
import com.drivesense.dto.response.RefreshResponse;
import com.drivesense.dto.response.SelectProfileResponse;
import com.drivesense.exceptions.*;
import com.drivesense.model.Account;
import com.drivesense.model.Profile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AccountService {
    @Autowired
    private AccountDao accountDao;
    @Autowired
    private ProfileDao profileDao;
    @Autowired
    private JwtService jwtService;

    public AccountResponse signUp(SignUpRequest request) {
        Account existing = accountDao.getByEmail(request.getEmail());
        if (existing != null) {
            throw new BadRequestException("Email bereits vergeben");
        }

        String hashedPassword = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt());

        Account account = new Account();
        account.setfName(request.getFname());
        account.setlName(request.getLname());
        account.setEmail(request.getEmail());
        account.setPassword(hashedPassword);
        account.setBirthdate(request.getBirthdate());
        accountDao.insert(account);

        return toResponse(account);
    }

    public LoginResponse login(LoginRequest request) {
        Account account = accountDao.getByEmail(request.getEmail());
        // bewusst gleiche Message für Email und Passwort – kein Hinweis welches falsch ist
        if (account == null || !BCrypt.checkpw(request.getPassword(), account.getPassword())) {
            throw new BadRequestException("Email oder Passwort falsch");
        }

        List<Profile> profiles = profileDao.getAllProfilesByAccountId(account.getId());

        LoginResponse res = new LoginResponse();
        res.setAccountToken(jwtService.generateAccountToken(account.getId()));
        res.setRefreshToken(jwtService.generateRefreshToken(account.getId()));
        res.setProfiles(profiles);
        return res;
    }

    public SelectProfileResponse selectProfile(int profileId, String accountToken) {
        if (!jwtService.isValid(accountToken) || !jwtService.extractType(accountToken).equals("ACCOUNT")) {
            throw new UnauthorizedException("Ungültiger Account Token");
        }

        int accountId = jwtService.extractAccountId(accountToken);
        Profile profile = profileDao.getById(profileId);

        if (profile == null || profile.getAccount_id() != accountId) {
            throw new NotFoundException("Profil nicht gefunden");
        }

        SelectProfileResponse res = new SelectProfileResponse();
        res.setProfileToken(jwtService.generateProfileToken(accountId, profileId, profile.getRole()));
        res.setProfile(profile);
        return res;
    }

    public RefreshResponse refresh(String refreshToken) {
        if (!jwtService.isValid(refreshToken) || !jwtService.extractType(refreshToken).equals("REFRESH")) {
            throw new UnauthorizedException("Ungültiger Refresh Token");
        }

        int accountId = jwtService.extractAccountId(refreshToken);
        RefreshResponse res = new RefreshResponse();
        res.setAccountToken(jwtService.generateAccountToken(accountId));
        return res;
    }

    public AccountResponse getById(int id) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new NotFoundException("Account nicht gefunden");
        }
        return toResponse(account);
    }

    public List<Account> getAll () {
        return accountDao.getAll();
    }

    public AccountResponse update(int id, UpdateAccountRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new NotFoundException("Account nicht gefunden");
        }

        account.setfName(request.getFname());
        account.setlName(request.getLname());
        account.setEmail(request.getEmail());
        accountDao.update(account);

        return toResponse(account);
    }

    public void updatePassword(int id, UpdatePasswordRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new NotFoundException("Account nicht gefunden");
        }

        if (!BCrypt.checkpw(request.getOldPassword(), account.getPassword())) {
            throw new BadRequestException("Altes Passwort falsch");
        }

        // neues Passwort darf nicht gleich wie altes sein
        if (BCrypt.checkpw(request.getNewPassword(), account.getPassword())) {
            throw new BadRequestException("Neues Passwort darf nicht gleich wie das alte sein");
        }

        String hashedPassword = BCrypt.hashpw(request.getNewPassword(), BCrypt.gensalt());
        accountDao.updatePassword(id, hashedPassword);
    }

    public void delete(int id) {
        Account account = accountDao.getById(id);
        if (account == null) {
            throw new NotFoundException("Account nicht gefunden");
        }
        accountDao.deleteById(id);
    }

    private AccountResponse toResponse(Account account) {
        AccountResponse res = new AccountResponse();
        res.setId(account.getId());
        res.setFname(account.getfName());
        res.setLname(account.getlName());
        res.setEmail(account.getEmail());
        return res;
    }
}
