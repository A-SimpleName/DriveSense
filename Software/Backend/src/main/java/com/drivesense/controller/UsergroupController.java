package com.drivesense.controller;

import com.drivesense.dto.request.UserGroupCreateRequest;
import com.drivesense.dto.request.UserGroupUpdateRoleRequest;
import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.model.UserGroup;
import com.drivesense.service.UsergroupService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Validated
@RestController
@RequestMapping("/api/groups")
public class UsergroupController {
    private final UsergroupService usergroupService;

    @Autowired
    public UsergroupController(UsergroupService usergroupService) {
        this.usergroupService = usergroupService;
    }

    // GET /api/groups?profileId=1
    @GetMapping("/")
    public ResponseEntity<List<UserGroup>> getGroupsByProfile(HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(usergroupService.getGroupsByProfile(profileId));
    }

    // GET /api/groups/1/members?requesterId=1
    @GetMapping("/{groupId}/members")
    public ResponseEntity<List<GroupMemberResponse>> getMembers(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein")
            @PathVariable int groupId,
            HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(usergroupService.getMembersByGroup(groupId, requesterId));
    }

    @PostMapping
    public ResponseEntity<UserGroup> insertGroup(
            @Valid @RequestBody UserGroupCreateRequest request,
            HttpServletRequest httpRequest) {
        int profileId = (int) httpRequest.getAttribute("profileId");
        return ResponseEntity.status(201).body(usergroupService.insertGroup(request.getName(), profileId));
    }

    @PostMapping("/{groupId}/members/{profileId}")
    public ResponseEntity<Void> addMember(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Min(value = 1, message = "Profil ID muss größer als 0 sein") @PathVariable int profileId,
            HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        usergroupService.addMember(groupId, profileId, requesterId);
        return ResponseEntity.status(201).build();
    }

    @PutMapping("/{groupId}")
    public ResponseEntity<Void> updateGroup(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Valid @RequestBody UserGroupCreateRequest request,
            HttpServletRequest httpRequest) {
        int profileId = (int) httpRequest.getAttribute("profileId");
        usergroupService.updateGroup(groupId, profileId, request.getName());
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{groupId}/members/{profileId}/role")
    public ResponseEntity<Void> updateRole(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Min(value = 1, message = "Profil ID muss größer als 0 sein") @PathVariable int profileId,
            @Valid @RequestBody UserGroupUpdateRoleRequest request,
            HttpServletRequest httpRequest) {
        int requesterId = (int) httpRequest.getAttribute("profileId");
        usergroupService.updateRole(groupId, profileId, request.getRole(), requesterId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{groupId}")
    public ResponseEntity<Void> deleteGroup(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        usergroupService.deleteGroup(groupId, profileId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{groupId}/members/{profileId}")
    public ResponseEntity<Void> deleteMember(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Min(value = 1, message = "Profil ID muss größer als 0 sein") @PathVariable int profileId,
            HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        usergroupService.deleteMember(groupId, profileId, requesterId);
        return ResponseEntity.noContent().build();
    }
}
