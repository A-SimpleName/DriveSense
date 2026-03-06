package com.drivesense.controller;

import com.drivesense.dto.ProtocolDto;
import com.drivesense.service.ProtocolService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/protocols")
public class ProtocolController {
    private ProtocolService protocolService = new ProtocolService();


    @GetMapping("/")
    public List<ProtocolDto> getAllProtocolsByUser(/*@RequestParam int userId*/) {
        return protocolService.getAllByUser(1);
    }
}