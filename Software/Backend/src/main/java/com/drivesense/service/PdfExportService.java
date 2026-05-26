package com.drivesense.service;

import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.exceptions.PdfExportException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.xhtmlrenderer.pdf.ITextRenderer;

import java.io.ByteArrayOutputStream;
import java.text.Normalizer;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.stream.IntStream;

@Service
public class PdfExportService {

    private final TemplateEngine templateEngine;

    @Autowired
    public PdfExportService(TemplateEngine templateEngine) {
        this.templateEngine = templateEngine;
    }

    public byte[] generateProtocolPdf(ProtocolDto protocol, boolean isGroup) {
        try {
            Context ctx = new Context();
            ctx.setVariable("protocol", protocol);
            ctx.setVariable("account", protocol.getCreated_by_account());
            ctx.setVariable("isGroup", isGroup);
            ctx.setVariable("pdf", new PdfTemplateHelper());

            List<TripSummaryDto> trips = protocol.getTrips() != null
                    ? protocol.getTrips()
                    : List.of();
            ctx.setVariable("trips", trips);

            double totalKm = trips.stream()
                    .mapToDouble(TripSummaryDto::getDistance)
                    .sum();
            ctx.setVariable("totalKm", totalKm);

            if (isGroup) {
                String groupName = protocol.getUsergroup().getName();
                ctx.setVariable("groupName", groupName);
            }

            PdfLayout layout = PdfLayout.fromRole(protocol.getProtocolRole());
            ctx.setVariable(
                    "fillerRows",
                    createFillerRows(trips.size(), layout.rowsPerPage()));

            String html = templateEngine.process(layout.templateName(), ctx);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ITextRenderer renderer = new ITextRenderer();
            String baseUrl = getClass().getResource("/static/").toURI().toString();
            renderer.setDocumentFromString(html, baseUrl);
            renderer.layout();
            renderer.createPDF(baos);

            return baos.toByteArray();

        } catch (Exception e) {
            throw new PdfExportException("PDF konnte nicht generiert werden", e);
        }
    }

    public static class PdfTemplateHelper {

        public String text(String value) {
            return value == null || value.trim().isEmpty()
                    ? ""
                    : value.trim();
        }

        public String name(String firstName, String lastName) {
            return List.of(text(firstName), text(lastName)).stream()
                    .filter(value -> !value.isEmpty())
                    .reduce((left, right) -> left + " " + right)
                    .orElse("");
        }

        public String date(LocalDate value, String pattern) {
            return value == null
                    ? ""
                    : value.format(DateTimeFormatter.ofPattern(pattern));
        }

        public String dateTime(LocalDateTime value, String pattern) {
            return value == null
                    ? ""
                    : value.format(DateTimeFormatter.ofPattern(pattern));
        }

        public String distance(double value) {
            return value + " km";
        }

        public String route(String startPoint, String furthestPoint, String endPoint) {
            return List.of(text(startPoint), text(furthestPoint), text(endPoint)).stream()
                    .filter(value -> !value.isEmpty())
                    .reduce((left, right) -> left + " \u2192 " + right)
                    .orElse("");
        }
    }

    private List<Integer> createFillerRows(int tripCount, int rowsPerPage) {
        int rowsOnLastPage = tripCount % rowsPerPage;
        int fillerCount = rowsOnLastPage == 0 && tripCount > 0
                ? 0
                : rowsPerPage - rowsOnLastPage;

        return IntStream.range(0, fillerCount).boxed().toList();
    }

    private enum PdfLayout {
        PRIVAT("pdf/privat", 32),
        BERUFSFAHRER("pdf/berufsfahrer", 30),
        FAHRSCHUELER("pdf/fahrsch\u00fcler", 28);

        private final String templateName;
        private final int rowsPerPage;

        PdfLayout(String templateName, int rowsPerPage) {
            this.templateName = templateName;
            this.rowsPerPage = rowsPerPage;
        }

        String templateName() {
            return templateName;
        }

        int rowsPerPage() {
            return rowsPerPage;
        }

        static PdfLayout fromRole(String role) {
            String normalizedRole = role == null
                    ? ""
                    : Normalizer.normalize(
                            role.replace("\u00df", "SS"),
                            Normalizer.Form.NFD)
                    .replaceAll("\\p{M}", "")
                    .toUpperCase(Locale.ROOT);

            return switch (normalizedRole) {
                case "FAHRSCHULER", "FAHRSCHUELER" -> FAHRSCHUELER;
                case "BERUFSFAHRER" -> BERUFSFAHRER;
                default -> PRIVAT;
            };
        }
    }
}
