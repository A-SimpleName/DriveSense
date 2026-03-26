package com.drivesense.controller;

import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.model.UserGroup;
import com.drivesense.service.UsergroupService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
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
    public ResponseEntity<List<GroupMemberResponse>> getMembers(@PathVariable int groupId, HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        return ResponseEntity.ok(usergroupService.getMembersByGroup(groupId, requesterId));
    }

    // POST /api/groups?profileId=1
    @PostMapping("/")
    public ResponseEntity<UserGroup> insertGroup(@RequestBody String name, HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        return ResponseEntity.status(201).body(usergroupService.insertGroup(name, profileId));
    }

    // POST /api/groups/1/members?requesterId=1
    @PostMapping("/{groupId}/members/{profileId}")
    public ResponseEntity<Void> addMember(@PathVariable int groupId, @PathVariable int profileId, HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        usergroupService.addMember(groupId, profileId, requesterId);
        return ResponseEntity.status(201).build();
    }

    // PUT /api/groups/1?profileId=1
    @PutMapping("/{groupId}")
    public ResponseEntity<Void> updateGroup(@PathVariable int groupId, @RequestBody String name,HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        usergroupService.updateGroup(groupId, profileId, name);
        return ResponseEntity.ok().build();
    }

    // PUT /api/groups/1/members/2/role?requesterId=1
    @PutMapping("/{groupId}/members/{profileId}/role")
    public ResponseEntity<Void> updateRole(@PathVariable int groupId, @PathVariable int profileId, @RequestBody String newRole,HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        usergroupService.updateRole(groupId, profileId, newRole, requesterId);
        return ResponseEntity.ok().build();
    }

    // DELETE /api/groups/1?profileId=1
    @DeleteMapping("/{groupId}")
    public ResponseEntity<Void> deleteGroup(@PathVariable int groupId,HttpServletRequest request) {
        int profileId = (int) request.getAttribute("profileId");
        usergroupService.deleteGroup(groupId, profileId);
        return ResponseEntity.noContent().build();
    }

    // DELETE /api/groups/1/members/2?requesterId=1
    @DeleteMapping("/{groupId}/members/{profileId}")
    public ResponseEntity<Void> deleteMember(@PathVariable int groupId, @PathVariable int profileId, HttpServletRequest request) {
        int requesterId = (int) request.getAttribute("profileId");
        usergroupService.deleteMember(groupId, profileId, requesterId);
        return ResponseEntity.noContent().build();
    }
}
