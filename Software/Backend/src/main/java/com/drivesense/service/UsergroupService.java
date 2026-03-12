package com.drivesense.service;

import com.drivesense.db.ProfileDao;
import com.drivesense.db.ProfileUsergroupDao;
import com.drivesense.db.UserGroupDao;
import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.model.Profile;
import com.drivesense.model.ProfileUsergroup;
import com.drivesense.model.UserGroup;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.swing.*;
import java.util.List;

@Service
public class UsergroupService {
    private final UserGroupDao userGroupDao;
    private final ProfileUsergroupDao profileUserGroupDao;
    private final ProfileDao profileDao;

    @Autowired
    public UsergroupService(UserGroupDao userGroupDao, ProfileUsergroupDao profileUserGroupDao, ProfileDao profileDao) {
        this.userGroupDao = userGroupDao;
        this.profileUserGroupDao = profileUserGroupDao;
        this.profileDao = profileDao;
    }

    public UserGroup insertGroup(String name, int profileId) {
        checkGroupPermission(profileId);
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

    public void deleteGroup(int groupId, int profileId) {
        checkGroupPermission(profileId);
        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) {
            throw new RuntimeException("Gruppe nicht gefunden");
        }
        if (group.getOwner_id() != profileId && !isOwnerOrAdmin(groupId, profileId)) {
            throw new RuntimeException("Keine Berechtigung");
        }

        profileUserGroupDao.delete(profileId,groupId);
        userGroupDao.deleteById(groupId);
    }

    public void addMember(int groupId, int profileId, int requesterId) {
        checkGroupPermission(profileId);
        checkGroupPermission(requesterId);
        // prüfen ob Requester Owner ist
        if (!isOwnerOrAdmin(groupId, requesterId)) {
            throw new RuntimeException("Keine Berechtigung");
        }

        ProfileUsergroup existing = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (existing != null) {
            throw new RuntimeException("Profil ist bereits in der Gruppe");
        }

        ProfileUsergroup pug = new ProfileUsergroup();
        pug.setProfileId(profileId);
        pug.setUsergroupId(groupId);
        pug.setGroupRole("MEMBER");
        profileUserGroupDao.insert(pug);
    }

    public void deleteMember(int groupId, int profileId, int requesterId) {
        checkGroupPermission(profileId);
        checkGroupPermission(requesterId);
        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (requester == null) {
            throw new RuntimeException("Kein Zugriff");
        }

        boolean isOwnerOrAdmin = isOwnerOrAdmin(groupId, requesterId);
        boolean isSelf = requesterId == profileId;

        if (!isOwnerOrAdmin && !isSelf) {
            throw new RuntimeException("Keine Berechtigung");
        }

        if (isOwnerOrAdmin && isSelf) {
            throw new RuntimeException("Owner/Admin kann sich nicht selbst entfernen");
        }

        profileUserGroupDao.delete(profileId, groupId);
    }

    public void updateRole(int groupId, int profileId, String newRole, int requesterId) {
        checkGroupPermission(profileId);
        checkGroupPermission(requesterId);
        if (!isOwnerOrAdmin(groupId, requesterId)) {
            throw new RuntimeException("Keine Berechtigung");
        }

        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (newRole.equals("OWNER") && !requester.getGroupRole().equals("OWNER")) {
            throw new RuntimeException("Nur der Owner darf die Owner Rolle vergeben");
        }

        ProfileUsergroup member = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (member == null) {
            throw new RuntimeException("Mitglied nicht gefunden");
        }

        member.setGroupRole(newRole);
        profileUserGroupDao.updateRole(member);
    }

    public List<UserGroup> getGroupsByProfile(int profileId) {
        checkGroupPermission(profileId);
        return userGroupDao.getGroupsByProfileId(profileId);
    }

    public List<GroupMemberResponse> getMembersByGroup(int groupId, int requesterId) {
        checkGroupPermission(requesterId);
        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (requester == null) {
            throw new RuntimeException("Kein Zugriff auf diese Gruppe");
        }
        return profileUserGroupDao.getMembersByGroupId(groupId);
    }

    public void updateGroup(int groupId, int profileId, String name) {
        checkGroupPermission(profileId);
        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) {
            throw new RuntimeException("Gruppe nicht gefunden");
        }

        if (!isOwnerOrAdmin(groupId, profileId)) {
            throw new RuntimeException("Keine Berechtigung");
        }

        group.setName(name);
        userGroupDao.update(group);
    }

    private boolean isOwnerOrAdmin(int groupId, int profileId) {
        ProfileUsergroup pug = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (pug == null) return false;
        return pug.getGroupRole().equals("OWNER") || pug.getGroupRole().equals("ADMIN");
    }

    private void checkGroupPermission(int profileId) {
        Profile profile = profileDao.getById(profileId);
        if (profile == null) {
            throw new RuntimeException("Profil nicht gefunden");
        }
        if (!profile.getRole().equals("PRIVAT")) {
            throw new RuntimeException("Nur Private Profile dürfen Gruppen verwenden");
        }
    }
}
