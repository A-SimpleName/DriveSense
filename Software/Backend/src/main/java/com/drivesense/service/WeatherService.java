package com.drivesense.service;

import com.drivesense.exceptions.*;
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
        WeatherData weather = fetchWeatherData(lat, lng);
        return mapToRoadCondition(weather);
    }

    private WeatherData fetchWeatherData(double lat, double lng) {
        String url = String.format(
                "https://api.open-meteo.com/v1/forecast" +
                        "?latitude=%f&longitude=%f" +
                        "&current=weather_code,precipitation,rain,showers,snowfall,temperature_2m" +
                        "&hourly=precipitation,rain,showers,snowfall,temperature_2m" +
                        "&past_hours=3" +
                        "&forecast_hours=1" +
                        "&timezone=auto",
                lat, lng
        );

        try {
            HttpClient client = HttpClient.newHttpClient();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .build();

            HttpResponse<String> response = client.send(
                    request,
                    HttpResponse.BodyHandlers.ofString()
            );

            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ExternalApiException(
                        "Wetter API Fehler: HTTP " + response.statusCode(),
                        new RuntimeException(response.body())
                );
            }

            JsonNode json = new ObjectMapper().readTree(response.body());

            JsonNode current = json.path("current");
            JsonNode hourly = json.path("hourly");

            int weatherCode = getInt(current, "weather_code", getInt(current, "weathercode", -1));
            double temperature = getDouble(current, "temperature_2m", Double.NaN);
            double currentPrecipitation = getDouble(current, "precipitation", 0.0);
            double currentSnowfall = getDouble(current, "snowfall", 0.0);

            double recentPrecipitation = sum(hourly.path("precipitation"));
            double recentSnowfall = sum(hourly.path("snowfall"));

            return new WeatherData(
                    weatherCode,
                    temperature,
                    currentPrecipitation,
                    currentSnowfall,
                    recentPrecipitation,
                    recentSnowfall
            );

        } catch (Exception e) {
            throw new ExternalApiException("Wetter API nicht erreichbar", e);
        }
    }

    private int getInt(JsonNode node, String field, int fallback) {
        JsonNode value = node.path(field);
        return value.isMissingNode() || value.isNull() ? fallback : value.asInt();
    }

    private double getDouble(JsonNode node, String field, double fallback) {
        JsonNode value = node.path(field);
        return value.isMissingNode() || value.isNull() ? fallback : value.asDouble();
    }

    private double sum(JsonNode array) {
        if (!array.isArray()) {
            return 0.0;
        }

        double result = 0.0;

        for (JsonNode value : array) {
            if (value.isNumber()) {
                result += value.asDouble();
            }
        }

        return result;
    }

    private String mapToRoadCondition(WeatherData weather) {
        int code = weather.weatherCode();

        double currentPrecipitation = weather.currentPrecipitation();
        double recentPrecipitation = weather.recentPrecipitation();
        double currentSnowfall = weather.currentSnowfall();
        double recentSnowfall = weather.recentSnowfall();
        double temperature = weather.temperature();

        boolean isFreezing = temperature <= 0.5;
        boolean hasCurrentPrecipitation = currentPrecipitation > 0.0;
        boolean hadRecentPrecipitation = recentPrecipitation > 0.2;
        boolean hasSnow = currentSnowfall > 0.0 || recentSnowfall > 0.0;

        if (code == -1) return "Unbekannt";

        if (code == 56 || code == 57 || code == 66 || code == 67) {
            return "Eisig";
        }

        if ((hasCurrentPrecipitation || hadRecentPrecipitation) && isFreezing) {
            return "Eisig";
        }

        if (hasSnow || (code >= 71 && code <= 77) || code == 85 || code == 86) {
            return "Schneebedeckt";
        }

        if (hasCurrentPrecipitation || hadRecentPrecipitation) {
            return "Nass";
        }

        if (code == 45 || code == 48) {
            return "Nebelig";
        }

        if (code >= 51 && code <= 55) {
            return "Feucht";
        }

        if (code >= 61 && code <= 65) {
            return "Nass";
        }

        if (code >= 80 && code <= 82) {
            return "Nass";
        }

        if (code >= 95 && code <= 99) {
            return "Nass";
        }

        return "Trocken";
    }
    
    private record WeatherData(
            int weatherCode,
            double temperature,
            double currentPrecipitation,
            double currentSnowfall,
            double recentPrecipitation,
            double recentSnowfall
    ) {}
}
