package com.drivesense.controller;

import com.drivesense.dto.request.*;
import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.dto.response.GroupResponse;
import com.drivesense.dto.response.ProfileSelectionResponse;
import com.drivesense.dto.response.SelectProfileResponse;
import com.drivesense.model.Profile;
import com.drivesense.model.UserGroup;
import com.drivesense.service.GroupInvitationService;
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
    @Autowired
    private UsergroupService usergroupService;
    @Autowired
    private GroupInvitationService groupInvitationService;

    // GET /api/groups?profileId=1
    @GetMapping
    public ResponseEntity<List<GroupResponse>> getGroupsByProfile(HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(usergroupService.getGroupsByProfile(profileId));
    }

    @GetMapping("/{groupId}")
    public ResponseEntity<GroupResponse> getGroupById(@PathVariable int groupId) {
        return ResponseEntity.ok(usergroupService.getUserGroupById(groupId));
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
    public ResponseEntity<GroupResponse> insertGroup(
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
        String role = (String) request.getAttribute("role");
        usergroupService.addMember(groupId, profileId, requesterId,role);
        return ResponseEntity.status(201).build();
    }

    @PostMapping("/{groupId}/invite")
    public ResponseEntity<Void> inviteToGroup(
            @PathVariable int groupId,
            @RequestBody @Valid InviteToGroupRequest request,
            HttpServletRequest httpRequest) {

        int profileId = (int) httpRequest.getAttribute("profileId");
        groupInvitationService.inviteToGroup(groupId, profileId, request.getEmail());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/verify-invite")
    public ResponseEntity<List<ProfileSelectionResponse>> verifyInvite(
            @RequestBody @Valid VerifyInviteRequest request,
            HttpServletRequest httpRequest) {

        int accountId = (int) httpRequest.getAttribute("accountId");
        List<Profile> profiles = groupInvitationService.verifyInviteCode(accountId, request.getCode());
        List<ProfileSelectionResponse> response = profiles.stream()
                .map(p -> new ProfileSelectionResponse(p.getId(), p.getName(),p.getRole()))
                .toList();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/accept-invite")
    public ResponseEntity<Void> acceptInvite(
            @RequestBody @Valid AcceptInviteRequest request,
            HttpServletRequest httpRequest) {

        int accountId = (int) httpRequest.getAttribute("accountId");
        groupInvitationService.acceptInvite(accountId, request.getCode(), request.getProfileId());
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{groupId}")
    public ResponseEntity<Void> updateGroup(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Valid @RequestBody UserGroupCreateRequest request,
            HttpServletRequest httpRequest) {
        int profileId = (int) httpRequest.getAttribute("profileId");
        String role = (String) httpRequest.getAttribute("role");
        usergroupService.updateGroup(groupId, profileId, request.getName(),role);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{groupId}/members/{profileId}/role")
    public ResponseEntity<Void> updateRole(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Min(value = 1, message = "Profil ID muss größer als 0 sein") @PathVariable int profileId,
            @Valid @RequestBody UserGroupUpdateRoleRequest request,
            HttpServletRequest httpRequest) {
        int requesterId = (int) httpRequest.getAttribute("profileId");
        String role = (String) httpRequest.getAttribute("role");
        usergroupService.updateRole(groupId, profileId, request.getRole(), requesterId,role);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{groupId}")
    public ResponseEntity<Void> deleteGroup(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        String role = (String) request.getAttribute("role");
        usergroupService.deleteGroup(groupId, profileId,role);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{groupId}/members/{profileId}")
    public ResponseEntity<Void> deleteMember(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein") @PathVariable int groupId,
            @Min(value = 1, message = "Profil ID muss größer als 0 sein") @PathVariable int profileId,
            HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        String role = (String) request.getAttribute("role");
        usergroupService.deleteMember(groupId, profileId, requesterId,role);
        return ResponseEntity.noContent().build();
    }
}
