package com.drivesense.service;

import com.drivesense.exceptions.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Service
public class GeocodingService {

    // API Key
    @Value("${google.api.key}")
    private String apiKey;

    @Autowired
    public GeocodingService() {}

    public String getCity(double lat, double lng) {
        // URL für Google Geocoding API
        String url = String.format(
                "https://maps.googleapis.com/maps/api/geocode/json?latlng=%s,%s&key=%s",
                lat, lng, apiKey
        );

        try {
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .build();

            HttpResponse<String> response = client.send(request,
                    HttpResponse.BodyHandlers.ofString());

            // JSON parsen
            ObjectMapper mapper = new ObjectMapper();
            JsonNode json = mapper.readTree(response.body());

            if (!json.get("status").asText().equals("OK")) {
                System.err.println("Google Geocoding Fehler: " + json.get("status").asText());
                return "Unbekannt";
            }

            // Durch die Ergebnisse iterieren
            for (JsonNode result : json.get("results")) {
                for (JsonNode component : result.get("address_components")) {
                    JsonNode types = component.get("types");
                    for (JsonNode type : types) {
                        String typeStr = type.asText();
                        if ("locality".equals(typeStr)) {       // Stadt
                            return component.get("long_name").asText();
                        }
                        if ("administrative_area_level_2".equals(typeStr)) { // Landkreis / Kreis
                            return component.get("long_name").asText();
                        }
                    }
                }
            }

            return "Unbekannt";

        } catch (Exception e) {
            throw new ExternalApiException("Geocoding API nicht erreichbar", e);
        }
    }
}