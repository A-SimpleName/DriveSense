package com.drivesense.controller;

import com.drivesense.dto.ProtocolDto;
import com.drivesense.service.ProtocolService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/protocols")
public class ProtocolController {

    private final ProtocolService protocolService;

    public ProtocolController(ProtocolService protocolService) {
        this.protocolService = protocolService;
    }

    @GetMapping("/")
    public List<ProtocolDto> getAllProtocolsByUser() {
        return protocolService.getAllByUser(1);
    }
}