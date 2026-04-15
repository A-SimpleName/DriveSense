package com.drivesense.controller;

import com.drivesense.dto.response.AccountResponse;
import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.model.Account;
import com.drivesense.model.Profile;
import com.drivesense.service.AccountService;
import com.drivesense.service.PdfExportService;
import com.drivesense.service.ProfileService;
import com.drivesense.service.ProtocolService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/export")
public class ExportController {

    private final PdfExportService pdfExportService;
    private final ProtocolService  protocolService;
    private final ProfileService   profileService;
    private final AccountService   accountService;

    public ExportController(PdfExportService pdfExportService,
                            ProtocolService protocolService,
                            ProfileService profileService,
                            AccountService accountService) {
        this.pdfExportService = pdfExportService;
        this.protocolService  = protocolService;
        this.profileService   = profileService;
        this.accountService   = accountService;
    }

    /**
     * Einzelprotokoll – Fahrten die der User alleine aufgezeichnet hat.
     * GET /api/export/single/{protocolId}?profileId=1
     */
    @GetMapping("{protocolId}")
    public ResponseEntity<byte[]> exportPdf(
            @PathVariable int protocolId,
            HttpServletRequest request) throws Exception {

        int profileId = (int) request.getAttribute("profileId");
        ProtocolDto protocol = protocolService.getProtocolWithTrips(protocolId);
        Profile profile      = profileService.getById(profileId);
        AccountResponse account      = accountService.getById(profile.getAccount_id());
        boolean isGroup = false;

        if (protocol.getUsergroup_id() > 0) {
            isGroup = true;
        }

        byte[] pdf = pdfExportService.generateProtocolPdf(
                protocol, account, profile.getRole(), isGroup);

        String filename = isGroup
                ? "gruppenprotokoll_" + protocolId + ".pdf"
                : "einzelprotokoll_"  + protocolId + ".pdf";

        return buildResponse(pdf, filename + protocolId + ".pdf");
    }

    private ResponseEntity<byte[]> buildResponse(byte[] pdf, String filename) {
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + filename + "\"")
                .body(pdf);
    }
}
