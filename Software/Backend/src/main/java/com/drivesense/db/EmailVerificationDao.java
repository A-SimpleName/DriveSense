package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.EmailVerification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class EmailVerificationDao {
    @Autowired
    private DbConnection dbConnection;
    public void insert(EmailVerification verification) {
        String sql = "INSERT INTO email_verification (account_id, code_hash, expires_at) VALUES (?, ?, ?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, verification.getAccountId());
            ps.setString(2, verification.getCodeHash());
            ps.setObject(3, verification.getExpiresAt());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Speichern des Verifizierungscodes", e);
        }
    }

    public List<EmailVerification> getAllByAccountId(int accountId) {
        String sql = "SELECT * FROM email_verification WHERE account_id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ResultSet rs = ps.executeQuery();
            List<EmailVerification> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Verifizierungscodes", e);
        }
    }

    public void deleteByAccountId(int accountId) {
        String sql = "DELETE FROM email_verification WHERE account_id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen des Verifizierungscodes", e);
        }
    }

    private EmailVerification map(ResultSet rs) throws SQLException {
        EmailVerification ev = new EmailVerification();
        ev.setId(rs.getInt("id"));
        ev.setAccountId(rs.getInt("account_id"));
        ev.setCodeHash(rs.getString("code_hash"));
        ev.setExpiresAt(rs.getObject("expires_at", LocalDateTime.class));
        ev.setCreatedAt(rs.getObject("created_at", LocalDateTime.class));
        return ev;
    }
}
