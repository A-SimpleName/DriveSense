package com.drivesense.service;

import com.drivesense.exceptions.ExternalApiException;
import com.drivesense.model.Trackingpoint;
import com.drivesense.model.TripSummary;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class RoadSnapService {
    private static final int MAX_POINTS_PER_REQUEST = 100;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${google.api.key}")
    private String apiKey;

    public List<Trackingpoint> snap(TripSummary tripSummary, List<Trackingpoint> rawPoints) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new ExternalApiException("Google Roads API Key fehlt", new IllegalStateException("google.api.key is blank"));
        }
        if (rawPoints == null || rawPoints.size() < 2) {
            throw new ExternalApiException("Mindestens zwei Trackingpoints fuer Road Snap erforderlich", new IllegalArgumentException());
        }

        List<LatLng> snappedCoordinates = new ArrayList<>();

        for (int start = 0; start < rawPoints.size(); start += MAX_POINTS_PER_REQUEST - 1) {
            int end = Math.min(start + MAX_POINTS_PER_REQUEST, rawPoints.size());
            List<Trackingpoint> batch = rawPoints.subList(start, end);
            if (batch.size() < 2) {
                break;
            }

            List<LatLng> batchCoordinates = snapBatch(batch);
            if (batchCoordinates.isEmpty()) {
                throw new ExternalApiException("Google Roads API lieferte keine Snap-Punkte", new IllegalStateException());
            }

            if (!snappedCoordinates.isEmpty() && samePosition(snappedCoordinates.get(snappedCoordinates.size() - 1), batchCoordinates.get(0))) {
                snappedCoordinates.addAll(batchCoordinates.subList(1, batchCoordinates.size()));
            } else {
                snappedCoordinates.addAll(batchCoordinates);
            }

            if (end == rawPoints.size()) {
                break;
            }
        }

        if (snappedCoordinates.size() < 2) {
            throw new ExternalApiException("Google Roads API lieferte zu wenige Snap-Punkte", new IllegalStateException());
        }

        return toTrackingpoints(tripSummary.getId(), rawPoints, snappedCoordinates);
    }

    private List<LatLng> snapBatch(List<Trackingpoint> points) {
        String path = points.stream()
                .map(point -> point.getLat() + "," + point.getLng())
                .reduce((left, right) -> left + "|" + right)
                .orElse("");

        String url = "https://roads.googleapis.com/v1/snapToRoads"
                + "?path=" + encode(path)
                + "&interpolate=true"
                + "&key=" + encode(apiKey);

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(10))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ExternalApiException("Google Roads API Fehler: HTTP " + response.statusCode(), new RuntimeException(response.body()));
            }

            JsonNode json = objectMapper.readTree(response.body());
            JsonNode snappedPoints = json.path("snappedPoints");
            if (!snappedPoints.isArray()) {
                return List.of();
            }

            List<LatLng> result = new ArrayList<>();
            for (JsonNode snappedPoint : snappedPoints) {
                JsonNode location = snappedPoint.path("location");
                if (location.hasNonNull("latitude") && location.hasNonNull("longitude")) {
                    result.add(new LatLng(location.get("latitude").asDouble(), location.get("longitude").asDouble()));
                }
            }
            return result;
        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            throw new ExternalApiException("Google Roads API nicht erreichbar", e);
        }
    }

    private List<Trackingpoint> toTrackingpoints(int tripId, List<Trackingpoint> rawPoints, List<LatLng> snappedCoordinates) {
        LocalDateTime startTime = rawPoints.get(0).getTimestamp();
        LocalDateTime endTime = rawPoints.get(rawPoints.size() - 1).getTimestamp();
        long durationSeconds = startTime != null && endTime != null
                ? Math.max(0, Duration.between(startTime, endTime).getSeconds())
                : 0;

        List<Trackingpoint> result = new ArrayList<>();
        for (int i = 0; i < snappedCoordinates.size(); i++) {
            LatLng coordinate = snappedCoordinates.get(i);
            Trackingpoint point = new Trackingpoint();
            point.setTripId(tripId);
            point.setLat(coordinate.lat());
            point.setLng(coordinate.lng());
            point.setAccuracy(0);
            point.setSpeed(0);
            point.setBearing(0);
            point.setTimestamp(estimatedTimestamp(startTime, durationSeconds, i, snappedCoordinates.size()));
            point.setPointSource("SNAPPED");
            result.add(point);
        }
        return result;
    }

    private LocalDateTime estimatedTimestamp(LocalDateTime startTime, long durationSeconds, int index, int total) {
        LocalDateTime base = startTime != null ? startTime : LocalDateTime.now();
        if (total <= 1 || durationSeconds <= 0) {
            return base.plusSeconds(index);
        }
        long offsetSeconds = Math.round((durationSeconds * index) / (double) (total - 1));
        return base.plusSeconds(offsetSeconds);
    }

    private boolean samePosition(LatLng left, LatLng right) {
        return Math.abs(left.lat() - right.lat()) < 0.000001
                && Math.abs(left.lng() - right.lng()) < 0.000001;
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private record LatLng(double lat, double lng) {}
}
