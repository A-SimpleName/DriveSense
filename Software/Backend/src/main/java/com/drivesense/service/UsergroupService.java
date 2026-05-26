package com.drivesense.service;

import com.drivesense.db.ProfileUsergroupDao;
import com.drivesense.db.UserGroupDao;
import com.drivesense.dto.response.GroupMemberResponse;
import com.drivesense.dto.response.GroupResponse;
import com.drivesense.exceptions.*;
import com.drivesense.model.ProfileUsergroup;
import com.drivesense.model.UserGroup;
import org.hibernate.validator.internal.engine.groups.Group;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class UsergroupService {
    @Autowired
    private UserGroupDao userGroupDao;
    @Autowired
    private ProfileUsergroupDao profileUserGroupDao;
    @Autowired
    private ProfileService profileService;

    public GroupResponse insertGroup(String name, int profileId) {

        UserGroup group = new UserGroup();
        group.setName(name);
        group.setOwner_id(profileId);
        userGroupDao.insert(group);

        ProfileUsergroup pug = new ProfileUsergroup();
        pug.setProfileId(profileId);
        pug.setUsergroupId(group.getId());
        pug.setGroupRole("OWNER");
        profileUserGroupDao.insert(pug);

        return mapToGroupResponse(group);
    }

    public void deleteGroup(int groupId, int profileId, String profileRole) {
        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) throw new NotFoundException("Gruppe nicht gefunden");

        if (!isGroupOwner(groupId, profileId) && !profileRole.equals("ADMIN")) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        profileUserGroupDao.deleteAllByGroupId(groupId);
        userGroupDao.deleteById(groupId);
    }

    public void addMember(int groupId, int profileId, int requesterId, String profileRole) {
        if (requesterId == profileId) {
            throw new BadRequestException("Du kannst dich nicht selbst einladen");
        }

        if (!isGroupOwnerOrAdmin(groupId, requesterId) && !profileRole.equals("ADMIN")) {
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

    public void deleteMember(int groupId, int profileId, int requesterId, String profileRole) {
        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (requester == null || requester.getProfileId() == 0) {
            throw new UnauthorizedException("Kein Zugriff");
        }

        String requesterGroupRole = getGroupRole(groupId, requesterId);
        String targetGroupRole = getGroupRole(groupId, profileId);
        boolean isSelf = requesterId == profileId;

        // niemand kann Owner entfernen
        if (targetGroupRole.equals("OWNER")) {
            throw new UnauthorizedException("Owner kann nicht entfernt werden");
        }

        // Admin kann keine anderen Admins entfernen
        if (requesterGroupRole.equals("ADMIN") && targetGroupRole.equals("ADMIN")) {
            throw new UnauthorizedException("Admins können keine anderen Admins entfernen");
        }

        // Owner kann sich nicht selbst entfernen
        if (isSelf && (requesterGroupRole.equals("OWNER"))) {
            throw new BadRequestException("Owner kann sich nicht selbst entfernen");
        }

        // normaler Member darf sich selbst entfernen
        if (isSelf) {
            profileUserGroupDao.delete(profileId, groupId);
            return;
        }

        // Owner darf Admins und Members entfernen
        // Admin darf nur Members entfernen
        if (requesterGroupRole.equals("OWNER") ||
                (requesterGroupRole.equals("ADMIN") && targetGroupRole.equals("MEMBER")) ||
                profileRole.equals("ADMIN")) {
            profileUserGroupDao.delete(profileId, groupId);
        } else {
            throw new UnauthorizedException("Keine Berechtigung");
        }
    }

    public void updateRole(int groupId, int profileId, String newRole, int requesterId, String profileRole) {
        String requesterGroupRole = getGroupRole(groupId, requesterId);
        String targetGroupRole = getGroupRole(groupId, profileId);

        // nur Owner darf Rollen ändern
        if (!requesterGroupRole.equals("OWNER") && !profileRole.equals("ADMIN")) {
            throw new UnauthorizedException("Nur der Owner darf Rollen ändern");
        }

        // OWNER Rolle darf nicht vergeben werden
        if (newRole.equals("OWNER")) {
            throw new UnauthorizedException("Owner Rolle kann nicht vergeben werden");
        }

        // Owner selbst kann nicht geändert werden
        if (targetGroupRole.equals("OWNER")) {
            throw new UnauthorizedException("Owner Rolle kann nicht geändert werden");
        }

        ProfileUsergroup member = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (member == null || member.getProfileId() == 0) {
            throw new NotFoundException("Mitglied nicht gefunden");
        }

        member.setGroupRole(newRole);
        profileUserGroupDao.updateRole(member);
    }

    public void updateGroup(int groupId, int profileId, String name, String profileRole) {
        UserGroup group = userGroupDao.getById(groupId);
        if (group == null) throw new NotFoundException("Gruppe nicht gefunden");

        // Owner oder globaler Admin darf Gruppe umbenennen
        if (!isGroupOwner(groupId, profileId) && !profileRole.equals("ADMIN")) {
            throw new UnauthorizedException("Keine Berechtigung");
        }

        group.setName(name);
        userGroupDao.update(group);
    }

    public void adminDeleteGroup (int groupId) {
        profileUserGroupDao.deleteAllByGroupId(groupId);
        userGroupDao.deleteById(groupId);
    }

    public void adminRemoveMember(int groupId, int profileId) {
        profileUserGroupDao.delete(profileId, groupId);
    }

    public List<GroupResponse> getGroupsByProfile(int profileId) {
        return mapToGroupResponse(userGroupDao.getGroupsByProfileId(profileId));
    }

    public List<GroupMemberResponse> getMembersByGroup(int groupId, int requesterId) {

        ProfileUsergroup requester = profileUserGroupDao.getByProfileIdAndGroupId(requesterId, groupId);
        if (requester == null || requester.getProfileId() == 0) {
            throw new UnauthorizedException("Kein Zugriff auf diese Gruppe");
        }
        return profileUserGroupDao.getMembersByGroupId(groupId);
    }

    public List<GroupMemberResponse> adminGetMembersByGroup(int groupId) {
        return profileUserGroupDao.getMembersByGroupId(groupId);
    }

    public List<GroupResponse> getAll () {
        return mapToGroupResponse(userGroupDao.getAll());
    }

    public GroupResponse getUserGroupById (int id) {
        return mapToGroupResponse(userGroupDao.getById(id));
    }

    public boolean isGroupOwner(int groupId, int profileId) {
        ProfileUsergroup pug = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (pug == null || pug.getProfileId() == 0) return false;
        return pug.getGroupRole().equals("OWNER");
    }

    public boolean isGroupAdmin(int groupId, int profileId) {
        ProfileUsergroup pug = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (pug == null || pug.getProfileId() == 0) return false;
        return pug.getGroupRole().equals("ADMIN");
    }

    public boolean isGroupOwnerOrAdmin(int groupId, int profileId) {
        return isGroupOwner(groupId, profileId) || isGroupAdmin(groupId, profileId);
    }

    private String getGroupRole(int groupId, int profileId) {
        ProfileUsergroup pug = profileUserGroupDao.getByProfileIdAndGroupId(profileId, groupId);
        if (pug == null || pug.getProfileId() == 0) return "NONE";
        return pug.getGroupRole();
    }

    private GroupResponse mapToGroupResponse(UserGroup group) {
        GroupResponse newGroup = new GroupResponse();
        newGroup.setId(group.getId());
        newGroup.setName(group.getName());
        newGroup.setOwnerId(group.getOwner_id());
        newGroup.setOwner(profileService.getById(group.getOwner_id()).getName());
        return newGroup;
    }

    private List<GroupResponse> mapToGroupResponse(List<UserGroup> groups) {
        List<GroupResponse> responses = new ArrayList<>();
        for (UserGroup group : groups) {
            responses.add(mapToGroupResponse(group));
        }
        return responses;
    }
}
