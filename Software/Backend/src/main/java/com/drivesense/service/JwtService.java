package com.drivesense.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;

@Service
public class JwtService {
    private final String SECRET_KEY = "drivesense-geheimer-schluessel-mindestens-32-zeichen!!";

    public String generateAccountToken(int accountId) {
        return Jwts.builder()
                .subject(String.valueOf(accountId))
                .claim("type", "ACCOUNT")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24))
                .signWith(getKey())
                .compact();
    }

    public String generateProfileToken(int accountId, int profileId, String role) {
        return Jwts.builder()
                .subject(String.valueOf(accountId))
                .claim("type", "PROFILE")
                .claim("profileId", profileId)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24))
                .signWith(getKey())
                .compact();
    }

    public String generateRefreshToken(int accountId) {
        return Jwts.builder()
                .subject(String.valueOf(accountId))
                .claim("type", "REFRESH")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 1000L * 60 * 60 * 24 * 30))
                .signWith(getKey())
                .compact();
    }

    public boolean isValid(String token) {
        try {
            getClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public int extractAccountId(String token) {
        return Integer.parseInt(getClaims(token).getSubject());
    }

    public int extractProfileId(String token) {
        return getClaims(token).get("profileId", Integer.class);
    }

    public String extractRole(String token) {
        return getClaims(token).get("role", String.class);
    }

    public String extractType(String token) {
        return getClaims(token).get("type", String.class);
    }

    private Claims getClaims(String token) {
        return Jwts.parser()
                .verifyWith(getKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey getKey() {
        return Keys.hmacShaKeyFor(SECRET_KEY.getBytes());
    }
}
