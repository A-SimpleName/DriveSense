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

import java.time.LocalDate;
import java.util.List;

@Service
public class AccountService {

    @Autowired private AccountDao accountDao;
    @Autowired private ProfileDao profileDao;
    @Autowired private JwtService jwtService;
    @Autowired private EmailVerificationService emailVerificationService;
    @Autowired private EmailService emailService;

    // ── Auth ────────────────────────────────────────────────────────────────

    public AccountResponse signUp(SignUpRequest request) {
        // Inline-Feldfehler → erscheint direkt beim E-Mail-Feld im Frontend
        if (accountDao.getByEmail(request.getEmail()) != null) {
            throw new FieldValidationException("email", "Email ist bereits vergeben");
        }
        String hashedPwd = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt());
        Account account = new Account();
        account.setFirstName(request.getFirstName());
        account.setLastName(request.getLastName());
        account.setEmail(request.getEmail());
        account.setPassword(hashedPwd);
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
            throw new UnauthorizedException("Profil nicht gefunden oder kein Zugriff");
        }
        SelectProfileResponse res = new SelectProfileResponse();
        res.setProfileToken(jwtService.generateProfileToken(accountId,profileId,profile.getRole()));
        res.setProfile(profile);
        return res;
    }

    public RefreshResponse refresh(String refreshToken) {
        if (!jwtService.isValid(refreshToken) || !jwtService.extractType(refreshToken).equals("REFRESH")) {
            throw new UnauthorizedException("Ungültiger Refresh Token");
        }
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
        accountDao.update(account);

        return toResponse(account);
    }

    public void updatePassword(int id, UpdatePasswordRequest request) {
        Account account = accountDao.getById(id);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        if (!BCrypt.checkpw(request.getOldPassword(), account.getPassword())) {
            throw new BadRequestException("Altes Passwort ist falsch");
        }
        if (BCrypt.checkpw(request.getNewPassword(), account.getPassword())) {
            throw new BadRequestException("Neues Passwort darf nicht gleich wie das alte sein");
        }
        accountDao.updatePassword(id, BCrypt.hashpw(request.getNewPassword(), BCrypt.gensalt()));
    }

    // ── Change-Email-Flow ───────────────────────────────────────────────────

    /**
     * Schritt 1: User gibt neue E-Mail an.
     * Prüft auf Duplikate (primary + pending), setzt pending_email und
     * schickt einen Verifikations-Code an die neue Adresse.
     */
    public void requestEmailChange(int accountId, String newEmail) {
        Account account = accountDao.getById(accountId);
        if (account == null) throw new NotFoundException("Account nicht gefunden");

        // Neue E-Mail darf nicht identisch mit der aktuellen sein
        if (newEmail.equalsIgnoreCase(account.getEmail())) {
            throw new BadRequestException("Die neue E-Mail ist identisch mit der aktuellen");
        }

        // Prüfen ob bereits ein anderer aktiver Account diese E-Mail als primäre Adresse hat
        if (accountDao.getByEmail(newEmail) != null) {
            throw new BadRequestException("Diese E-Mail-Adresse ist bereits vergeben");
        }

        // Prüfen ob die E-Mail schon als pending_email bei einem anderen Account liegt
        if (accountDao.existsByPendingEmail(newEmail, accountId)) {
            throw new BadRequestException("Diese E-Mail-Adresse wird bereits von einem anderen Account beansprucht");
        }

        // pending_email setzen (DB-seitig UNIQUE → kein Race-Condition-Problem)
        accountDao.setPendingEmail(accountId, newEmail);

        try {
            // Verifikations-Code an neue Adresse senden
            emailVerificationService.sendVerificationCode(accountId, newEmail);
        } catch (ExternalApiException e) {
            accountDao.clearPendingEmail(accountId);
            throw e;
        }
    }

    /**
     * Schritt 2: User gibt den Code ein, der an die neue E-Mail gesendet wurde.
     * Nach erfolgreicher Verifikation: email = pending_email, pending_email = NULL.
     */
    public void confirmEmailChange(int accountId, String code) {
        Account account = accountDao.getById(accountId);
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        if (account.getPendingEmail() == null) {
            throw new BadRequestException("Keine ausstehende E-Mail-Änderung vorhanden");
        }

        emailVerificationService.confirmEmailChange(accountId, code);
    }

    /**
     * Bricht eine laufende E-Mail-Änderung ab.
     */
    public void cancelEmailChange(int accountId) {
        accountDao.clearPendingEmail(accountId);
    }

    // ── Soft Delete ─────────────────────────────────────────────────────────

    /**
     * Soft-löscht den Account. Historische Trips, Protocols und Vehicles
     * bleiben durch RESTRICT / SET NULL auf den FK erhalten.
     */
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
