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
    @Autowired
    private AccountService accountService;
    @Autowired
    private AccountDao accountDao;
    @Autowired
    private EmailVerificationService emailVerificationService;
    @Autowired
    private PasswortResetService passwordResetService;

    @PostMapping("/signUp")
    public ResponseEntity<AccountResponse> signUp(@Valid @RequestBody SignUpRequest request) {
        AccountResponse account = accountService.signUp(request);
        return ResponseEntity.status(201).body(account);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest request,
            @RequestHeader(value = "X-Client-Type", defaultValue = "web") String clientType,
            HttpServletResponse httpResponse) {

        LoginResponse loginResponse = accountService.login(request);

        if (clientType.equals("web")) {
            // Beim Account-Login darf kein altes Profil aktiv bleiben.
            Cookie profileCookie = new Cookie("profileToken", "");
            profileCookie.setHttpOnly(true);
            profileCookie.setSecure(false);
            profileCookie.setPath("/");
            profileCookie.setMaxAge(0);
            profileCookie.setAttribute("SameSite", "Lax");
            httpResponse.addCookie(profileCookie);

            // accountToken als Cookie
            Cookie accountCookie = new Cookie("accountToken", loginResponse.getAccountToken());
            accountCookie.setHttpOnly(true);
            accountCookie.setSecure(false);
            accountCookie.setPath("/");
            accountCookie.setMaxAge(60 * 60 * 24); // 24h
            accountCookie.setAttribute("SameSite", "Lax");
            httpResponse.addCookie(accountCookie);

            // refreshToken als Cookie
            Cookie refreshCookie = new Cookie("refreshToken", loginResponse.getRefreshToken());
            refreshCookie.setHttpOnly(true);
            refreshCookie.setSecure(false);
            refreshCookie.setPath("/");
            refreshCookie.setMaxAge(60 * 60 * 24 * 30); // 30 Tage
            refreshCookie.setAttribute("SameSite", "Lax");
            httpResponse.addCookie(refreshCookie);
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

        // Token aus Cookie oder Header holen
        String token = getTokenFromRequestOrHeader(httpRequest, authHeader, "accountToken");

        SelectProfileResponse res = accountService.selectProfile(profileId, token);

        if (clientType.equals("web")) {
            // profileToken als Cookie setzen
            Cookie profileCookie = new Cookie("profileToken", res.getProfileToken());
            profileCookie.setHttpOnly(true);
            profileCookie.setSecure(false);
            profileCookie.setPath("/");
            profileCookie.setMaxAge(60 * 60 * 24); // 24h
            profileCookie.setAttribute("SameSite", "Lax");
            httpResponse.addCookie(profileCookie);
        }

        return ResponseEntity.ok(res);
    }

    @PostMapping("/refresh")
    public ResponseEntity<RefreshResponse> refresh(
            @RequestHeader(value = "X-Client-Type", defaultValue = "web") String clientType,
            @RequestBody(required = false) RefreshRequest request,
            HttpServletRequest httpRequest,
            HttpServletResponse httpResponse) {

        // Token aus Cookie oder Body holen
        String refreshToken = null;

        if (clientType.equals("web")) {
            refreshToken = getCookieValue(httpRequest, "refreshToken");
        } else if (request != null) {
            refreshToken = request.getRefreshToken();
        }

        if (refreshToken == null) {
            throw new UnauthorizedException("Kein Refresh Token vorhanden");
        }

        RefreshResponse res = accountService.refresh(refreshToken);

        if (clientType.equals("web")) {
            Cookie accountCookie = new Cookie("accountToken", res.getAccountToken());
            accountCookie.setHttpOnly(true);
            accountCookie.setSecure(false);
            accountCookie.setPath("/");
            accountCookie.setMaxAge(60 * 60 * 24);
            accountCookie.setAttribute("SameSite", "Lax");
            httpResponse.addCookie(accountCookie);
        }

        return ResponseEntity.ok(res);
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletResponse response) {
        // Cookies löschen
        Cookie profileCookie = new Cookie("profileToken", "");
        profileCookie.setMaxAge(0); // sofort löschen
        profileCookie.setPath("/");
        response.addCookie(profileCookie);

        Cookie accountCookie = new Cookie("accountToken", "");
        accountCookie.setMaxAge(0);
        accountCookie.setPath("/");
        response.addCookie(accountCookie);

        Cookie refreshCookie = new Cookie("refreshToken", "");
        refreshCookie.setMaxAge(0);
        refreshCookie.setPath("/");
        response.addCookie(refreshCookie);

        return ResponseEntity.ok().build();
    }

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

    @PostMapping("/verify-email")
    public ResponseEntity<Void> verifyEmail(
            @RequestBody @Valid VerifyEmailRequest request) {

        emailVerificationService.verifyCode(request.getEmail(), request.getCode());
        return ResponseEntity.ok().build();
    }

    // Falls User neuen Code anfordert
    @PostMapping("/resend-verification")
    public ResponseEntity<Void> resendVerification(
            @RequestBody @Valid ResendVerificationRequest request) {
        Account account = accountDao.getByEmail(request.getEmail());
        if (account == null) throw new NotFoundException("Account nicht gefunden");
        emailVerificationService.sendVerificationCode(account.getId(), account.getEmail());
        return ResponseEntity.ok().build();
    }

    // Schritt 1 – Code anfordern
    @PostMapping("/forgot-password")
    public ResponseEntity<Void> forgotPassword(
            @RequestBody @Valid ForgotPasswordRequest request) {
        passwordResetService.sendResetCode(request.getEmail());
        return ResponseEntity.ok().build();
    }

    // Schritt 2 – Code + neues Passwort
    @PostMapping("/reset-password")
    public ResponseEntity<Void> resetPassword(
            @RequestBody @Valid ResetPasswordRequest request) {
        passwordResetService.resetPassword(
                request.getEmail(),
                request.getCode(),
                request.getNewPassword()
        );
        return ResponseEntity.ok().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> delete(HttpServletRequest request) {
        int accountId = (int) request.getAttribute("accountId");
        accountService.delete(accountId);
        return ResponseEntity.noContent().build();
    }


    private String getCookieValue(HttpServletRequest request, String cookieName) {
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if (cookie.getName().equals(cookieName)) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }

    private String getTokenFromRequestOrHeader(HttpServletRequest request,
                                               String authHeader,
                                               String cookieName) {
        String token = getCookieValue(request, cookieName);
        if (token == null && authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        }
        return token;
    }
}
