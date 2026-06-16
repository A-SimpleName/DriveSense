package com.drivesense.controller;

import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.service.PdfExportService;
import com.drivesense.service.ProtocolService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/export")
public class ExportController {

    private final PdfExportService pdfExportService;
    private final ProtocolService  protocolService;

    public ExportController(PdfExportService pdfExportService,
                            ProtocolService protocolService) {
        this.pdfExportService = pdfExportService;
        this.protocolService  = protocolService;
    }

    @GetMapping("{protocolId}")
    public ResponseEntity<byte[]> exportPdf(
            @PathVariable int protocolId) {

        ProtocolDto protocol = protocolService.getProtocolWithTrips(protocolId);
        boolean isGroup = protocol.getUsergroup() != null
                && protocol.getUsergroup().getId() > 0;

        byte[] pdf = pdfExportService.generateProtocolPdf(
                protocol, isGroup);

        String filename = protocol.getName();

        return buildResponse(pdf, filename);
    }

    private ResponseEntity<byte[]> buildResponse(byte[] pdf, String filename) {
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + filename + "\"")
                .body(pdf);
    }
}
