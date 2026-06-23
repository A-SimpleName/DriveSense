package com.drivesense.controller;

import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.dto.response.GroupResponse;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.model.*;
import com.drivesense.service.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.constraints.Min;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
    @Autowired
    private AccountService accountService;
    @Autowired
    private ProfileService profileService;
    @Autowired
    private UsergroupService usergroupService;

    @GetMapping("/accounts")
    public ResponseEntity<List<Account>> getAllAccounts() {
        return ResponseEntity.ok(accountService.getAll());
    }
    @DeleteMapping("/accounts/{id}")
    public ResponseEntity<Void> deleteAccount(@PathVariable int id) {
        accountService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/profiles")
    public ResponseEntity<List<Profile>> getAllProfiles() {
        return ResponseEntity.ok(profileService.getAll());
    }

    @DeleteMapping("/profiles/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id) {
        profileService.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/groups")
    public ResponseEntity<List<GroupResponse>> getAllGroups () {
        return ResponseEntity.ok(usergroupService.getAll());
    }

    @GetMapping("/groups/{groupId}/members")
    public ResponseEntity<List<GroupMemberResponse>> getMembers(
            @Min(value = 1, message = "Gruppen ID muss größer als 0 sein")
            @PathVariable int groupId) {
        return ResponseEntity.ok(usergroupService.adminGetMembersByGroup(groupId));
    }

    @DeleteMapping("/groups/{groupId}/members/{profileId}")
    public ResponseEntity<Void> deleteMember(@PathVariable int groupId, @PathVariable int profileId) {
        usergroupService.adminRemoveMember(groupId, profileId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/groups/{groupId}")
    public ResponseEntity<Void> deleteGroup(@PathVariable int groupId) {
        usergroupService.adminDeleteGroup(groupId);
        return ResponseEntity.noContent().build();
    }
}
