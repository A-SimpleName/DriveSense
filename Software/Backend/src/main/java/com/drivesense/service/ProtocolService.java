package com.drivesense.service;

import com.drivesense.db.*;
import com.drivesense.model.Protocol;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProtocolService {
    @Autowired
    private ProtocolDao protocolDao;

    public Protocol insert (Protocol protocol) {
        return protocolDao.insert(protocol);
    }

    public Protocol getById (int id) {
        return protocolDao.getById(id);
    }

    public List<Protocol> getByGroup (int usergroup_id) {
        return protocolDao.getByGroup(usergroup_id);
    }

    public List<Protocol> getAll () {
        return protocolDao.getAll();
    }

    public void update (Protocol protocol) {
        protocolDao.update(protocol);
    }

    public List<Protocol> getByProfileId (int createdByProfileId) {
        return protocolDao.getByProfileId(createdByProfileId);
    }


}
