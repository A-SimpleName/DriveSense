package com.drivesense.service;

import com.drivesense.db.AccountDao;
import com.drivesense.db.ProfileDao;
import com.drivesense.dto.request.*;
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

    @Autowired private AccountDao accountDao;
    @Autowired private ProfileDao profileDao;
    @Autowired private JwtService jwtService;
    @Autowired private EmailVerificationService emailVerificationService;

    // ── Auth ────────────────────────────────────────────────────────────────

    public AccountResponse signUp(SignUpRequest request) {
        // Inline-Feldfehler → erscheint direkt beim E-Mail-Feld im Frontend
        if (accountDao.getByEmail(request.getEmail()) != null) {
            throw new FieldValidationException("email", "Email ist bereits vergeben");
        }

        Account account = new Account();
        account.setFirstName(request.getFirstName());
        account.setLastName(request.getLastName());
        account.setEmail(request.getEmail());
        account.setPassword(BCrypt.hashpw(request.getPassword(), BCrypt.gensalt()));
        account.setBirthdate(request.getBirthdate());

        accountDao.insert(account);
        emailVerificationService.sendVerificationCode(account.getId(), account.getEmail());

        return toResponse(account);
    }

    public LoginResponse login(LoginRequest request) {
        Account account = accountDao.getByEmail(request.getEmail());
        if (account == null || !BCrypt.checkpw(request.getPassword(), account.getPassword())) {
            throw new UnauthorizedException("Email oder Passwort falsch");
        }
        if (!account.isEmailVerified()) {
            throw new UnauthorizedException("Email nicht verifiziert");
        }

        List<Profile> profiles = profileDao.getAllProfilesByAccountId(account.getId());

        String accountToken = jwtService.generateAccountToken(account.getId());
        String refreshToken = jwtService.generateRefreshToken(account.getId());

        LoginResponse response = new LoginResponse();
        response.setAccountToken(accountToken);
        response.setRefreshToken(refreshToken);
        response.setProfiles(profiles);
        return response;
    }

    public SelectProfileResponse selectProfile(int profileId, String accountToken) {
        int accountId = jwtService.extractAccountId(accountToken);
        Profile profile = profileDao.getById(profileId);
        if (profile == null || profile.getAccount_id() != accountId) {
            throw new UnauthorizedException("Profil nicht gefunden oder kein Zugriff");
        }
        String profileToken = jwtService.generateProfileToken(accountId, profileId, profile.getRole());
        SelectProfileResponse res = new SelectProfileResponse();
        res.setProfileToken(profileToken);
        res.setProfile(profile);
        return res;
    }

    public RefreshResponse refresh(String refreshToken) {
        int accountId = jwtService.extractAccountId(refreshToken);
        Account account = accountDao.getById(accountId);
        if (account == null) throw new UnauthorizedException("Account nicht gefunden");
        RefreshResponse res = new RefreshResponse();
        res.setAccountToken(jwtService.generateAccountToken(accountId));
        return res;
    }

    // ── Lesen ───────────────────────────────────────────────────────────────

    public AccountResponse getById(int id) {
        Account account = accountDao.getById(id);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        return toResponse(account);
    }

    public List<Account> getAll() {
        return accountDao.getAll();
    }

    // ── Aktualisieren ───────────────────────────────────────────────────────

    public AccountResponse update(int id, UpdateAccountRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        account.setFirstName(request.getFirstName());
        account.setLastName(request.getLastName());
        // E-Mail bleibt unverändert – Änderung läuft über change-email Flow
        accountDao.update(account);
        return toResponse(account);
    }

    public void updatePassword(int id, UpdatePasswordRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        if (!BCrypt.checkpw(request.getOldPassword(), account.getPassword())) {
            throw new BadRequestException("Altes Passwort ist falsch");
        }
        accountDao.updatePassword(id, BCrypt.hashpw(request.getNewPassword(), BCrypt.gensalt()));
    }

    // ── Change-Email-Flow (Christof) ────────────────────────────────────────

    public void requestEmailChange(int accountId, String newEmail) {
        Account account = accountDao.getById(accountId);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        if (newEmail.equalsIgnoreCase(account.getEmail())) {
            throw new BadRequestException("Die neue E-Mail ist identisch mit der aktuellen");
        }
        if (accountDao.getByEmail(newEmail) != null) {
            throw new FieldValidationException("email", "Diese E-Mail-Adresse ist bereits vergeben");
        }
        accountDao.setPendingEmail(accountId, newEmail);
        emailVerificationService.sendVerificationCode(accountId, newEmail);
    }

    public void confirmEmailChange(int accountId, String code) {
        Account account = accountDao.getById(accountId);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        if (account.getPendingEmail() == null) {
            throw new BadRequestException("Keine ausstehende E-Mail-Änderung vorhanden");
        }
        emailVerificationService.verifyCode(account.getPendingEmail(), code);
        accountDao.confirmPendingEmail(accountId);
    }

    // ── Soft Delete ─────────────────────────────────────────────────────────

    public void delete(int id) {
        Account account = accountDao.getById(id);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        accountDao.softDelete(id);
    }

    // ── Mapper ──────────────────────────────────────────────────────────────

    private AccountResponse toResponse(Account account) {
        AccountResponse res = new AccountResponse();
        res.setId(account.getId());
        res.setFirstName(account.getFirstName());
        res.setLastName(account.getLastName());
        res.setEmail(account.getEmail());
        res.setPendingEmail(account.getPendingEmail());
        res.setBirthdate(account.getBirthdate());
        return res;
    }
}
