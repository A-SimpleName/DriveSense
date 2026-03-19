package com.drivesense.controller;

import com.drivesense.model.Protocol;
import com.drivesense.service.ProtocolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/protocols")
public class ProtocolController {
    @Autowired
    private ProtocolService protocolService;

    // GET /api/protocols
    @GetMapping("/")
    public ResponseEntity<List<Protocol>> getAll() {
        return ResponseEntity.ok(protocolService.getAll());
    }

    // GET /api/protocols/1
    @GetMapping("/{id}")
    public ResponseEntity<Protocol> getById(@PathVariable int id) {
        return ResponseEntity.ok(protocolService.getById(id));
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

    // POST /api/protocols
    @PostMapping
    public ResponseEntity<Protocol> insert(@RequestBody Protocol protocol) {
        return ResponseEntity.status(201).body(protocolService.insert(protocol));
    }

    // PUT /api/protocols/1
    @PutMapping("/{id}")
    public ResponseEntity<Void> update(@PathVariable int id, @RequestBody Protocol protocol) {
        protocol.setId(id);
        protocolService.update(protocol);
        return ResponseEntity.ok().build();
    }
}