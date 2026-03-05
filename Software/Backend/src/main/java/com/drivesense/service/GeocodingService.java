package com.drivesense.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class GeocodingService {
    public String getCity(double lat, double lng) {
        String url = String.format(
                "https://nominatim.openstreetmap.org/reverse?lat=%s&lon=%s&format=json",
                lat, lng
        );

        try {
            HttpClient client = HttpClient.newHttpClient();
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("User-Agent", "DriveSense/1.0") // Nominatim braucht das!
                    .GET()
                    .build();

            HttpResponse<String> response = client.send(request,
                    HttpResponse.BodyHandlers.ofString());

            // JSON parsen
            ObjectMapper mapper = new ObjectMapper();
            JsonNode json = mapper.readTree(response.body());

            // Stadt aus der Antwort holen
            JsonNode address = json.get("address");
            if (address.has("city"))        return address.get("city").asText();
            if (address.has("town"))        return address.get("town").asText();
            if (address.has("village"))     return address.get("village").asText();
            if (address.has("suburb"))      return address.get("suburb").asText();

            return "Unbekannt";

        } catch (Exception e) {
            System.err.println("Geocoding Fehler: " + e.getMessage());
            return "Unbekannt";
        }
    }
}
