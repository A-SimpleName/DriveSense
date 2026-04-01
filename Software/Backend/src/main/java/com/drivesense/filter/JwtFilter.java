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
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String path = request.getRequestURI();

        // Public Routes
        if (path.contains("/login") || path.contains("/signUp") || path.contains("/refresh")) {
            chain.doFilter(request, response);
            return;
        }

        // Tokens lesen
        String profileToken = getCookie(request, "profileToken");
        String accountToken = getCookie(request, "accountToken");

        String token = null;
        boolean isProfile = false;

        // Priorität: PROFILE > ACCOUNT
        if (profileToken != null && jwtService.isValid(profileToken)) {
            token = profileToken;
            isProfile = true;
        } else if (accountToken != null && jwtService.isValid(accountToken)) {
            token = accountToken;
        }

        // Kein gültiger Token
        if (token == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Kein Token vorhanden");
            return;
        }

        // Account ID IMMER setzen
        int accountId = jwtService.extractAccountId(token);
        request.setAttribute("accountId", accountId);

        // Profil nur wenn Profile Token
        if (isProfile) {
            request.setAttribute("profileId", jwtService.extractProfileId(token));
            request.setAttribute("role", jwtService.extractRole(token));
        }

        // SecurityContext setzen
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
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if (cookie.getName().equals(name)) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }
}