package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.VehicleInvitation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class VehicleInvitationDao {

    @Autowired
    private DbConnection dbConnection;

    public void insert(VehicleInvitation invitation) {
        String sql = """
            INSERT INTO vehicle_invitation
                (vehicle_id, invited_account_id, invited_by_profile_id, code_hash, status, role, expires_at)
            VALUES (?, ?, ?, ?, 'PENDING', ?, ?)
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, invitation.getVehicleId());
            ps.setInt(2, invitation.getInvitedAccountId());
            ps.setInt(3, invitation.getInvitedByProfileId());
            ps.setString(4, invitation.getCodeHash());
            ps.setString(5, invitation.getRole());
            ps.setObject(6, invitation.getExpiresAt());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Erstellen der Fahrzeug-Einladung", e);
        }
    }

    /** Liefert eine offene (PENDING) Einladung für Account + Fahrzeug – für Re-Invite-Logik. */
    public VehicleInvitation getPendingByAccountAndVehicle(int accountId, int vehicleId) {
        String sql = """
            SELECT * FROM vehicle_invitation
            WHERE invited_account_id = ? AND vehicle_id = ? AND status = 'PENDING'
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, vehicleId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? map(rs) : null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Suchen der Fahrzeug-Einladung", e);
        }
    }

    /** Alle offenen Einladungen für einen Account (zur Code-Verifikation). */
    public List<VehicleInvitation> getAllPendingByAccount(int accountId) {
        String sql = "SELECT * FROM vehicle_invitation WHERE invited_account_id = ? AND status = 'PENDING'";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ResultSet rs = ps.executeQuery();
            List<VehicleInvitation> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrzeug-Einladungen", e);
        }
    }

    /** Aktualisiert Code + Ablaufzeit einer bestehenden Einladung (Re-Invite). */
    public void updateCode(int id, String codeHash, LocalDateTime expiresAt) {
        String sql = "UPDATE vehicle_invitation SET code_hash = ?, expires_at = ?, created_at = NOW() WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, codeHash);
            ps.setObject(2, expiresAt);
            ps.setInt(3, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren der Fahrzeug-Einladung", e);
        }
    }

    public void updateStatus(int id, String status) {
        String sql = "UPDATE vehicle_invitation SET status = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Einladungsstatus", e);
        }
    }

    /** Markiert alle abgelaufenen PENDING-Einladungen als EXPIRED (für den Scheduler). */
    public void expireOldInvitations() {
        String sql = """
            UPDATE vehicle_invitation
            SET status = 'EXPIRED'
            WHERE status = 'PENDING' AND expires_at < NOW()
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Ablaufen der Fahrzeug-Einladungen", e);
        }
    }

    private VehicleInvitation map(ResultSet rs) throws SQLException {
        VehicleInvitation inv = new VehicleInvitation();
        inv.setId(rs.getInt("id"));
        inv.setVehicleId(rs.getInt("vehicle_id"));
        inv.setInvitedAccountId(rs.getInt("invited_account_id"));
        inv.setInvitedByProfileId(rs.getInt("invited_by_profile_id"));
        inv.setCodeHash(rs.getString("code_hash"));
        inv.setStatus(rs.getString("status"));
        inv.setRole(rs.getString("role"));
        inv.setExpiresAt(rs.getObject("expires_at", LocalDateTime.class));
        inv.setCreatedAt(rs.getObject("created_at", LocalDateTime.class));
        return inv;
    }
}
