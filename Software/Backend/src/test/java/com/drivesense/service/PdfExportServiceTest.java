package com.drivesense.service;

import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.dto.response.TripSummaryDto;
import org.junit.jupiter.api.Test;
import org.thymeleaf.spring6.SpringTemplateEngine;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;

class PdfExportServiceTest {

    @Test
    void generatesPdfForEmptyProtocols() {
        PdfExportService service = new PdfExportService(templateEngine());

        for (String role : List.of("PRIVAT", "BERUFSFAHRER", "FAHRSCHUELER")) {
            byte[] pdf = service.generateProtocolPdf(protocol(role), false);
            assertTrue(pdf.length > 0, "PDF should not be empty for " + role);
        }
    }

    @Test
    void pdfTemplatesUseCurrentAccountNameProperties() throws IOException {
        Path templateDir = Path.of("src", "main", "resources", "templates", "pdf");
        try (var templates = Files.list(templateDir)) {
            for (Path template : templates.filter(path -> path.toString().endsWith(".html")).toList()) {
                String html = Files.readString(template, StandardCharsets.UTF_8);
                assertTrue(!html.contains("account.fName"), template + " must not use account.fName");
                assertTrue(!html.contains("account.lName"), template + " must not use account.lName");
                assertTrue(!html.contains("account.fname"), template + " must not use account.fname");
                assertTrue(!html.contains("account.lname"), template + " must not use account.lname");
                assertTrue(html.contains("account.firstName") || html.contains("trip.accountFirstName"),
                        template + " should use firstName fields");
                assertTrue(html.contains("account.lastName") || html.contains("trip.accountLastName"),
                        template + " should use lastName fields");
            }
        }
    }

    private SpringTemplateEngine templateEngine() {
        ClassLoaderTemplateResolver resolver = new ClassLoaderTemplateResolver();
        resolver.setPrefix("templates/");
        resolver.setSuffix(".html");
        resolver.setCharacterEncoding("UTF-8");

        SpringTemplateEngine engine = new SpringTemplateEngine();
        engine.setTemplateResolver(resolver);
        return engine;
    }

    private ProtocolDto protocol(String role) {
        ProtocolDto protocol = new ProtocolDto();
        protocol.setId(1);
        protocol.setName(role + " Test");
        protocol.setProtocolRole(role);
        protocol.setCreated_at(LocalDateTime.now());
        protocol.setTrips(List.of(trip()));
        return protocol;
    }

    private TripSummaryDto trip() {
        TripSummaryDto trip = new TripSummaryDto();
        trip.setId(1);
        trip.setProfileId(1);
        trip.setVehicleId(1);
        trip.setProtocolId(1);
        trip.setStartTime(LocalDateTime.now().minusHours(1));
        trip.setEndTime(LocalDateTime.now());
        trip.setStartMileage(100);
        trip.setEndMileage(130);
        trip.setDistance(30);
        trip.setLicensePlate("PE-DS-1");
        trip.setVehicleModel("Test Car");
        trip.setStartPoint("Perg");
        trip.setFurthestPoint("Linz");
        trip.setEndPoint("Perg");
        trip.setRoadSurfaceConditions("Trocken");
        trip.setType("Privat");
        trip.setAccountFirstName("Max");
        trip.setAccountLastName("Mustermann");
        return trip;
    }
}
