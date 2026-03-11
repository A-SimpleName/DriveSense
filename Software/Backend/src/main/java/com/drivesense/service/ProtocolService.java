package com.drivesense.service;

import com.drivesense.db.*;
import com.drivesense.dto.response.ProtocolDto;
import com.drivesense.model.Trackingpoint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;

@Service
public class ProtocolService {
    @Autowired
    private ProtocolDetailDao protocolDetailDao;

    @Autowired
    private ProtocolDao protocolDao;

    @Autowired
    private ProtocolUserDao protocolUserDao;

    @Autowired
    private TripDao tripDao;

    @Autowired
    private TrackingpointDao trackingpointDao;




}
