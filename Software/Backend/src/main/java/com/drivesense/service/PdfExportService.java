package com.drivesense.service;


import com.drivesense.dto.response.AccountResponse;
import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.exceptions.PdfExportException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;
import org.xhtmlrenderer.pdf.ITextRenderer;


import java.io.ByteArrayOutputStream;
import java.util.Collections;
import java.util.List;

@Service
public class PdfExportService {

    private final TemplateEngine templateEngine;

    @Autowired
    public PdfExportService(TemplateEngine templateEngine) {
        this.templateEngine = templateEngine;
    }

    public byte[] generateProtocolPdf(ProtocolDto protocol, boolean isGroup) {
        try {

            // 1. Build Thymeleaf context with all data the template needs
            Context ctx = new Context();
            ctx.setVariable("protocol", protocol);
            ctx.setVariable("account", protocol.getCreated_by_account());
            ctx.setVariable("isGroup", isGroup);

            List<TripSummaryDto> trips = protocol.getTrips() != null
                    ? protocol.getTrips() : List.of();
            ctx.setVariable("trips", trips);

            int totalKm = trips.stream().mapToInt(TripSummaryDto::getDistance).sum();
            ctx.setVariable("totalKm", totalKm);

            if (isGroup) {
                String groupName = protocol.getUsergroup().getName();
                ctx.setVariable("groupName", groupName);
            }

            // Fahrschüler: always show at least 12 rows like the paper form
            if ("FAHRSCHÜLER".equalsIgnoreCase(protocol.getProtocolRole())) {
                int fillerCount = Math.max(0, 12 - trips.size());
                ctx.setVariable("fillerRows", Collections.nCopies(fillerCount, null));
            }

            // 2. Pick the right template based on role
            String template = switch (protocol.getProtocolRole().toUpperCase()) {
                case "FAHRSCHÜLER" -> "pdf/fahrschüler";
                case "BERUFSFAHRER" -> "pdf/berufsfahrer";
                default -> "pdf/privat";
            };

            // 3. Render HTML via Thymeleaf
            String html = templateEngine.process(template, ctx);

            // 4. Convert HTML → PDF via Flying Saucer
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ITextRenderer renderer = new ITextRenderer();
            renderer.setDocumentFromString(html);
            renderer.layout();
            renderer.createPDF(baos);
            String baseUrl = getClass().getResource("/static/").toURI().toString();
            renderer.setDocumentFromString(html, baseUrl);

            return baos.toByteArray();

        } catch (Exception e) {
            throw new PdfExportException("PDF konnte nicht generiert werden", e);
        }
    }
}
