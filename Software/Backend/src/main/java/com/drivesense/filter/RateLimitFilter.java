package com.drivesense.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private final Map<String, RequestWindow> requestWindows = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !isRateLimitedEndpoint(request.getRequestURI());
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String path = request.getRequestURI();
        String key = getClientIp(request) + ":" + path;
        RateLimit limit = limitFor(path);
        RequestWindow window = requestWindows.computeIfAbsent(key, ignored -> new RequestWindow());

        if (window.tryConsume(limit)) {
            chain.doFilter(request, response);
            return;
        }

        response.setStatus(429);
        response.setContentType("application/json");
        response.getWriter().write("{\"message\": \"Zu viele Anfragen. Bitte warte kurz.\"}");
    }

    private RateLimit limitFor(String path) {
        if (path.startsWith("/api/account/login")) {
            return new RateLimit(10, Duration.ofMinutes(15));
        }
        if (path.startsWith("/api/account/signUp")
                || path.startsWith("/api/account/forgot-password")) {
            return new RateLimit(5, Duration.ofHours(1));
        }
        if (path.startsWith("/api/account/verify-email")) {
            return new RateLimit(10, Duration.ofMinutes(15));
        }
        if (path.startsWith("/api/account/resend-verification")) {
            return new RateLimit(3, Duration.ofMinutes(15));
        }
        if (path.startsWith("/api/account/reset-password")) {
            return new RateLimit(5, Duration.ofMinutes(15));
        }
        return new RateLimit(20, Duration.ofMinutes(1));
    }

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

    private record RateLimit(int maxRequests, Duration window) {
    }

    private static class RequestWindow {
        private final Deque<Instant> requestTimes = new ArrayDeque<>();

        synchronized boolean tryConsume(RateLimit limit) {
            Instant now = Instant.now();
            Instant oldestAllowed = now.minus(limit.window());

            while (!requestTimes.isEmpty() && requestTimes.peekFirst().isBefore(oldestAllowed)) {
                requestTimes.removeFirst();
            }

            if (requestTimes.size() >= limit.maxRequests()) {
                return false;
            }

            requestTimes.addLast(now);
            return true;
        }
    }
}
