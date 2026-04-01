package com.drivesense.service;

import com.drivesense.db.ProfileUsergroupDao;
import com.drivesense.db.UserGroupDao;
import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.exceptions.*;
import com.drivesense.model.ProfileUsergroup;
import com.drivesense.model.UserGroup;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UsergroupService {
    @Autowired
    private UserGroupDao userGroupDao;
    @Autowired
    private ProfileUsergroupDao profileUserGroupDao;

    public UserGroup insertGroup(String name, int profileId) {

        UserGroup group = new UserGroup();
        group.setName(name);
        group.setOwner_id(profileId);
        userGroupDao.insert(group);

        ProfileUsergroup pug = new ProfileUsergroup();
        pug.setProfileId(profileId);
        pug.setUsergroupId(group.getId());
        pug.setGroupRole("OWNER");
        profileUserGroupDao.insert(pug);

        return group;
    }

    public void deleteGroup(int groupId, int profileId,String profileRole) {

        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) {
            throw new NotFoundException("Gruppe nicht gefunden");
        }
        if (group.getOwner_id() != profileId && !isOwnerOrAdmin(groupId, profileId,profileRole)) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        profileUserGroupDao.deleteAllByGroupId(groupId);
        userGroupDao.deleteById(groupId);
    }

    public void adminDeleteGroup (int groupId) {
        profileUserGroupDao.deleteAllByGroupId(groupId);
        userGroupDao.deleteById(groupId);
    }

    public void addMember(int groupId, int profileId, int requesterId,String profileRole) {

        if (requesterId == profileId) {
            throw new BadRequestException("Du kannst dich nicht selbst einladen");
        }

        if (!isOwnerOrAdmin(groupId, requesterId,profileRole)) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        ProfileUsergroup existing = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (existing != null && existing.getProfileId() != 0) {
            throw new BadRequestException("Profil ist bereits in der Gruppe");
        }

        ProfileUsergroup pug = new ProfileUsergroup();
        pug.setProfileId(profileId);
        pug.setUsergroupId(groupId);
        pug.setGroupRole("MEMBER");
        profileUserGroupDao.insert(pug);
    }

    public void deleteMember(int groupId, int profileId, int requesterId,String profileRole) {

        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (requester == null || requester.getProfileId() == 0) {
            throw new UnauthorizedException("Kein Zugriff");
        }

        boolean isOwnerOrAdmin = isOwnerOrAdmin(groupId, requesterId,profileRole);
        boolean isSelf = requesterId == profileId;

        if (!isOwnerOrAdmin && !isSelf) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        if (isOwnerOrAdmin && isSelf) {
            throw new BadRequestException("Owner/Admin kann sich nicht selbst entfernen");
        }

        profileUserGroupDao.delete(profileId, groupId);
    }

    public void adminRemoveMember(int groupId, int profileId) {
        profileUserGroupDao.delete(profileId, groupId);
    }

    public void updateRole(int groupId, int profileId, String newRole, int requesterId, String profileRole) {

        if (!isOwnerOrAdmin(groupId, requesterId,profileRole)) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (newRole.equals("OWNER") && !requester.getGroupRole().equals("OWNER")) {
            throw new UnauthorizedException("Nur der Owner darf die Owner Rolle vergeben");
        }

        ProfileUsergroup member = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (member == null || member.getProfileId() == 0) {
            throw new NotFoundException("Mitglied nicht gefunden");
        }

        member.setGroupRole(newRole);
        profileUserGroupDao.updateRole(member);
    }

    public List<UserGroup> getGroupsByProfile(int profileId) {
        return userGroupDao.getGroupsByProfileId(profileId);
    }

    public List<GroupMemberResponse> getMembersByGroup(int groupId, int requesterId) {

        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (requester == null || requester.getProfileId() == 0) {
            throw new UnauthorizedException("Kein Zugriff auf diese Gruppe");
        }
        return profileUserGroupDao.getMembersByGroupId(groupId);
    }

    public List<UserGroup> getAll () {
        return userGroupDao.getAll();
    }

    public void updateGroup(int groupId, int profileId, String name,String profileRole) {

        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) {
            throw new NotFoundException("Gruppe nicht gefunden");
        }

        if (!isOwnerOrAdmin(groupId, profileId,profileRole)) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        group.setName(name);
        userGroupDao.update(group);
    }

    private boolean isOwnerOrAdmin(int groupId, int profileId, String profileRole) {
        ProfileUsergroup pug = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (pug == null || pug.getProfileId() == 0) return false;
        return pug.getGroupRole().equals("OWNER") || profileRole.equals("ADMIN");
    }
}
