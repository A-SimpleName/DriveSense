package com.drivesense.service;

import com.drivesense.db.ProtocolDao;
import com.drivesense.exceptions.*;
import com.drivesense.db.*;
import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.dto.response.TripSummaryDto;
import com.drivesense.model.Protocol;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProtocolService {
    @Autowired
    private ProtocolDao protocolDao;

    @Autowired
    private TripDao tripDao;

    public Protocol insert(Protocol protocol) {
        Protocol inserted = protocolDao.insert(protocol);
        if (inserted == null) {
            throw new RuntimeException("Fehler beim Erstellen des Protokolls");
        }
        return inserted;
    }

    public Protocol getById(int id) {
        Protocol protocol = protocolDao.getById(id);
        if (protocol == null) {
            throw new NotFoundException("Protokoll nicht gefunden");
        }
        return protocol;
    }

    public List<Protocol> getByGroup(int usergroupId) {
        return protocolDao.getByGroup(usergroupId);
    }

    public List<Protocol> getAll() {
        return protocolDao.getAll();
    }

    public void update(Protocol protocol) {
        Protocol existing = protocolDao.getById(protocol.getId());
        if (existing == null) {
            throw new NotFoundException("Protokoll nicht gefunden");
        }
        protocolDao.update(protocol);
    }

    public List<Protocol> getByProfileId(int createdByProfileId) {
        return protocolDao.getByProfileId(createdByProfileId);
    }

    public ProtocolDto getProtocolWithTrips(int protocolId) {
        Protocol protocol = protocolDao.getById(protocolId);

        List<TripSummaryDto> trips =
                tripDao.getAllByProtocolId(protocolId);

        ProtocolDto dto = new ProtocolDto();
        dto.setId(protocol.getId());
        dto.setName(protocol.getName());
        dto.setTrips(trips);
        return dto;
    }

    public List<Protocol> getAllByProfileId (int profileId) {
        return protocolDao.getAllByProfileId(profileId);
    }
}
