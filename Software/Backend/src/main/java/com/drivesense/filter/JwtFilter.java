package com.drivesense.filter;

import com.drivesense.service.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class JwtFilter extends OncePerRequestFilter {

    @Autowired
    private JwtService jwtService;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();

        return path.startsWith("/api/account/login")
                || path.startsWith("/api/account/signUp")
                || path.startsWith("/api/account/cancel-signup")
                || path.startsWith("/api/account/refresh")
                || path.startsWith("/api/account/logout")
                || path.startsWith("/api/account/verify-email")
                || path.startsWith("/api/account/resend-verification")
                || path.startsWith("/api/account/forgot-password")
                || path.startsWith("/api/account/reset-password")
                || path.startsWith("/api/vehicles/invitations/accept-link");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain
    ) throws ServletException, IOException {

        String profileToken = getCookie(request, "profileToken");
        String accountToken = getCookie(request, "accountToken");

        String token = null;
        boolean isProfile = false;

        // PRIORITY: profile > account
        if (profileToken != null && jwtService.isValid(profileToken)) {
            token = profileToken;
            isProfile = true;
        } else if (accountToken != null && jwtService.isValid(accountToken)) {
            token = accountToken;
        }

        // ❌ NO TOKEN → unauthorized
        if (token == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Kein Token vorhanden");
            return;
        }

        // extract account
        int accountId = jwtService.extractAccountId(token);
        request.setAttribute("accountId", accountId);

        // profile only if profile token
        if (isProfile) {
            request.setAttribute("profileId", jwtService.extractProfileId(token));
            request.setAttribute("role", jwtService.extractRole(token));
        }

        // security context
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(
                        accountId,
                        null,
                        Collections.emptyList()
                );

        SecurityContextHolder.getContext().setAuthentication(auth);

        chain.doFilter(request, response);
    }

    private String getCookie(HttpServletRequest request, String name) {
        if (request.getCookies() == null) return null;

        for (Cookie cookie : request.getCookies()) {
            if (cookie.getName().equals(name)) {
                return cookie.getValue();
            }
        }
        return null;
    }
}
