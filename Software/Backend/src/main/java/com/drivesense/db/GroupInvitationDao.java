package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.GroupInvitation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class GroupInvitationDao {

    @Autowired
    private DbConnection dbConnection;

    public void insert(GroupInvitation invitation) {
        String sql = """
            INSERT INTO group_invitation (group_id, invited_account_id, invited_by_profile_id, code_hash, status, expires_at)
            VALUES (?, ?, ?, ?, 'PENDING', ?)
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invitation.getGroupId());
            ps.setInt(2, invitation.getInvitedAccountId());
            ps.setInt(3, invitation.getInvitedByProfileId());
            ps.setString(4, invitation.getCodeHash());
            ps.setObject(5, invitation.getExpiresAt());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Erstellen der Einladung", e);
        }
    }

    public GroupInvitation getPendingByAccountAndGroup(int accountId, int groupId) {
        String sql = "SELECT * FROM group_invitation WHERE invited_account_id = ? AND group_id = ? AND status = 'PENDING'";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, groupId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return map(rs);
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Suchen der Einladung", e);
        }
    }

    public List<GroupInvitation> getAllPendingByAccount(int accountId) {
        String sql = "SELECT * FROM group_invitation WHERE invited_account_id = ? AND status = 'PENDING'";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ResultSet rs = ps.executeQuery();
            List<GroupInvitation> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Einladungen", e);
        }
    }

    public void updateCode(int id, String codeHash, LocalDateTime expiresAt) {
        String sql = "UPDATE group_invitation SET code_hash = ?, expires_at = ?, created_at = NOW() WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, codeHash);
            ps.setObject(2, expiresAt);
            ps.setInt(3, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren der Einladung", e);
        }
    }

    public void updateStatus(int id, String status) {
        String sql = "UPDATE group_invitation SET status = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Status", e);
        }
    }

    /**
     * Markiert alle abgelaufenen PENDING-Einladungen als EXPIRED (für den Scheduler).
     * Wird stündlich vom CleanupScheduler aufgerufen.
     */
    public void expireOldInvitations() {
        String sql = """
            UPDATE group_invitation
            SET status = 'EXPIRED'
            WHERE status = 'PENDING' AND expires_at < NOW()
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Ablaufen der Gruppen-Einladungen", e);
        }
    }

    private GroupInvitation map(ResultSet rs) throws SQLException {
        GroupInvitation inv = new GroupInvitation();
        inv.setId(rs.getInt("id"));
        inv.setGroupId(rs.getInt("group_id"));
        inv.setInvitedAccountId(rs.getInt("invited_account_id"));
        inv.setInvitedByProfileId(rs.getInt("invited_by_profile_id"));
        inv.setCodeHash(rs.getString("code_hash"));
        inv.setStatus(rs.getString("status"));
        inv.setExpiresAt(rs.getObject("expires_at", LocalDateTime.class));
        inv.setCreatedAt(rs.getObject("created_at", LocalDateTime.class));
        return inv;
    }
}
