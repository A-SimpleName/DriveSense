package com.drivesense.filter;

import com.drivesense.service.JwtService;
import org.springframework.beans.factory.annotation.Autowired;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {
    @Autowired
    private JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");
        String path = request.getRequestURI();

        // Login, Register, Refresh brauchen keinen Token
        if (path.contains("/login") ||
                path.contains("/register") ||
                path.contains("/refresh")) {
            chain.doFilter(request, response);
            return;
        }

        // kein Token → 401
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Kein Token vorhanden");
            return;
        }

        String token = authHeader.substring(7);

        // Token ungültig → 401
        if (!jwtService.isValid(token)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Token ungültig oder abgelaufen");
            return;
        }

        String type = jwtService.extractType(token);

        // accountToken darf nur select-profile aufrufen
        if (type.equals("ACCOUNT") && !path.contains("select-profile")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Bitte zuerst Profil auswählen");
            return;
        }

        // refreshToken darf gar nichts außer /refresh
        if (type.equals("REFRESH")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Ungültiger Token Typ");
            return;
        }

        // Daten in Request legen
        request.setAttribute("accountId", jwtService.extractAccountId(token));
        if (type.equals("PROFILE")) {
            request.setAttribute("profileId", jwtService.extractProfileId(token));
            request.setAttribute("role", jwtService.extractRole(token));
        }

        chain.doFilter(request, response);
    }
}
