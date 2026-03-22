package com.drivesense.service;

import com.drivesense.exceptions.ExternalApiException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Service
public class WeatherService {
    public String getRoadSurfaceCondition(double lat, double lng) {
        int weatherCode = fetchWeatherCode(lat, lng);
        return mapToRoadCondition(weatherCode);
    }

    private int fetchWeatherCode(double lat, double lng) {
        String url = String.format(
                "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=weathercode",
                lat, lng
        );

        try {
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .build();

            HttpResponse<String> response = client.send(request,
                    HttpResponse.BodyHandlers.ofString());

            ObjectMapper mapper = new ObjectMapper();
            JsonNode json = mapper.readTree(response.body());
            return json.get("current").get("weathercode").asInt();

        } catch (Exception e) {
            throw new ExternalApiException("Wetter API nicht erreichbar", e);
        }
    }

    private String mapToRoadCondition(int code) {
        if (code == -1) return "Unbekannt";
        if (code <= 3)  return "Trocken";
        if (code == 45 || code == 48) return "Nebelig";
        if (code >= 51 && code <= 55) return "Feucht";
        if (code == 56 || code == 57) return "Eisig";
        if (code >= 61 && code <= 65) return "Nass";
        if (code == 66 || code == 67) return "Eisig";
        if (code >= 71 && code <= 77) return "Schneebedeckt";
        if (code >= 80 && code <= 82) return "Nass";
        if (code == 85 || code == 86) return "Schneebedeckt";
        if (code >= 95 && code <= 99) return "Nass";
        return "Trocken";
    }
}
