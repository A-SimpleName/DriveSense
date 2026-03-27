package com.drivesense.filter;

import com.drivesense.service.JwtService;
import jakarta.servlet.http.Cookie;
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

        String path = request.getRequestURI();

        if (path.contains("/login") ||
                path.contains("/register") ||
                path.contains("/refresh")) {
            chain.doFilter(request, response);
            return;
        }

        // ← Token aus Cookie ODER Header lesen
        String token = null;

        // zuerst Cookie prüfen (Web)
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if (cookie.getName().equals("profileToken")) {
                    token = cookie.getValue();
                }
            }
        }

        // dann Header prüfen (Flutter)
        if (token == null) {
            String authHeader = request.getHeader("Authorization");
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                token = authHeader.substring(7);
            }
        }

        // kein Token → 401
        if (token == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Kein Token vorhanden");
            return;
        }

        // Token ungültig → 401
        if (!jwtService.isValid(token)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Token ungültig oder abgelaufen");
            return;
        }

        String type = jwtService.extractType(token);

        if (type.equals("ACCOUNT") && !path.contains("select-profile")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Bitte zuerst Profil auswählen");
            return;
        }

        if (type.equals("REFRESH")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Ungültiger Token Typ");
            return;
        }

        if (path.startsWith("/api/admin")) {
            String role = jwtService.extractRole(token);
            if (!role.equals("ADMIN")) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().write("Kein Zugriff");
                return;
            }
        }

        request.setAttribute("accountId", jwtService.extractAccountId(token));
        if (type.equals("PROFILE")) {
            request.setAttribute("profileId", jwtService.extractProfileId(token));
            request.setAttribute("role", jwtService.extractRole(token));
        }

        chain.doFilter(request, response);
    }
}
