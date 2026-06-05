package com.drivesense.controller;

import com.drivesense.db.AccountDao;
import com.drivesense.dto.request.*;
import com.drivesense.dto.response.AccountResponse;
import com.drivesense.dto.response.LoginResponse;
import com.drivesense.dto.response.RefreshResponse;
import com.drivesense.dto.response.SelectProfileResponse;
import com.drivesense.exceptions.NotFoundException;
import com.drivesense.exceptions.UnauthorizedException;
import com.drivesense.model.Account;
import com.drivesense.service.AccountService;
import com.drivesense.service.EmailVerificationService;
import com.drivesense.service.JwtService;
import com.drivesense.service.PasswortResetService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/account")
public class AccountController {

    @Autowired private AccountService accountService;
    @Autowired private AccountDao accountDao;
    @Autowired private EmailVerificationService emailVerificationService;
    @Autowired private PasswortResetService passwordResetService;

    // ── Auth ─────────────────────────────────────────────────────────────────

    @PostMapping("/signUp")
    public ResponseEntity<AccountResponse> signUp(@Valid @RequestBody SignUpRequest request) {
        return ResponseEntity.status(201).body(accountService.signUp(request));
    }

    @PostMapping("/cancel-signup")
    public ResponseEntity<Void> cancelSignUp(@Valid @RequestBody CancelSignUpRequest request) {
        accountService.cancelSignUp(request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest request,
            @RequestHeader(value = "X-Client-Type", defaultValue = "web") String clientType,
            HttpServletResponse httpResponse) {

        LoginResponse loginResponse = accountService.login(request);

        if ("web".equals(clientType)) {
            clearCookie(httpResponse, "profileToken");
            setCookie(httpResponse, "accountToken", loginResponse.getAccountToken(), 60 * 60 * 24);
            setCookie(httpResponse, "refreshToken", loginResponse.getRefreshToken(), 60 * 60 * 24 * 30);
        }
        return ResponseEntity.ok(loginResponse);
    }

    @PostMapping("/select-profile")
    public ResponseEntity<SelectProfileResponse> selectProfile(
            @RequestParam int profileId,
            @RequestHeader(value = "X-Client-Type", defaultValue = "web") String clientType,
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            HttpServletRequest httpRequest,
            HttpServletResponse httpResponse) {

        String token = getTokenFromRequestOrHeader(httpRequest, authHeader, "accountToken");
        SelectProfileResponse res = accountService.selectProfile(profileId, token);

        if ("web".equals(clientType)) {
            setCookie(httpResponse, "profileToken", res.getProfileToken(), 60 * 60 * 24);
        }
        return ResponseEntity.ok(res);
    }

    @PostMapping("/refresh")
    public ResponseEntity<RefreshResponse> refresh(
            @RequestHeader(value = "X-Client-Type", defaultValue = "web") String clientType,
            @RequestBody(required = false) RefreshRequest request,
            HttpServletRequest httpRequest,
            HttpServletResponse httpResponse) {

        String refreshToken = "web".equals(clientType)
                ? getCookieValue(httpRequest, "refreshToken")
                : (request != null ? request.getRefreshToken() : null);

        if (refreshToken == null) throw new UnauthorizedException("Kein Refresh Token vorhanden");

        RefreshResponse res = accountService.refresh(refreshToken);
        if ("web".equals(clientType)) {
            setCookie(httpResponse, "accountToken", res.getAccountToken(), 60 * 60 * 24);
        }
        return ResponseEntity.ok(res);
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletResponse response) {
        clearCookie(response, "profileToken");
        clearCookie(response, "accountToken");
        clearCookie(response, "refreshToken");
        return ResponseEntity.ok().build();
    }

    // ── Account lesen / bearbeiten ───────────────────────────────────────────

    @GetMapping("/me")
    public ResponseEntity<AccountResponse> getCurrentAccount(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(accountService.getById(accountId));
    }

    @GetMapping
    public ResponseEntity<AccountResponse> getById(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        return ResponseEntity.ok(accountService.getById(accountId));
    }

    @PutMapping
    public ResponseEntity<AccountResponse> update(
            @Valid @RequestBody UpdateAccountRequest request,
            HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        return ResponseEntity.ok(accountService.update(accountId, request));
    }

    @PutMapping("/password")
    public ResponseEntity<Void> updatePassword(
            @Valid @RequestBody UpdatePasswordRequest request,
            HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        accountService.updatePassword(accountId, request);
        return ResponseEntity.ok().build();
    }

    // ── E-Mail-Änderungs-Flow ────────────────────────────────────────────────

    /**
     * POST /api/account/change-email
     * Schritt 1: neue E-Mail anfordern → schickt Code an neue Adresse.
     */
    @PostMapping("/change-email")
    public ResponseEntity<Void> requestEmailChange(
            @Valid @RequestBody ChangeEmailRequest request,
            HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        accountService.requestEmailChange(accountId, request.getNewEmail());
        return ResponseEntity.ok().build();
    }

    /**
     * POST /api/account/confirm-email-change
     * Schritt 2: Code eingeben → E-Mail wird übernommen.
     */
    @PostMapping("/confirm-email-change")
    public ResponseEntity<Void> confirmEmailChange(
            @Valid @RequestBody ConfirmEmailChangeRequest request,
            HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        accountService.confirmEmailChange(accountId, request.getCode());
        return ResponseEntity.ok().build();
    }

    /**
     * DELETE /api/account/change-email
     * Bricht eine laufende E-Mail-Änderung ab.
     */
    @DeleteMapping("/change-email")
    public ResponseEntity<Void> cancelEmailChange(HttpServletRequest httpRequest) {
        int accountId = (int) httpRequest.getAttribute("accountId");
        accountService.cancelEmailChange(accountId);
        return ResponseEntity.ok().build();
    }

    // ── E-Mail-Verifikation (Registrierung) ──────────────────────────────────

    @PostMapping("/verify-email")
    public ResponseEntity<Void> verifyEmail(@RequestBody @Valid VerifyEmailRequest request) {
        emailVerificationService.verifyCode(request.getEmail(), request.getCode());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<Void> resendVerification(@RequestBody @Valid ResendVerificationRequest request) {
        Account account = accountDao.getByEmail(request.getEmail());
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        emailVerificationService.sendVerificationCode(account.getId(), account.getEmail());
        return ResponseEntity.ok().build();
    }

    // ── Passwort-Reset ───────────────────────────────────────────────────────

    @PostMapping("/forgot-password")
    public ResponseEntity<Void> forgotPassword(@RequestBody @Valid ForgotPasswordRequest request) {
        passwordResetService.sendResetCode(request.getEmail());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Void> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
        passwordResetService.resetPassword(request.getEmail(), request.getCode(), request.getNewPassword());
        return ResponseEntity.ok().build();
    }

    // ── Soft Delete ──────────────────────────────────────────────────────────

    @DeleteMapping
    public ResponseEntity<Void> delete(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        accountService.delete(accountId);
        return ResponseEntity.noContent().build();
    }

    // ── Cookie-Hilfsmethoden ─────────────────────────────────────────────────

    private void setCookie(HttpServletResponse response, String name, String value, int maxAge) {
        Cookie cookie = new Cookie(name, value);
        cookie.setHttpOnly(true);
        cookie.setSecure(false);   // auf true setzen wenn HTTPS
        cookie.setPath("/");
        cookie.setMaxAge(maxAge);
        cookie.setAttribute("SameSite", "Lax");
        response.addCookie(cookie);
    }

    private void clearCookie(HttpServletResponse response, String name) {
        Cookie cookie = new Cookie(name, "");
        cookie.setMaxAge(0);
        cookie.setPath("/");
        response.addCookie(cookie);
    }

    private String getCookieValue(HttpServletRequest request, String cookieName) {
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if (cookie.getName().equals(cookieName)) return cookie.getValue();
            }
        }
        return null;
    }

    private String getTokenFromRequestOrHeader(HttpServletRequest request, String authHeader, String cookieName) {
        String token = getCookieValue(request, cookieName);
        if (token == null && authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        }
        return token;
    }
}
