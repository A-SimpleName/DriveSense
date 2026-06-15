package com.drivesense.filter;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitFilter extends OncePerRequestFilter {

    // Pro IP + Endpoint ein Bucket
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return !isRateLimitedEndpoint(path);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String ip = getClientIp(request);
        String path = request.getRequestURI();
        String key = ip + ":" + path;

        Bucket bucket = buckets.computeIfAbsent(key, k -> createBucket(path));

        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(429);
            response.setContentType("application/json");
            response.getWriter().write("{\"message\": \"Zu viele Anfragen. Bitte warte kurz.\"}");
        }
    }

    // ──────────────────────────────────────────
    // BUCKET PRO ENDPOINT
    // ──────────────────────────────────────────

    private Bucket createBucket(String path) {
        Bandwidth limit;

        if (path.startsWith("/api/account/login")) {
            // 10 Versuche pro 15 Minuten
            limit = Bandwidth.classic(10, Refill.greedy(10, Duration.ofMinutes(15)));

        } else if (path.startsWith("/api/account/signUp")) {
            // 5 Versuche pro Stunde
            limit = Bandwidth.classic(5, Refill.greedy(5, Duration.ofHours(1)));

        } else if (path.startsWith("/api/account/forgot-password")) {
            // 5 Versuche pro Stunde
            limit = Bandwidth.classic(5, Refill.greedy(5, Duration.ofHours(1)));

        } else if (path.startsWith("/api/account/verify-email")) {
            // 10 Versuche pro 15 Minuten
            limit = Bandwidth.classic(10, Refill.greedy(10, Duration.ofMinutes(15)));

        } else if (path.startsWith("/api/account/resend-verification")) {
            // 3 Versuche pro 15 Minuten
            limit = Bandwidth.classic(3, Refill.greedy(3, Duration.ofMinutes(15)));

        } else if (path.startsWith("/api/account/reset-password")) {
            // 5 Versuche pro 15 Minuten
            limit = Bandwidth.classic(5, Refill.greedy(5, Duration.ofMinutes(15)));

        } else {
            // Fallback – sollte nicht vorkommen
            limit = Bandwidth.classic(20, Refill.greedy(20, Duration.ofMinutes(1)));
        }

        return Bucket.builder().addLimit(limit).build();
    }

    // ──────────────────────────────────────────
    // HILFSMETHODEN
    // ──────────────────────────────────────────

    private boolean isRateLimitedEndpoint(String path) {
        return path.startsWith("/api/account/login")
                || path.startsWith("/api/account/signUp")
                || path.startsWith("/api/account/forgot-password")
                || path.startsWith("/api/account/verify-email")
                || path.startsWith("/api/account/resend-verification")
                || path.startsWith("/api/account/reset-password");
    }

    private String getClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isEmpty()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
