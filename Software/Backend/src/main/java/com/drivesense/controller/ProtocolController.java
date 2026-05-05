package com.drivesense.controller;

import com.drivesense.dto.request.ProtocolCreateRequest;
import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.model.Protocol;
import com.drivesense.service.ProtocolService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.parameters.P;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/protocols")
public class ProtocolController {
    @Autowired
    private ProtocolService protocolService;

    // GET /api/protocols
    @GetMapping("/admin/all")
    public ResponseEntity<List<Protocol>> getAll() {
        return ResponseEntity.ok(protocolService.getAll());
    }

    // GET /api/protocols/1
    @GetMapping("/{id}")
    public ResponseEntity<Protocol> getById(@PathVariable int id) {
        return ResponseEntity.ok(protocolService.getById(id));
    }

    @GetMapping("/{id}/with-trips")
    public ResponseEntity<ProtocolDto> getProtocolWithTrips(@PathVariable int id) {
        return ResponseEntity.ok(protocolService.getProtocolWithTrips(id));
    }

    // GET /api/protocols/profile/1
    @GetMapping("/profile/{createdByProfileId}")
    public ResponseEntity<List<Protocol>> getByProfileId(@PathVariable int createdByProfileId) {
        return ResponseEntity.ok(protocolService.getByProfileId(createdByProfileId));
    }

    // GET /api/protocols/group/1
    @GetMapping("/group/{groupId}")
    public ResponseEntity<List<Protocol>> getByGroup(@PathVariable int groupId) {
        return ResponseEntity.ok(protocolService.getByGroup(groupId));
    }

    @GetMapping
    public ResponseEntity<List<Protocol>> getAllByProfileId (HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(protocolService.getAllByProfileId(profileId));
    }

    // POST /api/protocols
    @PostMapping
    public ResponseEntity<Protocol> insert(
            @Valid @RequestBody ProtocolCreateRequest requestBody,
            HttpServletRequest request
    ) {
        int profileId = (int) request.getAttribute("profileId");
        Protocol protocol = protocolService.insert(requestBody.getName(), profileId);

        return ResponseEntity.status(201).body(protocol);
    }

    // PUT /api/protocols/1
    @PutMapping("/{id}")
    public ResponseEntity<Void> update(@PathVariable int id, @Valid @RequestBody Protocol protocol) {
        protocol.setId(id);
        protocolService.update(protocol);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        protocolService.delete(id,profileId);
        return ResponseEntity.noContent().build();
    }
}